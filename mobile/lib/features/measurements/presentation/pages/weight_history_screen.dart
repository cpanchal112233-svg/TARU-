import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../health_profile/application/health_profile_providers.dart';
import '../../../health_profile/domain/health_profile.dart';
import '../../../health_profile/domain/health_units.dart';
import '../../application/measurements_providers.dart';
import '../../domain/measurement_chart_points.dart';
import '../../domain/weight_measurement.dart';
import '../widgets/raw_measurement_chart.dart';

/// Neutral list of intentional weight recordings.
class WeightHistoryScreen extends ConsumerStatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  ConsumerState<WeightHistoryScreen> createState() =>
      _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  bool _starting = false;
  final Set<String> _deleting = <String>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WeightMeasurement>> history = ref.watch(
      weightHistoryProvider,
    );
    final HealthProfile profile =
        ref.watch(healthProfileProvider).value ?? HealthProfile.empty;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Weight history'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddWeight(context, ref, profile.preferredUnits),
        icon: const Icon(Icons.add),
        label: const Text('Add weight'),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load weight history. ${userFacingErrorMessage(error)}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(weightHistoryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (List<WeightMeasurement> items) {
          if (items.isEmpty) {
            return _EmptyHistory(
              legacyWeightKg: profile.weightKg,
              units: profile.preferredUnits,
              onStartTracking: profile.weightKg == null
                  ? null
                  : () => _startTracking(context, ref, profile.weightKg!),
              starting: _starting,
              onAdd: () => _openAddWeight(context, ref, profile.preferredUnits),
            );
          }

          final List<MeasurementChartPoint> chartPoints = weightChartPoints(
            items,
          );
          final List<MeasurementChartPoint> displayPoints = chartPoints
              .map(
                (MeasurementChartPoint p) => MeasurementChartPoint(
                  recordedAt: p.recordedAt,
                  value: _displayValue(p.value, profile.preferredUnits),
                ),
              )
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: items.length + 2,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent history',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recorded weights. TARU stores what you enter — it does '
                      'not interpret your body.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (items.length >= 2) ...[
                      const SizedBox(height: 16),
                      RawMeasurementChart(
                        semanticsLabel:
                            'Recent weight chart. Exact values are listed below.',
                        series: [
                          RawChartSeries(
                            color: const Color(0xff1D4ED8),
                            points: displayPoints,
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }

              if (index == 1) {
                return Text(
                  'Exact values are listed below.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                );
              }

              final WeightMeasurement item = items[index - 2];
              return _WeightTile(
                measurement: item,
                units: profile.preferredUnits,
                isLatest: index == 2,
                onDelete: _deleting.contains(item.id)
                    ? null
                    : () => _confirmDelete(context, ref, item),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAddWeight(
    BuildContext context,
    WidgetRef ref,
    UnitSystem units,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: _AddWeightSheet(units: units),
        );
      },
    );
  }

  Future<void> _startTracking(
    BuildContext context,
    WidgetRef ref,
    double weightKg,
  ) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await ref.read(recordWeightProvider)(weightKg);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weight tracking started.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not start tracking. ${userFacingErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WeightMeasurement measurement,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete this weight?'),
        content: const Text(
          'This removes the recorded entry. You can add a new weight '
          'afterwards if you need to correct it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    if (_deleting.contains(measurement.id)) return;
    setState(() => _deleting.add(measurement.id));

    try {
      await ref.read(deleteWeightMeasurementProvider)(measurement.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weight deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete weight. ${userFacingErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting.remove(measurement.id));
      }
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.legacyWeightKg,
    required this.units,
    required this.onStartTracking,
    required this.onAdd,
    this.starting = false,
  });

  final double? legacyWeightKg;
  final UnitSystem units;
  final VoidCallback? onStartTracking;
  final VoidCallback onAdd;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No weight history yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'When you record a weight, TARU keeps a history. Existing Health '
            'Profile weights are not turned into history until you choose to '
            'start tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          if (legacyWeightKg != null && onStartTracking != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: starting ? null : onStartTracking,
              child: starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Start tracking with your current weight '
                      '(${_formatWeight(legacyWeightKg!, units)})',
                    ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(onPressed: onAdd, child: const Text('Add weight')),
        ],
      ),
    );
  }
}

class _WeightTile extends StatelessWidget {
  const _WeightTile({
    required this.measurement,
    required this.units,
    required this.isLatest,
    required this.onDelete,
  });

  final WeightMeasurement measurement;
  final UnitSystem units;
  final bool isLatest;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String when = _formatRecordedAt(measurement.recordedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWeight(measurement.valueKg, units),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLatest ? 'Latest · recorded $when' : 'Recorded $when',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _AddWeightSheet extends ConsumerStatefulWidget {
  const _AddWeightSheet({required this.units});

  final UnitSystem units;

  @override
  ConsumerState<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<_AddWeightSheet> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _recordedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _recordedAt = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add weight',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the weight and when it was measured.',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Weight (${widget.units.weightUnit})',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validate,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Measurement date & time'),
                subtitle: Text(_formatRecordedAt(_recordedAt)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validate(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a weight';
    final double? entered = double.tryParse(text);
    if (entered == null) return 'Enter a number';
    final double kg = switch (widget.units) {
      UnitSystem.metric => entered,
      UnitSystem.imperial => HealthUnits.poundsToKilograms(entered),
    };
    if (!isPlausibleWeightKg(kg)) {
      return 'Enter a weight in ${widget.units.weightUnit}';
    }
    return null;
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(now.year - 20),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final double entered = double.parse(_controller.text.trim());
    final double kg = switch (widget.units) {
      UnitSystem.metric => entered,
      UnitSystem.imperial => HealthUnits.poundsToKilograms(entered),
    };

    setState(() => _saving = true);
    try {
      await ref.read(recordWeightProvider)(kg, recordedAt: _recordedAt);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final String message = error is ArgumentError
          ? 'Check the values you entered and try again.'
          : 'Could not save weight. ${userFacingErrorMessage(error)}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

double _displayValue(double valueKg, UnitSystem units) {
  return switch (units) {
    UnitSystem.metric => valueKg,
    UnitSystem.imperial => HealthUnits.kilogramsToPounds(valueKg),
  };
}

String _formatWeight(double valueKg, UnitSystem units) {
  switch (units) {
    case UnitSystem.metric:
      return '${_trim(valueKg)} kg';
    case UnitSystem.imperial:
      return '${_trim(HealthUnits.kilogramsToPounds(valueKg))} lb';
  }
}

String _formatRecordedAt(DateTime recordedAt) {
  final DateTime local = recordedAt.toLocal();
  final String day = local.day.toString();
  final String month = _monthName(local.month);
  final String year = local.year.toString();
  final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String minute = local.minute.toString().padLeft(2, '0');
  final String suffix = local.hour >= 12 ? 'pm' : 'am';
  return '$day $month $year, $hour12:$minute $suffix';
}

String _monthName(int month) {
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

String _trim(double value) {
  final String fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
