import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/conditions_providers.dart';
import '../../domain/medical_condition.dart';

/// Lets the user record which conditions they live with.
///
/// Stored as codes rather than free text so later features can actually reason
/// about them, for example warning that a suggested painkiller is risky with
/// kidney disease.
class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<UserCondition>> conditions = ref.watch(
      conditionsProvider,
    );

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Medical Conditions'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(conditions),
    );
  }

  Widget _buildBody(AsyncValue<List<UserCondition>> conditions) {
    if (conditions.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load your conditions.\n${conditions.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!conditions.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    return _ConditionsEditor(
      initialConditions: conditions.value ?? const <UserCondition>[],
    );
  }
}

class _ConditionsEditor extends ConsumerStatefulWidget {
  const _ConditionsEditor({required this.initialConditions});

  final List<UserCondition> initialConditions;

  @override
  ConsumerState<_ConditionsEditor> createState() => _ConditionsEditorState();
}

class _ConditionsEditorState extends ConsumerState<_ConditionsEditor> {
  final TextEditingController _searchController = TextEditingController();

  late List<UserCondition> _selected;

  String _query = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _selected = List<UserCondition>.of(widget.initialConditions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      !listEquals(_selected, widget.initialConditions);

  void _add(MedicalConditionType type) {
    setState(() {
      _selected.add(UserCondition(type: type));
      _searchController.clear();
      _query = '';
    });

    FocusScope.of(context).unfocus();
  }

  void _removeAt(int index) {
    setState(() => _selected.removeAt(index));
  }

  void _updateAt(int index, UserCondition condition) {
    setState(() => _selected[index] = condition);
  }

  Future<void> _addCustomCondition() async {
    final TextEditingController nameController = TextEditingController();

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Add another condition'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Condition name',
            hintText: 'What is it called?',
          ),
          onSubmitted: (String value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameController.dispose();

    if (name == null || name.isEmpty) return;

    setState(() {
      _selected.add(
        UserCondition(type: MedicalConditionType.other, customName: name),
      );
    });
  }

  Future<bool> _confirmDiscard() async {
    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your conditions have unsaved changes. Leaving now will lose them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(saveConditionsProvider)(_selected);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conditions saved.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your conditions: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final bool shouldDiscard = await _confirmDiscard();

        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const _IntroNote(),

                const SizedBox(height: 20),

                if (_selected.isNotEmpty) ...[
                  _SectionLabel('Your conditions (${_selected.length})'),
                  for (int index = 0; index < _selected.length; index++)
                    _SelectedConditionCard(
                      condition: _selected[index],
                      onChanged: (UserCondition updated) =>
                          _updateAt(index, updated),
                      onRemove: () => _removeAt(index),
                    ),
                  const SizedBox(height: 20),
                ],

                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conditions, e.g. sugar or BP',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (String value) => setState(() => _query = value),
                ),

                const SizedBox(height: 12),

                ..._buildBrowseList(),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: _addCustomCondition,
                  icon: const Icon(Icons.add),
                  label: const Text('Add a condition not listed'),
                ),
              ],
            ),
          ),
          _SaveBar(
            onSave: _isSaving ? null : _save,
            isSaving: _isSaving,
            hasChanges: _hasUnsavedChanges,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBrowseList() {
    final Set<MedicalConditionType> chosen = _selected
        .map((UserCondition condition) => condition.type)
        .toSet();

    final List<MedicalConditionType> available = MedicalConditionType.values
        .where((MedicalConditionType type) {
          return type != MedicalConditionType.other &&
              !chosen.contains(type) &&
              type.matches(_query);
        })
        .toList();

    if (available.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            _query.trim().isEmpty
                ? 'You have added every condition on the list.'
                : 'Nothing matched "${_query.trim()}". '
                      'You can still add it by name below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ];
    }

    if (_query.trim().isNotEmpty) {
      return available.map(_buildAvailableTile).toList();
    }

    final List<Widget> widgets = [];

    final List<MedicalConditionType> quickPicks = available
        .where((MedicalConditionType type) => type.isCommon)
        .toList();

    if (quickPicks.isNotEmpty) {
      widgets.add(const _SectionLabel('Quick picks'));
      widgets.addAll(quickPicks.map(_buildAvailableTile));
    }

    for (final ConditionCategory category in ConditionCategory.values) {
      if (category == ConditionCategory.other) continue;

      final List<MedicalConditionType> inCategory = available
          .where((MedicalConditionType type) => type.category == category)
          .toList();

      if (inCategory.isEmpty) continue;

      widgets.add(_SectionLabel(category.label));
      widgets.addAll(inCategory.map(_buildAvailableTile));
    }

    return widgets;
  }

  /// Deliberately unkeyed: quick picks repeat their category entries, and two
  /// widgets in one list may not share a key.
  Widget _buildAvailableTile(MedicalConditionType type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(Icons.add_circle_outline, color: Colors.blue.shade400),
      title: Text(type.label),
      onTap: () => _add(type),
    );
  }
}

/// A condition the user has, with its optional clinical detail.
class _SelectedConditionCard extends StatelessWidget {
  const _SelectedConditionCard({
    required this.condition,
    required this.onChanged,
    required this.onRemove,
  });

  final UserCondition condition;
  final ValueChanged<UserCondition> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  condition.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey.shade600,
                tooltip: 'Remove',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InputDecorator(
                    decoration: _detailDecoration('Since'),
                    child: DropdownButton<int>(
                      value: condition.yearDiagnosed,
                      isExpanded: true,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      hint: const Text('Year'),
                      items: [
                        for (
                          int year = currentYear;
                          year >= currentYear - 100;
                          year--
                        )
                          DropdownMenuItem<int>(
                            value: year,
                            child: Text('$year'),
                          ),
                      ],
                      onChanged: (int? year) =>
                          onChanged(condition.copyWith(yearDiagnosed: year)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: InputDecorator(
                    decoration: _detailDecoration('Control'),
                    child: DropdownButton<ConditionControl>(
                      value: condition.control,
                      isExpanded: true,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      hint: const Text('How well?'),
                      items: [
                        for (final ConditionControl control
                            in ConditionControl.values)
                          DropdownMenuItem<ConditionControl>(
                            value: control,
                            child: Text(
                              control.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (ConditionControl? control) =>
                          onChanged(condition.copyWith(control: control)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _detailDecoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.onSave,
    required this.isSaving,
    required this.hasChanges,
  });

  final VoidCallback? onSave;
  final bool isSaving;
  final bool hasChanges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton(
          onPressed: onSave,
          child: Text(
            isSaving
                ? 'Saving...'
                : hasChanges
                ? 'Save conditions'
                : 'Saved',
          ),
        ),
      ),
    );
  }
}

class _IntroNote extends StatelessWidget {
  const _IntroNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.medical_information_outlined,
              color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Knowing what you already live with lets TARU avoid advice that '
              'is unsafe for you. Adding when it started and how well it is '
              'controlled helps, but both are optional.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.blueGrey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
