import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/application/health_profile_providers.dart';
import '../../../health_profile/domain/health_profile.dart';
import '../../../health_profile/domain/health_units.dart';
import '../../application/measurements_providers.dart';
import '../../domain/weight_measurement.dart';

/// Neutral list of intentional weight recordings.
class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  'Could not load weight history.\n$error',
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
              onAdd: () =>
                  _openAddWeight(context, ref, profile.preferredUnits),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Text(
                  'Recorded weights. TARU stores what you enter — it does '
                  'not interpret your body.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                );
              }

              final WeightMeasurement item = items[index - 1];
              return _WeightTile(
                measurement: item,
                units: profile.preferredUnits,
                isLatest: index == 1,
                onDelete: () => _confirmDelete(context, ref, item),
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
    try {
      await ref.read(recordWeightProvider)(weightKg);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight tracking started.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start tracking: $error')),
      );
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

    try {
      await ref.read(deleteWeightMeasurementProvider)(measurement.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weight deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete weight: $error')),
      );
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.legacyWeightKg,
    required this.units,
    required this.onStartTracking,
    required this.onAdd,
  });

  final double? legacyWeightKg;
  final UnitSystem units;
  final VoidCallback? onStartTracking;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 48, color: Colors.grey.shade400),
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
              onPressed: onStartTracking,
              child: Text(
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
  bool _saving = false;

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
                'Records your current weight now.',
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
              const SizedBox(height: 20),
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final double entered = double.parse(_controller.text.trim());
    final double kg = switch (widget.units) {
      UnitSystem.metric => entered,
      UnitSystem.imperial => HealthUnits.poundsToKilograms(entered),
    };

    setState(() => _saving = true);
    try {
      await ref.read(recordWeightProvider)(kg);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save weight: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
