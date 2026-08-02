import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/health_profile_providers.dart';
import '../../domain/health_profile.dart';
import '../../domain/health_units.dart';
import '../widgets/bmi_card.dart';

/// Collects the clinical basics: who this person is, in medical terms.
///
/// Every field is optional so the form can be filled over time; the completeness
/// indicator is what nudges people to finish it.
class HealthProfileScreen extends ConsumerWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HealthProfile> profile = ref.watch(healthProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Health Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(profile),
    );
  }

  Widget _buildBody(AsyncValue<HealthProfile> profile) {
    if (profile.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load your health profile.\n${profile.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!profile.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    return _HealthProfileForm(
      initialProfile: profile.value ?? HealthProfile.empty,
    );
  }
}

class _HealthProfileForm extends ConsumerStatefulWidget {
  const _HealthProfileForm({required this.initialProfile});

  final HealthProfile initialProfile;

  @override
  ConsumerState<_HealthProfileForm> createState() => _HealthProfileFormState();
}

class _HealthProfileFormState extends ConsumerState<_HealthProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactRelationController =
      TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  late UnitSystem _units;

  DateTime? _dateOfBirth;
  BiologicalSex? _biologicalSex;
  BloodGroup? _bloodGroup;
  PregnancyStatus? _pregnancyStatus;

  /// Height and weight are held in metric no matter which units are displayed,
  /// so switching units can never corrupt what gets saved.
  double? _heightCm;
  double? _weightKg;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final HealthProfile profile = widget.initialProfile;

    _units = profile.preferredUnits;
    _dateOfBirth = profile.dateOfBirth;
    _biologicalSex = profile.biologicalSex;
    _bloodGroup = profile.bloodGroup;
    _pregnancyStatus = profile.pregnancyStatus;
    _heightCm = profile.heightCm;
    _weightKg = profile.weightKg;

    _contactNameController.text = profile.emergencyContactName ?? '';
    _contactRelationController.text = profile.emergencyContactRelation ?? '';
    _contactPhoneController.text = profile.emergencyContactPhone ?? '';

    _syncMeasurementFields();
  }

  @override
  void dispose() {
    _heightCmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    _contactNameController.dispose();
    _contactRelationController.dispose();
    _contactPhoneController.dispose();

    super.dispose();
  }

  /// Rewrites the visible measurement fields from the stored metric values.
  void _syncMeasurementFields() {
    final double? heightCm = _heightCm;
    final double? weightKg = _weightKg;

    switch (_units) {
      case UnitSystem.metric:
        _heightCmController.text = heightCm == null
            ? ''
            : _trimTrailingZero(heightCm);
        _weightController.text = weightKg == null
            ? ''
            : _trimTrailingZero(weightKg);
      case UnitSystem.imperial:
        if (heightCm == null) {
          _feetController.text = '';
          _inchesController.text = '';
        } else {
          final ({int feet, int inches}) height =
              HealthUnits.centimetresToFeetAndInches(heightCm);

          _feetController.text = height.feet.toString();
          _inchesController.text = height.inches.toString();
        }

        _weightController.text = weightKg == null
            ? ''
            : _trimTrailingZero(HealthUnits.kilogramsToPounds(weightKg));
    }
  }

  void _onUnitsChanged(UnitSystem units) {
    setState(() {
      _units = units;
      _syncMeasurementFields();
    });
  }

  void _onHeightChanged() {
    setState(() {
      switch (_units) {
        case UnitSystem.metric:
          _heightCm = double.tryParse(_heightCmController.text.trim());
        case UnitSystem.imperial:
          final int? feet = int.tryParse(_feetController.text.trim());
          final double inches =
              double.tryParse(_inchesController.text.trim()) ?? 0;

          _heightCm = feet == null
              ? null
              : HealthUnits.feetAndInchesToCentimetres(feet, inches);
      }
    });
  }

  void _onWeightChanged() {
    final double? entered = double.tryParse(_weightController.text.trim());

    setState(() {
      _weightKg = switch (_units) {
        UnitSystem.metric => entered,
        UnitSystem.imperial =>
          entered == null ? null : HealthUnits.poundsToKilograms(entered),
      };
    });
  }

  /// The profile as it stands right now, used for the live BMI readout.
  HealthProfile get _draftProfile => HealthProfile(
    dateOfBirth: _dateOfBirth,
    biologicalSex: _biologicalSex,
    heightCm: _heightCm,
    weightKg: _weightKg,
    bloodGroup: _bloodGroup,
    pregnancyStatus: _pregnancyStatus,
    emergencyContactName: _contactNameController.text,
    emergencyContactRelation: _contactRelationController.text,
    emergencyContactPhone: _contactPhoneController.text,
    preferredUnits: _units,
  );

  Future<void> _pickDateOfBirth() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Select your date of birth',
    );

    if (picked == null || !mounted) return;

    setState(() => _dateOfBirth = picked);
  }

  bool get _hasUnsavedChanges =>
      !_draftProfile.hasSameAnswersAs(widget.initialProfile);

  /// Asks before throwing away medical details someone just typed in.
  Future<bool> _confirmDiscard() async {
    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your health profile has unsaved changes. Leaving now will lose them.',
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(saveHealthProfileProvider)(_draftProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Health profile saved.')));

      // pop rather than maybePop: the work is saved, so the unsaved-changes
      // guard must not intercept this.
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final HealthProfile draft = _draftProfile;

    return PopScope(
      // Only intercepts when there is something to lose, so the iOS swipe-back
      // gesture keeps working on an untouched form.
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final bool shouldDiscard = await _confirmDiscard();

        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildForm(draft),
    );
  }

  Widget _buildForm(HealthProfile draft) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          const _PrivacyNote(),

          const SizedBox(height: 24),

          _SectionHeader(
            title: 'Units',
            subtitle:
                'Enter measurements however you normally think about them.',
          ),
          SegmentedButton<UnitSystem>(
            segments: [
              for (final UnitSystem system in UnitSystem.values)
                ButtonSegment<UnitSystem>(
                  value: system,
                  label: Text('${system.label} (${system.weightUnit})'),
                ),
            ],
            selected: <UnitSystem>{_units},
            onSelectionChanged: (Set<UnitSystem> selection) =>
                _onUnitsChanged(selection.first),
          ),

          const SizedBox(height: 28),

          _SectionHeader(
            title: 'About you',
            subtitle:
                'Age and sex change what is normal for almost every test '
                'result and dose.',
          ),
          _DateOfBirthField(
            dateOfBirth: _dateOfBirth,
            ageInYears: draft.ageInYears,
            onTap: _pickDateOfBirth,
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<BiologicalSex>(
            initialValue: _biologicalSex,
            decoration: _fieldDecoration('Biological sex'),
            items: [
              for (final BiologicalSex sex in BiologicalSex.values)
                DropdownMenuItem<BiologicalSex>(
                  value: sex,
                  child: Text(sex.label),
                ),
            ],
            onChanged: (BiologicalSex? sex) {
              setState(() {
                _biologicalSex = sex;

                // Drop an answer that no longer applies rather than storing
                // something misleading.
                if (!_draftProfile.pregnancyQuestionApplies) {
                  _pregnancyStatus = null;
                }
              });
            },
          ),

          if (draft.pregnancyQuestionApplies) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<PregnancyStatus>(
              initialValue: _pregnancyStatus,
              decoration: _fieldDecoration(
                'Pregnancy status',
                helper:
                    'Some common medicines are unsafe while pregnant or '
                    'breastfeeding.',
              ),
              items: [
                for (final PregnancyStatus status in PregnancyStatus.values)
                  DropdownMenuItem<PregnancyStatus>(
                    value: status,
                    child: Text(status.label),
                  ),
              ],
              onChanged: (PregnancyStatus? status) =>
                  setState(() => _pregnancyStatus = status),
            ),
          ],

          const SizedBox(height: 16),

          DropdownButtonFormField<BloodGroup>(
            initialValue: _bloodGroup,
            decoration: _fieldDecoration('Blood group'),
            items: [
              for (final BloodGroup group in BloodGroup.values)
                DropdownMenuItem<BloodGroup>(
                  value: group,
                  child: Text(group.label),
                ),
            ],
            onChanged: (BloodGroup? group) =>
                setState(() => _bloodGroup = group),
          ),

          const SizedBox(height: 28),

          _SectionHeader(
            title: 'Body measurements',
            subtitle: 'Used for dosing guidance and to track change over time.',
          ),
          if (_units == UnitSystem.metric)
            TextFormField(
              controller: _heightCmController,
              keyboardType: TextInputType.number,
              inputFormatters: [_decimalInputFormatter],
              decoration: _fieldDecoration('Height (cm)'),
              validator: _validateHeightCm,
              onChanged: (_) => _onHeightChanged(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _feetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration('Height (ft)'),
                    validator: _validateFeet,
                    onChanged: (_) => _onHeightChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _inchesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _fieldDecoration('Inches'),
                    validator: _validateInches,
                    onChanged: (_) => _onHeightChanged(),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            inputFormatters: [_decimalInputFormatter],
            decoration: _fieldDecoration('Weight (${_units.weightUnit})'),
            validator: _validateWeight,
            onChanged: (_) => _onWeightChanged(),
          ),

          const SizedBox(height: 20),

          BmiCard(
            bmi: draft.bmi,
            category: draft.bmiCategory,
            needsCaveat: draft.bmiNeedsCaveat,
          ),

          const SizedBox(height: 28),

          _SectionHeader(
            title: 'Emergency contact',
            subtitle: 'Who TARU should point to if something looks urgent.',
          ),
          TextFormField(
            controller: _contactNameController,
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('Full name'),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _contactRelationController,
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('Relationship', hint: 'e.g. Spouse'),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration('Phone number'),
            validator: _validatePhone,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Saving...' : 'Save health profile'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION
  //
  // Ranges are deliberately wide: the aim is to catch typos such as a height
  // of 17 cm, not to argue with unusual but real measurements.
  // ============================================================

  String? _validateHeightCm(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final double? centimetres = double.tryParse(text);

    if (centimetres == null) return 'Enter a number';
    if (centimetres < 40 || centimetres > 260) {
      return 'Enter a height between 40 and 260 cm';
    }

    return null;
  }

  String? _validateFeet(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final int? feet = int.tryParse(text);

    if (feet == null) return 'Enter a number';
    if (feet < 1 || feet > 8) return 'Enter 1 to 8 ft';

    return null;
  }

  String? _validateInches(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final int? inches = int.tryParse(text);

    if (inches == null) return 'Enter a number';
    if (inches > 11) return '0 to 11 in';

    return null;
  }

  String? _validateWeight(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final double? entered = double.tryParse(text);

    if (entered == null) return 'Enter a number';

    final double kilograms = switch (_units) {
      UnitSystem.metric => entered,
      UnitSystem.imperial => HealthUnits.poundsToKilograms(entered),
    };

    if (kilograms < 2 || kilograms > 400) {
      return 'Enter a weight in ${_units.weightUnit}';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final int digitCount = text.replaceAll(RegExp(r'\D'), '').length;

    if (digitCount < 6) return 'Enter a complete phone number';

    return null;
  }

  static final TextInputFormatter _decimalInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

  static String _trimTrailingZero(double value) {
    final String fixed = value.toStringAsFixed(1);

    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  /// Units live in the label rather than [InputDecoration.suffixText], which
  /// Flutter only renders once a field is focused or filled.
  InputDecoration _fieldDecoration(
    String label, {
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.dateOfBirth,
    required this.ageInYears,
    required this.onTap,
  });

  final DateTime? dateOfBirth;
  final int? ageInYears;
  final VoidCallback onTap;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime? date = dateOfBirth;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of birth',
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          date == null
              ? 'Tap to select'
              : '${date.day} ${_monthNames[date.month - 1]} ${date.year}'
                    '${ageInYears == null ? '' : '  •  $ageInYears years old'}',
          style: TextStyle(
            fontSize: 16,
            color: date == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

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
          const Icon(Icons.lock_outline, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Only you can see this. TARU uses it to give advice that fits '
              'your body instead of generic guidance.',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
