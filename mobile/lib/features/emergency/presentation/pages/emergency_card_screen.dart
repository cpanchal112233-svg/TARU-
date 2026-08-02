import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../health_profile/application/allergies_providers.dart';
import '../../../health_profile/application/conditions_providers.dart';
import '../../../health_profile/application/health_profile_providers.dart';
import '../../../health_profile/application/medications_providers.dart';
import '../../../health_profile/domain/allergy.dart';
import '../../../health_profile/domain/health_profile.dart';
import '../../../health_profile/domain/medical_condition.dart';
import '../../../health_profile/domain/medication.dart';
import '../../../profile/application/user_profile_providers.dart';

/// Everything a paramedic, pharmacist or bystander would need, on one screen.
///
/// Designed to be handed to a stranger: large type, no navigation, no
/// scrolling required for the life-threatening parts, and worded so an empty
/// section never reads as "nothing to worry about" when it really means
/// "never asked".
class EmergencyCardScreen extends ConsumerWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HealthProfile profile =
        ref.watch(healthProfileProvider).value ?? HealthProfile.empty;

    final AllergyRecord allergies =
        ref.watch(allergiesProvider).value ?? AllergyRecord.empty;

    final ConditionRecord conditions =
        ref.watch(conditionsProvider).value ?? ConditionRecord.empty;

    final MedicationRecord medications =
        ref.watch(medicationsProvider).value ?? MedicationRecord.empty;

    final String name = ref.watch(userDisplayNameProvider).value ?? '';

    final List<UserAllergy> severe = allergies.emergencyRisks;

    final List<UserAllergy> otherAllergies = allergies.allergies
        .where((UserAllergy allergy) => !allergy.isEmergencyRisk)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency card'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Header(name: name, profile: profile),

          const SizedBox(height: 20),

          _BloodGroupTile(bloodGroup: profile.bloodGroup),

          const SizedBox(height: 20),

          _Section(
            title: 'Severe allergies',
            isAlarming: severe.isNotEmpty,
            child: severe.isEmpty
                ? _PlainNote(
                    allergies.hasAnswered
                        ? 'None reported.'
                        : 'Not recorded. Do not assume there are none.',
                    isMissing: !allergies.hasAnswered,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final UserAllergy allergy in severe)
                        _SevereAllergyRow(allergy: allergy),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Other allergies',
            child: otherAllergies.isEmpty
                ? _PlainNote(
                    allergies.noKnownAllergies
                        ? 'No known allergies.'
                        : allergies.hasAnswered
                        ? 'None besides those above.'
                        : 'Not recorded.',
                    isMissing: !allergies.hasAnswered,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final UserAllergy allergy in otherAllergies)
                        _BulletLine(
                          text: allergy.displayName,
                          detail: allergy.severity?.label,
                        ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Medical conditions',
            child: conditions.conditions.isEmpty
                ? _PlainNote(
                    conditions.noKnownConditions
                        ? 'No ongoing conditions reported.'
                        : 'Not recorded.',
                    isMissing: !conditions.hasAnswered,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final UserCondition condition
                          in conditions.conditions)
                        _BulletLine(
                          text: condition.displayName,
                          detail: condition.detailSummary,
                        ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          _Section(
            title: 'Current medicines',
            child: medications.medications.isEmpty
                ? _PlainNote(
                    medications.takesNoMedication
                        ? 'Takes no medicines.'
                        : 'Not recorded.',
                    isMissing: !medications.hasAnswered,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final UserMedication medication
                          in medications.medications)
                        _BulletLine(
                          text: medication.displayName,
                          detail: medication.scheduleSummary,
                        ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          _EmergencyContact(profile: profile),

          const SizedBox(height: 24),

          Text(
            'Entered by the user in TARU. This is not a medical document and '
            'may be incomplete or out of date.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.profile});

  final String name;
  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    final int? age = profile.ageInYears;

    final List<String> descriptors = [
      if (age != null) '$age years old',
      if (profile.biologicalSex != null) profile.biologicalSex!.label,
      if (profile.pregnancyStatus == PregnancyStatus.pregnant) 'Pregnant',
      if (profile.pregnancyStatus == PregnancyStatus.breastfeeding)
        'Breastfeeding',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffB3261E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'EMERGENCY MEDICAL INFORMATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name.isEmpty ? 'Name not set' : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (descriptors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              descriptors.join('  •  '),
              style: const TextStyle(color: Colors.white, fontSize: 15.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _BloodGroupTile extends StatelessWidget {
  const _BloodGroupTile({required this.bloodGroup});

  final BloodGroup? bloodGroup;

  @override
  Widget build(BuildContext context) {
    final bool isKnown = bloodGroup != null && bloodGroup != BloodGroup.unknown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            'BLOOD GROUP',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            isKnown ? bloodGroup!.label : 'Not recorded',
            style: TextStyle(
              fontSize: isKnown ? 32 : 16,
              fontWeight: FontWeight.bold,
              color: isKnown ? const Color(0xff0F172A) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.isAlarming = false,
  });

  final String title;
  final Widget child;
  final bool isAlarming;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAlarming ? const Color(0xffFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlarming ? const Color(0xffB3261E) : Colors.grey.shade300,
          width: isAlarming ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isAlarming
                  ? const Color(0xffB3261E)
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SevereAllergyRow extends StatelessWidget {
  const _SevereAllergyRow({required this.allergy});

  final UserAllergy allergy;

  @override
  Widget build(BuildContext context) {
    final List<String> reactions = allergy.reactions
        .map((AllergyReaction reaction) => reaction.label.toLowerCase())
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allergy.displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff7F1D1D),
            ),
          ),
          if (reactions.isNotEmpty)
            Text(
              reactions.join(', '),
              style: const TextStyle(fontSize: 14.5, color: Color(0xff7F1D1D)),
            ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 17)),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  if (detail != null)
                    TextSpan(
                      text: '  $detail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainNote extends StatelessWidget {
  const _PlainNote(this.text, {this.isMissing = false});

  final String text;
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.5,
        fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
        color: isMissing ? const Color(0xffB45309) : Colors.grey.shade800,
      ),
    );
  }
}

class _EmergencyContact extends StatelessWidget {
  const _EmergencyContact({required this.profile});

  final HealthProfile profile;

  Future<void> _call(BuildContext context, String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);

    try {
      final bool launched = await launchUrl(uri);

      if (launched || !context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a call to $phone.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start a call: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!profile.hasEmergencyContact) {
      return const _Section(
        title: 'Emergency contact',
        child: _PlainNote('Not recorded.', isMissing: true),
      );
    }

    final String phone = profile.emergencyContactPhone!.trim();
    final String? relation = profile.emergencyContactRelation?.trim();

    return _Section(
      title: 'Emergency contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.emergencyContactName!.trim(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (relation != null && relation.isNotEmpty)
            Text(
              relation,
              style: TextStyle(fontSize: 14.5, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 4),
          Text(phone, style: const TextStyle(fontSize: 19, letterSpacing: 0.5)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffB3261E),
              ),
              onPressed: () => _call(context, phone),
              icon: const Icon(Icons.call),
              label: const Text('Call now', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
