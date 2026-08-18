import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../health_profile/presentation/widgets/health_form_widgets.dart';
import '../../application/health_context_providers.dart';
import '../../domain/dietary_profile.dart';
import '../widgets/health_context_widgets.dart';

class DietaryProfileScreen extends ConsumerStatefulWidget {
  const DietaryProfileScreen({super.key});

  @override
  ConsumerState<DietaryProfileScreen> createState() =>
      _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends ConsumerState<DietaryProfileScreen> {
  DietaryProfile _draft = DietaryProfile.empty;
  bool _hydrated = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DietaryProfile> async = ref.watch(dietaryProfileProvider);
    async.whenData((DietaryProfile value) {
      if (!_hydrated) {
        _draft = value;
        _hydrated = true;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Diet & food preferences'),
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
                      'This is preference and avoidance, not a medical allergy '
                      'record. Food allergies stay under Allergies. TARU does '
                      'not infer diet from religion, name, or location.',
                ),
                const HealthSectionLabel('Pattern'),
                RadioGroup<DietaryPattern>(
                  groupValue: _draft.pattern,
                  onChanged: (DietaryPattern? value) {
                    setState(() {
                      _draft = _draft.copyWith(pattern: value);
                    });
                  },
                  child: Column(
                    children: <Widget>[
                      for (final DietaryPattern pattern
                          in DietaryPattern.values)
                        RadioListTile<DietaryPattern>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(DietarySemantics.label(pattern)),
                          subtitle: Text(DietarySemantics.description(pattern)),
                          value: pattern,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _draft = _draft.copyWith(clearPattern: true);
                    });
                  },
                  child: const Text('Clear pattern (leave not recorded)'),
                ),
                const HealthSectionLabel('Avoidances and dislikes'),
                CommaSeparatedField(
                  label: 'Foods avoided',
                  helper: 'Preference or restriction, not allergy',
                  values: _draft.avoidedFoods,
                  onChanged: (List<String> values) {
                    setState(() {
                      _draft = _draft.copyWith(avoidedFoods: values);
                    });
                  },
                ),
                const SizedBox(height: 12),
                CommaSeparatedField(
                  label: 'Ingredients avoided',
                  helper: 'For example onion, garlic, gelatin',
                  values: _draft.avoidedIngredients,
                  onChanged: (List<String> values) {
                    setState(() {
                      _draft = _draft.copyWith(avoidedIngredients: values);
                    });
                  },
                ),
                const SizedBox(height: 12),
                CommaSeparatedField(
                  label: 'Foods disliked',
                  helper: 'Personal dislike, not medical intolerance',
                  values: _draft.dislikedFoods,
                  onChanged: (List<String> values) {
                    setState(() {
                      _draft = _draft.copyWith(dislikedFoods: values);
                    });
                  },
                ),
                const SizedBox(height: 12),
                CommaSeparatedField(
                  label: 'Optional cultural or personal constraints',
                  helper:
                      'Only if you choose — for example no beef, Halal '
                      'preference, fasting pattern. TARU does not assume these.',
                  values: _draft.culturalConstraints,
                  onChanged: (List<String> values) {
                    setState(() {
                      _draft = _draft.copyWith(culturalConstraints: values);
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _draft.notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                  onChanged: (String value) {
                    setState(() {
                      _draft = _draft.copyWith(notes: value);
                    });
                  },
                ),
              ],
            ),
    );
  }

  Future<void> _save() async {
    final User? user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(dietaryProfileRepositoryProvider).save(user.uid, _draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet preferences saved.')),
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
