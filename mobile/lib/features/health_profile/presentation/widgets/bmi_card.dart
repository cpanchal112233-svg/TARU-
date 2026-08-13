import 'package:flutter/material.dart';

/// Shows the BMI derived from the entered height and weight.
///
/// Displays the numeric ratio only — no clinical category labels or
/// traffic-light classification.
class BmiCard extends StatelessWidget {
  const BmiCard({
    super.key,
    required this.bmi,
    this.needsCaveat = false,
  });

  final double? bmi;

  /// True when BMI is a poor guide for this person, e.g. during pregnancy.
  final bool needsCaveat;

  static const Color _accent = Color(0xff2563EB);

  @override
  Widget build(BuildContext context) {
    final double? value = bmi;

    if (value == null) {
      return _Shell(
        child: Row(
          children: [
            Icon(Icons.straighten, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add your height and weight to see your BMI.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'BMI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'BMI is a height-to-weight ratio and is not a diagnosis.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          if (needsCaveat) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BMI is not a reliable guide during pregnancy, while '
                    'breastfeeding, or while you are still growing. Treat this '
                    'as background information only.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
