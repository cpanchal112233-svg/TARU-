import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/interaction_providers.dart';
import '../../domain/medicine_checker.dart';
import '../../domain/medicine_warning.dart';
import '../pages/medicine_safety_screen.dart';
import 'medicine_warning_widgets.dart';

/// Home-screen prompt that appears only when there is something to say about
/// the user's medicines.
///
/// A permanent "all clear" tile would be one more thing to scroll past every
/// day; a warning that only shows up when it applies keeps its weight.
class MedicineSafetyBanner extends ConsumerWidget {
  const MedicineSafetyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MedicineWarning> warnings = ref.watch(medicineWarningsProvider);
    final MedicineWarningSeverity? severity = warnings.highestSeverity;

    if (severity == null) return const SizedBox.shrink();

    final MedicineWarningStyle style = MedicineWarningStyle.of(severity);
    final int count = warnings.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: style.tint,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MedicineSafetyScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(style.icon, color: style.colour),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1
                            ? '1 thing to check about your medicines'
                            : '$count things to check about your medicines',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: style.colour,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        severity.summary,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: style.colour),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
