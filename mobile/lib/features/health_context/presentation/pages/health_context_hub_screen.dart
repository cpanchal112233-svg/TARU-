import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/presentation/pages/allergies_screen.dart';
import '../../../health_profile/presentation/pages/conditions_screen.dart';
import '../../../health_profile/presentation/pages/health_profile_screen.dart';
import '../../../health_profile/presentation/pages/medications_screen.dart';
import '../widgets/health_context_widgets.dart';
import 'care_team_screen.dart';
import 'dietary_profile_screen.dart';
import 'family_history_screen.dart';
import 'health_goals_screen.dart';
import 'immunizations_screen.dart';
import 'lifestyle_context_screen.dart';
import 'procedures_screen.dart';
import 'supplements_screen.dart';

/// Hub for structured personal context. Does not duplicate existing
/// conditions/allergies/medicines — those stay on their own screens.
class HealthContextHubScreen extends ConsumerWidget {
  const HealthContextHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Health context'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Record what is generally true about you. This is not a diagnosis, '
              'diet plan, or care recommendation. Missing sections stay “not '
              'recorded”.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.45),
            ),
            const SizedBox(height: 20),
            Text(
              'Already in TARU',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            HealthContextTile(
              title: 'Health profile',
              subtitle: 'Basics you already record',
              onTap: () => _open(context, const HealthProfileScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Conditions',
              subtitle: 'Self-reported conditions',
              onTap: () => _open(context, const ConditionsScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Allergies',
              subtitle:
                  'Medical allergy records — separate from food preference',
              onTap: () => _open(context, const AllergiesScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Medicines',
              subtitle: 'Prescription and regular medicines',
              onTap: () => _open(context, const MedicationsScreen()),
            ),
            const SizedBox(height: 24),
            Text(
              'Additional context',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            HealthContextTile(
              title: 'Diet & food preferences',
              subtitle: 'Pattern, dislikes, and avoidances — not allergies',
              onTap: () => _open(context, const DietaryProfileScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Supplements',
              subtitle: 'Vitamins, herbal, and other non-prescription products',
              onTap: () => _open(context, const SupplementsScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Family history',
              subtitle: 'What you know about relatives — no genetic risk score',
              onTap: () => _open(context, const FamilyHistoryScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Procedures & surgeries',
              subtitle: 'Operations and procedures you remember',
              onTap: () => _open(context, const ProceduresScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Vaccinations',
              subtitle: 'Immunisations you choose to record',
              onTap: () => _open(context, const ImmunizationsScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Lifestyle',
              subtitle:
                  'What is generally true — not today’s routine checklist',
              onTap: () => _open(context, const LifestyleContextScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Health goals',
              subtitle: 'Your aims. Dates are targets, not predicted recovery',
              onTap: () => _open(context, const HealthGoalsScreen()),
            ),
            const SizedBox(height: 12),
            HealthContextTile(
              title: 'Care team',
              subtitle:
                  'Clinicians you note for yourself — TARU does not contact them',
              onTap: () => _open(context, const CareTeamScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
