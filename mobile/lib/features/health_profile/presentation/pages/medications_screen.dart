import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../interactions/domain/medicine_checker.dart';
import '../../../interactions/domain/medicine_warning.dart';
import '../../../interactions/presentation/widgets/medicine_warning_widgets.dart';
import '../../../safety/application/safety_providers.dart';
import '../../application/allergies_providers.dart';
import '../../application/medications_providers.dart';
import '../../domain/allergy.dart';
import '../../domain/medication.dart';
import '../widgets/health_form_widgets.dart';
import 'medication_editor_screen.dart';

/// Lets the user record what they are currently taking.
///
/// Recognised medicines are stored as generic ingredient codes, so a later
/// interaction check can reason about them, while anything unrecognised is
/// still accepted as free text. An unknown medicine on the list is far more
/// useful than a missing one.
class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MedicationRecord> record = ref.watch(medicationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Medications'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(record),
    );
  }

  Widget _buildBody(AsyncValue<MedicationRecord> record) {
    if (record.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load your medications.\n${record.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!record.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    return _MedicationsEditor(
      initialRecord: record.value ?? MedicationRecord.empty,
    );
  }
}

class _MedicationsEditor extends ConsumerStatefulWidget {
  const _MedicationsEditor({required this.initialRecord});

  final MedicationRecord initialRecord;

  @override
  ConsumerState<_MedicationsEditor> createState() => _MedicationsEditorState();
}

class _MedicationsEditorState extends ConsumerState<_MedicationsEditor> {
  final TextEditingController _searchController = TextEditingController();

  late List<UserMedication> _selected;
  late bool _takesNoMedication;

  String _query = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _selected = List<UserMedication>.of(widget.initialRecord.medications);
    _takesNoMedication = widget.initialRecord.takesNoMedication;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _takesNoMedication != widget.initialRecord.takesNoMedication ||
      !listEquals(_selected, widget.initialRecord.medications);

  Future<void> _add(MedicationIngredient ingredient) async {
    FocusScope.of(context).unfocus();

    final UserMedication? added = await Navigator.of(context)
        .push<UserMedication>(
          MaterialPageRoute<UserMedication>(
            builder: (_) => MedicationEditorScreen(
              medication: UserMedication(ingredient: ingredient),
              others: _selected,
            ),
          ),
        );

    if (added == null) return;

    setState(() {
      _selected.add(added);
      _takesNoMedication = false;
      _searchController.clear();
      _query = '';
    });
  }

  Future<void> _edit(int index) async {
    final UserMedication? updated = await Navigator.of(context)
        .push<UserMedication>(
          MaterialPageRoute<UserMedication>(
            builder: (_) => MedicationEditorScreen(
              medication: _selected[index],
              others: <UserMedication>[
                for (int i = 0; i < _selected.length; i++)
                  if (i != index) _selected[i],
              ],
            ),
          ),
        );

    if (updated == null) return;

    setState(() => _selected[index] = updated);
  }

  void _removeAt(int index) {
    setState(() => _selected.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      await ref.read(saveMedicationsProvider)(
        MedicationRecord(
          medications: _selected,
          takesNoMedication: _takesNoMedication,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medications saved.')));

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your medications: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AllergyRecord allergies =
        ref.watch(allergiesProvider).value ?? AllergyRecord.empty;

    final List<({UserMedication medication, UserAllergy allergy})> conflicts =
        MedicationRecord(medications: _selected).conflictsWith(allergies);

    // Checked against the list being edited rather than the saved one, so a
    // clash shows up the moment a medicine is added instead of after saving.
    final List<MedicineWarning> warnings = MedicineChecker.check(
      medicines: _selected,
      profile: ref.watch(safetyProfileProvider),
    );

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final bool shouldDiscard = await confirmDiscardChanges(
          context,
          message:
              'Your medications have unsaved changes. '
              'Leaving now will lose them.',
        );

        if (shouldDiscard && context.mounted) Navigator.of(context).pop();
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const HealthNote(
                  icon: Icons.medication_outlined,
                  text:
                      'Knowing what you already take is how TARU avoids '
                      'suggesting something that clashes with it. Add the '
                      'name first; the dose and timing can wait.',
                ),

                const SizedBox(height: 16),

                if (conflicts.isNotEmpty) ...[
                  _ConflictBanner(conflicts: conflicts),
                  const SizedBox(height: 16),
                ],

                HealthNoneKnownTile(
                  title: 'I do not take any medicines',
                  lockedHint: 'Remove the medicines listed below to use this.',
                  value: _takesNoMedication,
                  canToggle: _selected.isEmpty,
                  onChanged: (bool value) =>
                      setState(() => _takesNoMedication = value),
                ),

                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  HealthSectionLabel('Your medicines (${_selected.length})'),
                  for (int index = 0; index < _selected.length; index++)
                    _MedicationCard(
                      medication: _selected[index],
                      clashesWithAllergy: conflicts.any(
                        (conflict) =>
                            identical(conflict.medication, _selected[index]),
                      ),
                      warningSeverity: warnings
                          .forMedicine(_selected[index])
                          .highestSeverity,
                      onTap: () => _edit(index),
                      onRemove: () => _removeAt(index),
                    ),
                ],

                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  HealthSectionLabel('Taken together'),
                  MedicineWarningsPanel(warnings: warnings),
                  const MedicineSafetyDisclaimer(),
                ],

                const SizedBox(height: 20),

                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or brand, e.g. Dolo',
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
                  onPressed: () => _add(MedicationIngredient.other),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a medicine not listed'),
                ),
              ],
            ),
          ),
          HealthSaveBar(
            onSave: _isSaving ? null : _save,
            isSaving: _isSaving,
            hasChanges: _hasUnsavedChanges,
            label: 'Save medications',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBrowseList() {
    final List<MedicationIngredient> available = MedicationIngredient.values
        .where(
          (MedicationIngredient ingredient) =>
              !ingredient.isCustom && ingredient.matches(_query),
        )
        .toList();

    // The full list of ingredients is long and unhelpful to scroll, so it only
    // appears once someone has started typing.
    if (_query.trim().isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Start typing to find a medicine. Brand names work too.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ];
    }

    if (available.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Nothing matched "${_query.trim()}". '
            'You can still add it by name below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ];
    }

    return available
        .map(
          (MedicationIngredient ingredient) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              Icons.add_circle_outline,
              color: Colors.blue.shade400,
            ),
            title: Text(ingredient.label),
            onTap: () => _add(ingredient),
          ),
        )
        .toList();
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.clashesWithAllergy,
    required this.warningSeverity,
    required this.onTap,
    required this.onRemove,
  });

  final UserMedication medication;
  final bool clashesWithAllergy;

  /// Worst interaction this medicine is part of, if any, so the card can carry
  /// a marker that points at the explanation further down the page.
  final MedicineWarningSeverity? warningSeverity;

  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String? brand = medication.brandName?.trim();
    final String? schedule = medication.scheduleSummary;
    final String? reason = medication.reason?.trim();

    final MedicineWarningSeverity? severity = warningSeverity;

    final Color? accent = clashesWithAllergy
        ? Colors.red
        : severity == null
        ? null
        : MedicineWarningStyle.of(severity).colour;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: accent == null
            ? null
            : Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          onTap: onTap,
          title: Row(
            children: [
              if (clashesWithAllergy) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 6),
              ] else if (severity != null) ...[
                Icon(
                  MedicineWarningStyle.of(severity).icon,
                  color: MedicineWarningStyle.of(severity).colour,
                  size: 18,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  brand == null || brand.isEmpty
                      ? medication.displayName
                      : '$brand (${medication.displayName})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: schedule == null && reason == null
              ? Text(
                  'Tap to add dose and timing',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (schedule != null)
                      Text(schedule, style: const TextStyle(fontSize: 13)),
                    if (reason != null && reason.isNotEmpty)
                      Text(
                        'For $reason',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey.shade600,
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.conflicts});

  final List<({UserMedication medication, UserAllergy allergy})> conflicts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'A medicine clashes with your allergies',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffB3261E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final conflict in conflicts)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${conflict.medication.displayName} is in the same family as '
                'your ${conflict.allergy.displayName} allergy.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xff7F1D1D),
                ),
              ),
            ),
          const SizedBox(height: 4),
          const Text(
            'Please check with your doctor or pharmacist.',
            style: TextStyle(fontSize: 13, color: Color(0xff7F1D1D)),
          ),
        ],
      ),
    );
  }
}
