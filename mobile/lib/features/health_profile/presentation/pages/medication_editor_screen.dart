import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../interactions/domain/medicine_checker.dart';
import '../../../interactions/domain/medicine_warning.dart';
import '../../../interactions/presentation/widgets/medicine_warning_widgets.dart';
import '../../../safety/application/safety_providers.dart';
import '../../application/allergies_providers.dart';
import '../../domain/allergy.dart';
import '../../domain/medication.dart';
import '../widgets/health_form_widgets.dart';

/// Full-page form for one medicine.
///
/// Medicines carry far more detail than conditions or allergies — dose, timing,
/// food, reason — so each one gets its own page instead of an inline card that
/// would bury the list.
class MedicationEditorScreen extends ConsumerStatefulWidget {
  const MedicationEditorScreen({
    super.key,
    required this.medication,
    this.others = const <UserMedication>[],
  });

  final UserMedication medication;

  /// The rest of the list, so a clash is visible while the medicine is being
  /// added rather than only after it lands on the list behind this page.
  final List<UserMedication> others;

  @override
  ConsumerState<MedicationEditorScreen> createState() =>
      _MedicationEditorScreenState();
}

class _MedicationEditorScreenState
    extends ConsumerState<MedicationEditorScreen> {
  late final TextEditingController _brandController;
  late final TextEditingController _doseController;
  late final TextEditingController _reasonController;
  late final TextEditingController _customNameController;

  late UserMedication _draft;

  @override
  void initState() {
    super.initState();

    _draft = widget.medication;

    _brandController = TextEditingController(text: _draft.brandName ?? '');
    _reasonController = TextEditingController(text: _draft.reason ?? '');

    _customNameController = TextEditingController(
      text: _draft.customName ?? '',
    );

    _doseController = TextEditingController(
      text: _draft.doseAmount == null ? '' : _formatDose(_draft.doseAmount!),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _doseController.dispose();
    _reasonController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  static String _formatDose(double amount) => amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toString();

  /// Blank fields become null rather than empty strings, so simply opening a
  /// medicine and closing it again does not look like an edit.
  UserMedication get _current => UserMedication(
    ingredient: _draft.ingredient,
    customName: _trimToNull(_customNameController.text),
    brandName: _trimToNull(_brandController.text),
    form: _draft.form,
    doseAmount: double.tryParse(_doseController.text.trim()),
    doseUnit: _draft.doseUnit,
    frequency: _draft.frequency,
    doseTimes: _draft.doseTimes,
    foodTiming: _draft.foodTiming,
    reason: _trimToNull(_reasonController.text),
    startedOn: _draft.startedOn,
  );

  static String? _trimToNull(String value) {
    final String trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  bool get _hasUnsavedChanges => _current != widget.medication;

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _draft.startedOn ?? now,
      firstDate: DateTime(now.year - 60),
      lastDate: now,
      helpText: 'When did you start taking it?',
    );

    if (picked == null) return;

    setState(() => _draft = _draft.copyWith(startedOn: picked));
  }

  @override
  Widget build(BuildContext context) {
    final AllergyRecord allergies =
        ref.watch(allergiesProvider).value ?? AllergyRecord.empty;

    final UserAllergy? clash = _clashingAllergy(allergies);

    final List<MedicineWarning> warnings = MedicineChecker.check(
      medicines: <UserMedication>[...widget.others, _current],
      profile: ref.watch(safetyProfileProvider),
    ).forMedicine(_current);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final bool shouldDiscard = await confirmDiscardChanges(
          context,
          message:
              'This medicine has unsaved details. '
              'Leaving now will lose them.',
        );

        if (shouldDiscard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        appBar: AppBar(
          title: Text(_draft.displayName),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (clash != null) ...[
                    _AllergyClashBanner(
                      medicationName: _draft.displayName,
                      allergy: clash,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (warnings.isNotEmpty) ...[
                    MedicineWarningsPanel(warnings: warnings),
                    const SizedBox(height: 8),
                  ],

                  if (_draft.ingredient.isCustom) ...[
                    TextField(
                      controller: _customNameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _decoration(
                        'Medicine name',
                        hint: 'What does the strip say?',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: _brandController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration(
                      'Brand name (optional)',
                      hint: 'e.g. Dolo 650',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 14),

                  _dropdown<MedicationForm>(
                    label: 'Form',
                    value: _draft.form,
                    values: MedicationForm.values,
                    labelFor: (MedicationForm form) => form.label,
                    onChanged: (MedicationForm? form) =>
                        setState(() => _draft = _draft.copyWith(form: form)),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _doseController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: _decoration('Dose', hint: 'e.g. 500'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _dropdown<DoseUnit>(
                          label: 'Unit',
                          value: _draft.doseUnit,
                          values: DoseUnit.values,
                          labelFor: (DoseUnit unit) => unit.label,
                          onChanged: (DoseUnit? unit) => setState(
                            () => _draft = _draft.copyWith(doseUnit: unit),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _dropdown<MedicationFrequency>(
                    label: 'How often',
                    value: _draft.frequency,
                    values: MedicationFrequency.values,
                    labelFor: (MedicationFrequency frequency) =>
                        frequency.label,
                    onChanged: (MedicationFrequency? frequency) => setState(
                      () => _draft = _draft.copyWith(frequency: frequency),
                    ),
                  ),

                  if (_draft.frequency?.isDaily ?? false) ...[
                    const SizedBox(height: 18),
                    Text(
                      'When in the day?',
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
                        for (final DoseTime time in DoseTime.values)
                          FilterChip(
                            label: Text(time.label),
                            selected: _draft.doseTimes.contains(time),
                            onSelected: (bool isSelected) {
                              final Set<DoseTime> updated = Set<DoseTime>.of(
                                _draft.doseTimes,
                              );

                              if (isSelected) {
                                updated.add(time);
                              } else {
                                updated.remove(time);
                              }

                              setState(
                                () => _draft = _draft.copyWith(
                                  doseTimes: updated,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    _DoseCountHint(
                      frequency: _draft.frequency!,
                      chosen: _draft.doseTimes.length,
                    ),
                  ],

                  const SizedBox(height: 18),

                  _dropdown<FoodTiming>(
                    label: 'With food?',
                    value: _draft.foodTiming,
                    values: FoodTiming.values,
                    labelFor: (FoodTiming timing) => timing.label,
                    onChanged: (FoodTiming? timing) => setState(
                      () => _draft = _draft.copyWith(foodTiming: timing),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _reasonController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration(
                      'What is it for? (optional)',
                      hint: 'e.g. blood pressure',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 14),

                  InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _decoration('Started on (optional)'),
                      child: Text(
                        _draft.startedOn == null
                            ? 'Not set'
                            : _formatDate(_draft.startedOn!),
                        style: TextStyle(
                          fontSize: 15,
                          color: _draft.startedOn == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            HealthSaveBar(
              onSave: () => Navigator.of(context).pop(_current),
              isSaving: false,
              hasChanges: true,
              label: 'Done',
            ),
          ],
        ),
      ),
    );
  }

  UserAllergy? _clashingAllergy(AllergyRecord allergies) {
    final AllergenType? allergen = _draft.ingredient.relatedAllergen;

    if (allergen == null) return null;

    for (final UserAllergy allergy in allergies.allergies) {
      if (allergy.type == allergen) return allergy;
    }

    return null;
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  static InputDecoration _decoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _dropdown<T extends Enum>({
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) labelFor,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label),
      hint: const Text('Not set'),
      items: [
        for (final T candidate in values)
          DropdownMenuItem<T>(
            value: candidate,
            child: Text(labelFor(candidate), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Points out when the chosen times do not add up to the stated frequency,
/// which usually means a dose is about to be forgotten.
class _DoseCountHint extends StatelessWidget {
  const _DoseCountHint({required this.frequency, required this.chosen});

  final MedicationFrequency frequency;
  final int chosen;

  @override
  Widget build(BuildContext context) {
    final int? expected = frequency.timesPerDay;

    if (expected == null || chosen == 0 || chosen == expected) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${frequency.label} usually means $expected times, '
        'but $chosen is selected.',
        style: const TextStyle(fontSize: 12.5, color: Color(0xffB45309)),
      ),
    );
  }
}

class _AllergyClashBanner extends StatelessWidget {
  const _AllergyClashBanner({
    required this.medicationName,
    required this.allergy,
  });

  final String medicationName;
  final UserAllergy allergy;

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You reported a ${allergy.displayName} allergy',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffB3261E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$medicationName belongs to that family. Keep it recorded '
                  'either way, but check with your doctor or pharmacist that '
                  'it is meant for you.',
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
