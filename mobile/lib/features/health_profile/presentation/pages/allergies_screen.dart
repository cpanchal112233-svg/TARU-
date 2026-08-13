import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../application/allergies_providers.dart';
import '../../domain/allergy.dart';
import '../widgets/health_form_widgets.dart';

/// Lets the user record what they react to.
///
/// This is the most safety-critical screen in the profile: a stored penicillin
/// allergy is what lets later features refuse to suggest amoxicillin, and a
/// stored anaphylaxis history is what makes TARU escalate instead of offering
/// home advice.
class AllergiesScreen extends ConsumerWidget {
  const AllergiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AllergyRecord> record = ref.watch(allergiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Allergies'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(record),
    );
  }

  Widget _buildBody(AsyncValue<AllergyRecord> record) {
    if (record.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load your allergies. ${userFacingErrorMessage(record.error!)}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!record.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    return _AllergiesEditor(initialRecord: record.value ?? AllergyRecord.empty);
  }
}

class _AllergiesEditor extends ConsumerStatefulWidget {
  const _AllergiesEditor({required this.initialRecord});

  final AllergyRecord initialRecord;

  @override
  ConsumerState<_AllergiesEditor> createState() => _AllergiesEditorState();
}

class _AllergiesEditorState extends ConsumerState<_AllergiesEditor> {
  final TextEditingController _searchController = TextEditingController();

  late List<UserAllergy> _selected;
  late bool _noKnownAllergies;

  String _query = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _selected = List<UserAllergy>.of(widget.initialRecord.allergies);
    _noKnownAllergies = widget.initialRecord.noKnownAllergies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _noKnownAllergies != widget.initialRecord.noKnownAllergies ||
      !listEquals(_selected, widget.initialRecord.allergies);

  List<UserAllergy> get _emergencyRisks => _selected
      .where((UserAllergy allergy) => allergy.isEmergencyRisk)
      .toList();

  void _add(AllergenType type) {
    setState(() {
      _selected.add(UserAllergy(type: type));
      _noKnownAllergies = false;
      _searchController.clear();
      _query = '';
    });

    FocusScope.of(context).unfocus();
  }

  void _removeAt(int index) {
    setState(() => _selected.removeAt(index));
  }

  void _updateAt(int index, UserAllergy allergy) {
    setState(() => _selected[index] = allergy);
  }

  Future<void> _addCustomAllergen() async {
    final _CustomAllergen? custom = await showDialog<_CustomAllergen>(
      context: context,
      builder: (_) => const _AddCustomAllergenDialog(),
    );

    if (custom == null) return;

    setState(() {
      _selected.add(
        UserAllergy(type: custom.placeholder, customName: custom.name),
      );
      _noKnownAllergies = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(saveAllergiesProvider)(
        AllergyRecord(
          allergies: _selected,
          noKnownAllergies: _noKnownAllergies,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Allergies saved.')));

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save your allergies. ${userFacingErrorMessage(error)}',
          ),
        ),
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

        final bool shouldDiscard = await confirmDiscardChanges(
          context,
          message:
              'Your allergies have unsaved changes. '
              'Leaving now will lose them.',
        );

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
                const HealthNote(
                  icon: Icons.warning_amber_rounded,
                  text:
                      'Allergies are the single most important thing TARU can '
                      'know about you. Anything you record here will be '
                      'checked before any medicine or food is ever suggested.',
                ),

                const SizedBox(height: 16),

                if (_emergencyRisks.isNotEmpty) ...[
                  _EmergencyBanner(allergies: _emergencyRisks),
                  const SizedBox(height: 16),
                ],

                HealthNoneKnownTile(
                  title: 'I have no known allergies',
                  lockedHint: 'Remove the allergies listed below to use this.',
                  value: _noKnownAllergies,
                  canToggle: _selected.isEmpty,
                  onChanged: (bool value) =>
                      setState(() => _noKnownAllergies = value),
                ),

                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  HealthSectionLabel('Your allergies (${_selected.length})'),
                  for (int index = 0; index < _selected.length; index++)
                    _SelectedAllergyCard(
                      allergy: _selected[index],
                      onChanged: (UserAllergy updated) =>
                          _updateAt(index, updated),
                      onRemove: () => _removeAt(index),
                    ),
                ],

                const SizedBox(height: 20),

                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search allergies, e.g. penicillin or peanut',
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
                  onPressed: _addCustomAllergen,
                  icon: const Icon(Icons.add),
                  label: const Text('Add an allergy not listed'),
                ),
              ],
            ),
          ),
          HealthSaveBar(
            onSave: _isSaving ? null : _save,
            isSaving: _isSaving,
            hasChanges: _hasUnsavedChanges,
            label: 'Save allergies',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBrowseList() {
    final Set<AllergenType> chosen = _selected
        .map((UserAllergy allergy) => allergy.type)
        .toSet();

    final List<AllergenType> available = AllergenType.values.where((
      AllergenType type,
    ) {
      return !type.isCustom && !chosen.contains(type) && type.matches(_query);
    }).toList();

    if (available.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            _query.trim().isEmpty
                ? 'You have added every allergy on the list.'
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

    for (final AllergyCategory category in AllergyCategory.values) {
      final List<AllergenType> inCategory = available
          .where((AllergenType type) => type.category == category)
          .toList();

      if (inCategory.isEmpty) continue;

      widgets.add(HealthSectionLabel(category.label));
      widgets.addAll(inCategory.map(_buildAvailableTile));
    }

    return widgets;
  }

  Widget _buildAvailableTile(AllergenType type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(Icons.add_circle_outline, color: Colors.blue.shade400),
      title: Text(type.label),
      onTap: () => _add(type),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.allergies});

  final List<UserAllergy> allergies;

  @override
  Widget build(BuildContext context) {
    final String names = allergies
        .map((UserAllergy allergy) => allergy.displayName)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emergency_outlined, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Severe reaction recorded',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffB3261E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TARU will treat exposure to $names as an emergency and tell '
                  'you to get urgent care rather than suggest home remedies.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xff7F1D1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An allergy the user has, with how badly they react to it.
class _SelectedAllergyCard extends StatelessWidget {
  const _SelectedAllergyCard({
    required this.allergy,
    required this.onChanged,
    required this.onRemove,
  });

  final UserAllergy allergy;
  final ValueChanged<UserAllergy> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isEmergency = allergy.isEmergencyRisk;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isEmergency
            ? Border.all(color: Colors.red.withValues(alpha: 0.4))
            : null,
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
              if (isEmergency) ...[
                const Icon(Icons.priority_high, color: Colors.red, size: 18),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  allergy.displayName,
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
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'How bad is the reaction',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: DropdownButton<AllergySeverity>(
                value: allergy.severity,
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Select severity'),
                items: [
                  for (final AllergySeverity severity in AllergySeverity.values)
                    DropdownMenuItem<AllergySeverity>(
                      value: severity,
                      child: Text(severity.label),
                    ),
                ],
                onChanged: (AllergySeverity? severity) =>
                    onChanged(allergy.copyWith(severity: severity)),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'What happens when you are exposed?',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final AllergyReaction reaction in AllergyReaction.values)
                FilterChip(
                  label: Text(
                    reaction.label,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  selected: allergy.reactions.contains(reaction),
                  selectedColor: reaction.isEmergency
                      ? Colors.red.withValues(alpha: 0.12)
                      : null,
                  checkmarkColor: reaction.isEmergency ? Colors.red : null,
                  onSelected: (bool isSelected) {
                    final Set<AllergyReaction> updated =
                        Set<AllergyReaction>.of(allergy.reactions);

                    if (isSelected) {
                      updated.add(reaction);
                    } else {
                      updated.remove(reaction);
                    }

                    onChanged(allergy.copyWith(reactions: updated));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A free-text allergen plus the category it belongs to, so TARU still knows
/// whether it is a medicine, a food or something in the environment.
@immutable
class _CustomAllergen {
  const _CustomAllergen({required this.name, required this.category});

  final String name;
  final AllergyCategory category;

  AllergenType get placeholder {
    switch (category) {
      case AllergyCategory.medicine:
        return AllergenType.otherMedicine;
      case AllergyCategory.food:
        return AllergenType.otherFood;
      case AllergyCategory.environmental:
        return AllergenType.otherEnvironmental;
    }
  }
}

class _AddCustomAllergenDialog extends StatefulWidget {
  const _AddCustomAllergenDialog();

  @override
  State<_AddCustomAllergenDialog> createState() =>
      _AddCustomAllergenDialogState();
}

class _AddCustomAllergenDialogState extends State<_AddCustomAllergenDialog> {
  final TextEditingController _nameController = TextEditingController();

  AllergyCategory _category = AllergyCategory.medicine;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();

    if (name.isEmpty) return;

    Navigator.of(context).pop(_CustomAllergen(name: name, category: _category));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add another allergy'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What are you allergic to?',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AllergyCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final AllergyCategory category in AllergyCategory.values)
                DropdownMenuItem<AllergyCategory>(
                  value: category,
                  child: Text(category.label),
                ),
            ],
            onChanged: (AllergyCategory? category) {
              if (category != null) setState(() => _category = category);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
