import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const FeaturePlaceholder(
        icon: Icons.description_outlined,
        title: 'Medical Reports',
        description:
            'Upload lab results and medical documents. TARU will help you '
            'understand them in plain language.',
        phaseHint: 'Coming in Phase 2',
      ),
    );
  }
}
