import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Progress'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const FeaturePlaceholder(
        icon: Icons.insights_outlined,
        title: 'Track Your Progress',
        description:
            'See how your habits and health metrics improve over time with '
            'clear insights and trends.',
        phaseHint: 'Coming in Phase 5',
      ),
    );
  }
}
