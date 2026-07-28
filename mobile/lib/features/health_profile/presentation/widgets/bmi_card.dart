import 'package:flutter/material.dart';

import '../../domain/health_profile.dart';

/// Shows the BMI derived from the entered height and weight.
class BmiCard extends StatelessWidget {
  const BmiCard({super.key, required this.bmi, required this.category, this.needsCaveat = false});

  final double? bmi;
  final BmiCategory? category;

  /// True when BMI is a poor guide for this person, e.g. during pregnancy.
  final bool needsCaveat;

  @override
  Widget build(BuildContext context) {
    final double? value = bmi;
    final BmiCategory? bmiCategory = category;

    if (value == null || bmiCategory == null) {
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

    final Color accent = _accentFor(bmiCategory);

    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: accent,
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory.label,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BmiScale(category: bmiCategory),
          if (needsCaveat) ...[
            const SizedBox(height: 14),
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

  static Color _accentFor(BmiCategory category) {
    return switch (category) {
      BmiCategory.underweight => const Color(0xffF59E0B),
      BmiCategory.healthy => const Color(0xff16A34A),
      BmiCategory.overweight => const Color(0xffF97316),
      BmiCategory.obese => const Color(0xffDC2626),
    };
  }
}

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.category});

  final BmiCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final BmiCategory segment in BmiCategory.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: segment == category
                          ? BmiCard._accentFor(segment)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shortLabel(segment),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: segment == category
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: segment == category
                          ? BmiCard._accentFor(segment)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _shortLabel(BmiCategory category) {
    return switch (category) {
      BmiCategory.underweight => 'Under 18.5',
      BmiCategory.healthy => '18.5–24.9',
      BmiCategory.overweight => '25–29.9',
      BmiCategory.obese => '30+',
    };
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
