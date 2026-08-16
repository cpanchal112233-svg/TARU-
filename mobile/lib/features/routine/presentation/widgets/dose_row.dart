import 'package:flutter/material.dart';

import '../../../health_profile/domain/medication.dart';
import '../../domain/dose_schedule.dart';

/// One medicine dose row: primary logging action + separate Skip control.
class DoseRow extends StatelessWidget {
  const DoseRow({
    super.key,
    required this.dose,
    required this.status,
    required this.busy,
    required this.onSetStatus,
  });

  final ScheduledDose dose;
  final DoseStatus? status;
  final bool busy;
  final ValueChanged<DoseStatus?> onSetStatus;

  @override
  Widget build(BuildContext context) {
    final bool isTaken = status == DoseStatus.taken;
    final bool isSkipped = status == DoseStatus.skipped;

    final String? subtitle = _subtitleFor(dose.medication);
    final String semanticLabel = busy
        ? '${dose.medication.displayName}, Saving'
        : isTaken
        ? '${dose.medication.displayName}, recorded as taken'
        : isSkipped
        ? '${dose.medication.displayName}, recorded as skipped'
        : '${dose.medication.displayName}, not recorded as taken';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTaken
              ? const Color(0xff16A34A).withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  checked: isTaken,
                  enabled: !busy,
                  label: semanticLabel,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: busy
                        ? null
                        : () => onSetStatus(isTaken ? null : DoseStatus.taken),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              isTaken
                                  ? Icons.check_circle
                                  : isSkipped
                                  ? Icons.remove_circle_outline
                                  : Icons.circle_outlined,
                              color: isTaken
                                  ? const Color(0xff16A34A)
                                  : isSkipped
                                  ? Colors.grey.shade500
                                  : Colors.blue.shade300,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ExcludeSemantics(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dose.medication.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSkipped
                                          ? Colors.grey.shade600
                                          : Colors.black87,
                                      decoration: isSkipped
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (busy)
                            const ExcludeSemantics(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!busy)
                TextButton(
                  onPressed: () =>
                      onSetStatus(isSkipped ? null : DoseStatus.skipped),
                  child: Text(isSkipped ? 'Skipped' : 'Skip'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _subtitleFor(UserMedication medication) {
    final List<String> parts = [
      ?medication.doseSummary,
      if (medication.foodTiming != null &&
          medication.foodTiming != FoodTiming.noPreference)
        medication.foodTiming!.label,
    ];

    return parts.isEmpty ? null : parts.join('  •  ');
  }
}
