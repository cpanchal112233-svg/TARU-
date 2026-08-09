import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/measurements_providers.dart';
import '../../domain/blood_pressure_measurement.dart';
import '../../domain/measurement_chart_points.dart';
import '../widgets/raw_measurement_chart.dart';

/// Dedicated blood-pressure history: add, recent raw chart, recent list.
class BloodPressureHistoryScreen extends ConsumerWidget {
  const BloodPressureHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BloodPressureMeasurement>> history = ref.watch(
      bloodPressureHistoryProvider,
    );

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Blood pressure'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add reading'),
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
                  'Could not load blood pressure history.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(bloodPressureHistoryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (List<BloodPressureMeasurement> items) {
          if (items.isEmpty) {
            return _EmptyHistory(onAdd: () => _openAdd(context, ref));
          }

          final BloodPressureChartSeries chart = bloodPressureChartSeries(items);

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
                      'Recorded readings only. TARU does not classify blood '
                      'pressure values.',
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
                            'Recent blood pressure chart with systolic and '
                            'diastolic series',
                        series: [
                          RawChartSeries(
                            label: 'Systolic',
                            color: const Color(0xff1D4ED8),
                            points: chart.systolic,
                          ),
                          RawChartSeries(
                            label: 'Diastolic',
                            color: const Color(0xff0F766E),
                            points: chart.diastolic,
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

              final BloodPressureMeasurement item = items[index - 2];
              return _BpTile(
                measurement: item,
                isLatest: index == 2,
                onDelete: () => _confirmDelete(context, ref, item),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, WidgetRef ref) async {
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
          child: const _AddBloodPressureSheet(),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BloodPressureMeasurement measurement,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete this reading?'),
        content: const Text(
          'This removes the recorded entry. You can add a new reading '
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

    try {
      await ref.read(deleteBloodPressureMeasurementProvider)(measurement.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood pressure reading deleted.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete reading: $error')),
      );
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No blood pressure readings recorded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'When you add a reading, TARU keeps systolic and diastolic values '
            'with the time you choose.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onAdd, child: const Text('Add reading')),
        ],
      ),
    );
  }
}

class _BpTile extends StatelessWidget {
  const _BpTile({
    required this.measurement,
    required this.isLatest,
    required this.onDelete,
  });

  final BloodPressureMeasurement measurement;
  final bool isLatest;
  final VoidCallback onDelete;

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
                  '${measurement.systolicMmHg} / ${measurement.diastolicMmHg} mmHg',
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

class _AddBloodPressureSheet extends ConsumerStatefulWidget {
  const _AddBloodPressureSheet();

  @override
  ConsumerState<_AddBloodPressureSheet> createState() =>
      _AddBloodPressureSheetState();
}

class _AddBloodPressureSheetState
    extends ConsumerState<_AddBloodPressureSheet> {
  final TextEditingController _systolic = TextEditingController();
  final TextEditingController _diastolic = TextEditingController();
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
    _systolic.dispose();
    _diastolic.dispose();
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
                'Add reading',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter systolic and diastolic values in mmHg.',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolic,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        // Digits only — do not truncate. Validation rejects >3 digits.
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Systolic',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (String? value) {
                        if (!isTechnicallyValidBpMmHgInput(value)) {
                          return 'Enter a valid systolic value.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _diastolic,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Diastolic',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (String? value) {
                        if (!isTechnicallyValidBpMmHgInput(value)) {
                          return 'Enter a valid diastolic value.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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

    setState(() => _saving = true);
    try {
      await ref.read(recordBloodPressureProvider)(
        systolicMmHg: int.parse(_systolic.text.trim()),
        diastolicMmHg: int.parse(_diastolic.text.trim()),
        recordedAt: _recordedAt,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final String message = error is ArgumentError && error.message != null
          ? error.message.toString()
          : 'Could not save reading: $error';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
