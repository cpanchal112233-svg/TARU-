import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/application/health_profile_providers.dart';
import '../../../health_profile/domain/health_units.dart';
import '../../application/measurements_providers.dart';
import '../../domain/blood_pressure_measurement.dart';
import '../../domain/weight_measurement.dart';
import '../pages/blood_pressure_history_screen.dart';
import '../pages/weight_history_screen.dart';

/// Compact Progress "Measurements" area — independent of Last 7 Days.
class ProgressMeasurementsSection extends ConsumerWidget {
  const ProgressMeasurementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WeightMeasurement?> weightAsync = ref.watch(
      latestWeightMeasurementProvider,
    );
    final AsyncValue<BloodPressureMeasurement?> bpAsync = ref.watch(
      latestBloodPressureProvider,
    );
    final UnitSystem units =
        ref.watch(healthProfileProvider).value?.preferredUnits ??
        UnitSystem.metric;

    final bool weightLoading = weightAsync.isLoading;
    final bool bpLoading = bpAsync.isLoading;
    if (weightLoading && bpLoading) {
      return const SizedBox.shrink();
    }

    final WeightMeasurement? weight = weightAsync.asData?.value;
    final BloodPressureMeasurement? bp = bpAsync.asData?.value;
    final Object? weightError = weightAsync.asError?.error;
    final Object? bpError = bpAsync.asError?.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest recorded values — not a medical assessment.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          if (weightError != null)
            _ErrorLine(text: 'Could not load latest weight.')
          else
            _WeightRow(measurement: weight, units: units),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          if (bpError != null)
            _ErrorLine(text: 'Could not load latest blood pressure.')
          else
            _BloodPressureRow(measurement: bp),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.measurement, required this.units});

  final WeightMeasurement? measurement;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        if (measurement == null) ...[
          Text(
            'No recorded weight yet.',
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _openWeight(context),
                child: const Text('Add reading'),
              ),
              TextButton(
                onPressed: () => _openWeight(context),
                child: const Text('View history'),
              ),
            ],
          ),
        ] else ...[
          Text(
            _formatWeight(measurement!.valueKg, units),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Recorded ${_formatWhen(measurement!.recordedAt)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _openWeight(context),
                child: const Text('View history'),
              ),
              TextButton(
                onPressed: () => _openWeight(context),
                child: const Text('Add reading'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _openWeight(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WeightHistoryScreen()),
    );
  }
}

class _BloodPressureRow extends StatelessWidget {
  const _BloodPressureRow({required this.measurement});

  final BloodPressureMeasurement? measurement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blood pressure',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        if (measurement == null) ...[
          Text(
            'No blood pressure readings recorded yet.',
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _openBp(context),
                child: const Text('Add reading'),
              ),
              TextButton(
                onPressed: () => _openBp(context),
                child: const Text('View history'),
              ),
            ],
          ),
        ] else ...[
          Text(
            '${measurement!.systolicMmHg} / ${measurement!.diastolicMmHg} mmHg',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Recorded ${_formatWhen(measurement!.recordedAt)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _openBp(context),
                child: const Text('View history'),
              ),
              TextButton(
                onPressed: () => _openBp(context),
                child: const Text('Add reading'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _openBp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BloodPressureHistoryScreen(),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: Colors.grey.shade700));
  }
}

String _formatWeight(double valueKg, UnitSystem units) {
  switch (units) {
    case UnitSystem.metric:
      return '${_trim(valueKg)} kg';
    case UnitSystem.imperial:
      return '${_trim(HealthUnits.kilogramsToPounds(valueKg))} lb';
  }
}

String _formatWhen(DateTime recordedAt) {
  final DateTime local = recordedAt.toLocal();
  final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String minute = local.minute.toString().padLeft(2, '0');
  final String suffix = local.hour >= 12 ? 'pm' : 'am';
  return '${local.day} ${_month(local.month)} ${local.year}, '
      '$hour12:$minute $suffix';
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
