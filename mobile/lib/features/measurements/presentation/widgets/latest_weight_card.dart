import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/application/health_profile_providers.dart';
import '../../../health_profile/domain/health_units.dart';
import '../../application/measurements_providers.dart';
import '../../domain/weight_measurement.dart';
import '../pages/weight_history_screen.dart';

/// Progress "Weight" zone — outside the Last 7 days logging review.
class LatestWeightCard extends ConsumerWidget {
  const LatestWeightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WeightMeasurement?> latest = ref.watch(
      latestWeightMeasurementProvider,
    );
    final UnitSystem units =
        ref.watch(healthProfileProvider).value?.preferredUnits ??
        UnitSystem.metric;

    return latest.when(
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stack) => _Card(
        child: Text(
          'Could not load latest weight.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
      data: (WeightMeasurement? measurement) {
        if (measurement == null) {
          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No recorded weight history yet. Start tracking from '
                  'Weight history — TARU will not invent entries from your '
                  'profile snapshot.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _openHistory(context),
                  child: const Text('View weight history'),
                ),
              ],
            ),
          );
        }

        final DateTime local = measurement.recordedAt.toLocal();
        final String dateLabel =
            '${local.day} ${_month(local.month)} ${local.year}';

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _format(measurement.valueKg, units),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Latest weight · recorded $dateLabel',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _openHistory(context),
                child: const Text('View weight history'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WeightHistoryScreen()),
    );
  }

  String _format(double valueKg, UnitSystem units) {
    switch (units) {
      case UnitSystem.metric:
        return '${_trim(valueKg)} kg';
      case UnitSystem.imperial:
        return '${_trim(HealthUnits.kilogramsToPounds(valueKg))} lb';
    }
  }

  String _trim(double value) {
    final String fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  String _month(int month) {
    const List<String> names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
