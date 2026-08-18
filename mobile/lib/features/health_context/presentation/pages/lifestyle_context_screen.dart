import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../health_profile/presentation/widgets/health_form_widgets.dart';
import '../../application/health_context_providers.dart';
import '../../domain/lifestyle_context.dart';

class LifestyleContextScreen extends ConsumerStatefulWidget {
  const LifestyleContextScreen({super.key});

  @override
  ConsumerState<LifestyleContextScreen> createState() =>
      _LifestyleContextScreenState();
}

class _LifestyleContextScreenState
    extends ConsumerState<LifestyleContextScreen> {
  LifestyleContext _draft = LifestyleContext.empty;
  bool _hydrated = false;
  bool _saving = false;
  late final TextEditingController _hours;

  @override
  void initState() {
    super.initState();
    _hours = TextEditingController();
  }

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LifestyleContext> async = ref.watch(
      lifestyleContextProvider,
    );
    async.whenData((LifestyleContext value) {
      if (!_hydrated) {
        _draft = value;
        _hours.text = value.usualSleepHours?.toString() ?? '';
        _hydrated = true;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Lifestyle'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: async.hasError
          ? Center(child: Text(userFacingErrorMessage(async.error!)))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const HealthNote(
                  icon: Icons.info_outline,
                  text:
                      'This describes what is generally true. Today’s sleep or '
                      'habits still belong on Routine. TARU does not score or '
                      'judge lifestyle.',
                ),
                const HealthSectionLabel('Sleep'),
                TextFormField(
                  controller: _hours,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Usual sleep hours',
                    helperText: 'Leave blank if not recorded',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _draft.usualSleepWindow,
                  decoration: const InputDecoration(
                    labelText: 'Usual sleep window',
                    helperText: 'For example 11pm–7am',
                  ),
                  onChanged: (String value) {
                    _draft = _copy(usualSleepWindow: value);
                  },
                ),
                const HealthSectionLabel('Activity'),
                RadioGroup<TypicalActivityLevel>(
                  groupValue: _draft.activityLevel,
                  onChanged: (TypicalActivityLevel? value) {
                    setState(() => _draft = _copy(activityLevel: value));
                  },
                  child: Column(
                    children: <Widget>[
                      for (final TypicalActivityLevel level
                          in TypicalActivityLevel.values)
                        RadioListTile<TypicalActivityLevel>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(activityLevelLabel(level)),
                          value: level,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(
                      () => _draft = LifestyleContext(
                        usualSleepHours: _draft.usualSleepHours,
                        usualSleepWindow: _draft.usualSleepWindow,
                        occupationActivity: _draft.occupationActivity,
                        tobaccoUse: _draft.tobaccoUse,
                        alcoholUse: _draft.alcoholUse,
                        caffeineUse: _draft.caffeineUse,
                        notes: _draft.notes,
                        provenance: _draft.provenance,
                      ),
                    );
                  },
                  child: const Text('Clear activity (leave not recorded)'),
                ),
                TextFormField(
                  initialValue: _draft.occupationActivity,
                  decoration: const InputDecoration(
                    labelText: 'Occupation or activity pattern',
                  ),
                  onChanged: (String value) {
                    _draft = _copy(occupationActivity: value);
                  },
                ),
                const HealthSectionLabel('Tobacco, alcohol, caffeine'),
                _substance('Tobacco', _draft.tobaccoUse, (
                  SubstanceUsePattern? v,
                ) {
                  setState(
                    () =>
                        _draft = _copy(tobaccoUse: v, clearTobacco: v == null),
                  );
                }),
                _substance('Alcohol', _draft.alcoholUse, (
                  SubstanceUsePattern? v,
                ) {
                  setState(
                    () =>
                        _draft = _copy(alcoholUse: v, clearAlcohol: v == null),
                  );
                }),
                _substance('Caffeine', _draft.caffeineUse, (
                  SubstanceUsePattern? v,
                ) {
                  setState(
                    () => _draft = _copy(
                      caffeineUse: v,
                      clearCaffeine: v == null,
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _draft.notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                  onChanged: (String value) => _draft = _copy(notes: value),
                ),
              ],
            ),
    );
  }

  Widget _substance(
    String label,
    SubstanceUsePattern? value,
    ValueChanged<SubstanceUsePattern?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Not recorded'),
              selected: value == null,
              onSelected: (_) => onChanged(null),
            ),
            for (final SubstanceUsePattern pattern
                in SubstanceUsePattern.values)
              ChoiceChip(
                label: Text(substanceUseLabel(pattern)),
                selected: value == pattern,
                onSelected: (_) => onChanged(pattern),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  LifestyleContext _copy({
    String? usualSleepWindow,
    TypicalActivityLevel? activityLevel,
    String? occupationActivity,
    SubstanceUsePattern? tobaccoUse,
    SubstanceUsePattern? alcoholUse,
    SubstanceUsePattern? caffeineUse,
    String? notes,
    bool clearTobacco = false,
    bool clearAlcohol = false,
    bool clearCaffeine = false,
  }) {
    return _draft.copyWith(
      usualSleepHours:
          double.tryParse(_hours.text.trim()) ?? _draft.usualSleepHours,
      usualSleepWindow: usualSleepWindow,
      activityLevel: activityLevel,
      occupationActivity: occupationActivity,
      tobaccoUse: tobaccoUse,
      alcoholUse: alcoholUse,
      caffeineUse: caffeineUse,
      notes: notes,
      clearTobacco: clearTobacco,
      clearAlcohol: clearAlcohol,
      clearCaffeine: clearCaffeine,
    );
  }

  Future<void> _save() async {
    final User? user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    setState(() => _saving = true);
    final LifestyleContext toSave = _copy();
    try {
      await ref.read(lifestyleContextRepositoryProvider).save(user.uid, toSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lifestyle context saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
