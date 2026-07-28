import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Routine'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const FeaturePlaceholder(
        icon: Icons.calendar_today_outlined,
        title: 'Daily Health Routine',
        description:
            'Medication reminders, diet, exercise, sleep, and mindfulness — '
            'personalized for your day.',
        phaseHint: 'Coming in Phase 4',
      ),
    );
  }
}
