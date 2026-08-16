import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_profile/presentation/pages/allergies_screen.dart';
import '../../../health_profile/presentation/pages/conditions_screen.dart';
import '../../../health_profile/presentation/pages/medications_screen.dart';
import '../../../measurements/domain/blood_pressure_measurement.dart';
import '../../../measurements/domain/weight_measurement.dart';
import '../../../measurements/presentation/pages/blood_pressure_history_screen.dart';
import '../../../measurements/presentation/pages/weight_history_screen.dart';
import '../../../progress/presentation/pages/progress_screen.dart';
import '../../../reports/presentation/pages/report_detail_screen.dart';
import '../../../reports/presentation/widgets/report_widgets.dart';
import '../../../routine/domain/dose_schedule.dart';
import '../../../routine/domain/habit.dart';
import '../../../routine/presentation/pages/routine_screen.dart';
import '../../application/evidence_brief_providers.dart';
import '../../domain/evidence_brief.dart';
import '../../domain/evidence_brief_period.dart';
import '../../domain/evidence_brief_provenance.dart';
import '../../domain/evidence_brief_section_load.dart';
import '../../domain/evidence_brief_sections.dart';
import '../widgets/evidence_brief_section_card.dart';
import 'evidence_brief_share_preview_screen.dart';

/// Factual "what I recorded" brief for a chosen period.
class EvidenceBriefScreen extends ConsumerStatefulWidget {
  const EvidenceBriefScreen({super.key});

  @override
  ConsumerState<EvidenceBriefScreen> createState() =>
      _EvidenceBriefScreenState();
}

class _EvidenceBriefScreenState extends ConsumerState<EvidenceBriefScreen> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: ref.read(evidenceBriefNotesProvider),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final EvidenceBriefPeriod current = ref.read(evidenceBriefPeriodProvider);
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 10);
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(start: current.start, end: current.end),
      helpText: 'Custom Evidence Brief range',
      saveText: 'Apply',
    );
    if (range == null || !mounted) return;
    final EvidenceBriefPeriod? period = EvidenceBriefPeriod.tryCustom(
      start: range.start,
      end: range.end,
    );
    if (period == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a start date on or before the end date.'),
        ),
      );
      return;
    }
    ref.read(evidenceBriefPeriodProvider.notifier).setPeriod(period);
  }

  void _selectPreset(EvidenceBriefPeriodPreset preset) {
    final int days = switch (preset) {
      EvidenceBriefPeriodPreset.last7 => 7,
      EvidenceBriefPeriodPreset.last30 => 30,
      EvidenceBriefPeriodPreset.last90 => 90,
      EvidenceBriefPeriodPreset.custom => 7,
    };
    if (preset == EvidenceBriefPeriodPreset.custom) {
      _pickCustomRange();
      return;
    }
    ref
        .read(evidenceBriefPeriodProvider.notifier)
        .setPeriod(EvidenceBriefPeriod.lastDays(days));
  }

  void _openSharePreview() {
    final bool canShare = ref.read(evidenceBriefCanShareProvider);
    if (!canShare) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Turn off any section that could not load before sharing.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EvidenceBriefSharePreviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EvidenceBrief brief = ref.watch(evidenceBriefProvider);
    final EvidenceBriefPeriod period = ref.watch(evidenceBriefPeriodProvider);
    final EvidenceBriefShareSelection selection = ref.watch(
      evidenceBriefShareSelectionProvider,
    );
    final bool canShare = ref.watch(evidenceBriefCanShareProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Evidence Brief'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: 'Open Share Preview',
            child: IconButton(
              onPressed: canShare ? _openSharePreview : null,
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Share Preview',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A factual summary of information you have recorded in '
              'TARU. Not a certified medical record.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 18),
            EvidenceBriefPeriodPicker(
              period: period,
              onPresetSelected: _selectPreset,
              onCustomPressed: _pickCustomRange,
            ),
            const SizedBox(height: 16),
            _SourcesSummaryCard(brief: brief),
            if (brief.hasNoPeriodEvidence) ...[
              const SizedBox(height: 14),
              _EmptyPeriodBanner(
                hasContext:
                    brief.contextLoad.isShareable && brief.context.hasAnyAnswer,
              ),
            ],
            const SizedBox(height: 20),
            _ChooseWhatToInclude(
              brief: brief,
              selection: selection,
              onChanged: (EvidenceBriefSectionId id, bool value) {
                ref
                    .read(evidenceBriefShareSelectionProvider.notifier)
                    .setSection(id, value);
              },
              onRetry: (EvidenceBriefSectionId id) {
                retryEvidenceBriefSection(ref, id);
              },
            ),
            const SizedBox(height: 20),
            _SectionLoadGate(
              load: brief.contextLoad,
              title: 'Current self-reported context',
              failedMessage: "Couldn't load current health context.",
              onRetry: () => retryEvidenceBriefSection(
                ref,
                EvidenceBriefSectionId.currentContext,
              ),
              child: _ContextSection(section: brief.context),
            ),
            const SizedBox(height: 14),
            _SectionLoadGate(
              load: brief.measurementsLoad,
              title: 'Measurements',
              failedMessage: "Couldn't load measurements.",
              onRetry: () => retryEvidenceBriefSection(
                ref,
                EvidenceBriefSectionId.measurements,
              ),
              child: _MeasurementsSection(section: brief.measurements),
            ),
            const SizedBox(height: 14),
            _SectionLoadGate(
              load: brief.reportsLoad,
              title: 'Reports',
              failedMessage: "Couldn't load reports.",
              onRetry: () => retryEvidenceBriefSection(
                ref,
                EvidenceBriefSectionId.reports,
              ),
              child: _ReportsSection(section: brief.reports),
            ),
            const SizedBox(height: 14),
            _SectionLoadGate(
              load: brief.medicineLoad,
              title: 'Medicine routine',
              failedMessage: "Couldn't load medicine routine.",
              onRetry: () => retryEvidenceBriefSection(
                ref,
                EvidenceBriefSectionId.medicineRoutine,
              ),
              child: _MedicineRoutineSection(section: brief.routine),
            ),
            const SizedBox(height: 14),
            _SectionLoadGate(
              load: brief.lifestyleLoad,
              title: 'Lifestyle routine',
              failedMessage: "Couldn't load lifestyle routine.",
              onRetry: () => retryEvidenceBriefSection(
                ref,
                EvidenceBriefSectionId.lifestyleRoutine,
              ),
              child: _LifestyleRoutineSection(section: brief.routine),
            ),
            const SizedBox(height: 14),
            _NotesSection(
              controller: _notesController,
              onChanged: (String value) {
                ref.read(evidenceBriefNotesProvider.notifier).setNotes(value);
              },
            ),
            if (!canShare) ...[
              const SizedBox(height: 12),
              Text(
                'Sharing is paused while an included section is still loading '
                'or could not load. Turn that section off, or retry it.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Review Share Preview before sharing',
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: FilledButton.icon(
                    onPressed: canShare ? _openSharePreview : null,
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text(
                      'Review & share',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcesSummaryCard extends StatelessWidget {
  const _SourcesSummaryCard({required this.brief});

  final EvidenceBrief brief;

  @override
  Widget build(BuildContext context) {
    final EvidenceBriefSourcesSummary summary = brief.sourcesSummary;
    return Semantics(
      container: true,
      label: 'Sources in this brief',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Sources in this brief',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final String line in summary.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· $line',
                  style: TextStyle(height: 1.35, color: Colors.grey.shade800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPeriodBanner extends StatelessWidget {
  const _EmptyPeriodBanner({required this.hasContext});

  final bool hasContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        hasContext
            ? 'No measurements, reports, or routine records were found in '
                  'this period. Current self-reported context is still shown '
                  'separately. You can change the period above.'
            : 'No measurements, reports, or routine records were found in '
                  'this period. You can change the period above.',
        style: TextStyle(
          fontSize: 13.5,
          height: 1.4,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _SectionLoadGate extends StatelessWidget {
  const _SectionLoadGate({
    required this.load,
    required this.title,
    required this.failedMessage,
    required this.onRetry,
    required this.child,
  });

  final EvidenceBriefSectionLoad load;
  final String title;
  final String failedMessage;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (load.isLoading) {
      return EvidenceBriefSectionCard(
        title: title,
        provenance: EvidenceProvenance.selfReported,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (load.isFailed) {
      return EvidenceBriefSectionCard(
        title: title,
        provenance: EvidenceProvenance.selfReported,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              failedMessage,
              style: TextStyle(height: 1.4, color: Colors.grey.shade900),
            ),
            const SizedBox(height: 8),
            Text(
              'This section cannot be included until it loads successfully.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            Semantics(
              button: true,
              label: 'Retry $title',
              child: TextButton(onPressed: onRetry, child: const Text('Retry')),
            ),
          ],
        ),
      );
    }
    return child;
  }
}

class _ChooseWhatToInclude extends StatelessWidget {
  const _ChooseWhatToInclude({
    required this.brief,
    required this.selection,
    required this.onChanged,
    required this.onRetry,
  });

  final EvidenceBrief brief;
  final EvidenceBriefShareSelection selection;
  final void Function(EvidenceBriefSectionId id, bool value) onChanged;
  final void Function(EvidenceBriefSectionId id) onRetry;

  @override
  Widget build(BuildContext context) {
    final List<_SectionToggleSpec> specs = <_SectionToggleSpec>[
      _SectionToggleSpec(
        id: EvidenceBriefSectionId.currentContext,
        load: brief.contextLoad,
        emptyReason: 'No current health context recorded yet.',
      ),
      _SectionToggleSpec(
        id: EvidenceBriefSectionId.measurements,
        load: brief.measurementsLoad,
        emptyReason: 'No measurements in this period.',
      ),
      _SectionToggleSpec(
        id: EvidenceBriefSectionId.reports,
        load: brief.reportsLoad,
        emptyReason: 'No reports in this period.',
      ),
      _SectionToggleSpec(
        id: EvidenceBriefSectionId.medicineRoutine,
        load: brief.medicineLoad,
        emptyReason: 'No medicine routine content for this period.',
      ),
      _SectionToggleSpec(
        id: EvidenceBriefSectionId.lifestyleRoutine,
        load: brief.lifestyleLoad,
        emptyReason: 'No lifestyle routine content for this period.',
      ),
      _SectionToggleSpec(
        id: EvidenceBriefSectionId.notes,
        load: const EvidenceBriefSectionLoad.ready(),
        emptyReason: null,
      ),
    ];

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Choose what to include',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Applies to Share Preview and sharing.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              for (final _SectionToggleSpec spec in specs) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(spec.id.label),
                  subtitle: Text(spec.subtitle),
                  value: spec.load.isShareable && selection.includes(spec.id),
                  onChanged: spec.load.isShareable
                      ? (bool value) => onChanged(spec.id, value)
                      : null,
                ),
                if (spec.load.isFailed)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      button: true,
                      label: 'Retry ${spec.id.label}',
                      child: TextButton(
                        onPressed: () => onRetry(spec.id),
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionToggleSpec {
  const _SectionToggleSpec({
    required this.id,
    required this.load,
    required this.emptyReason,
  });

  final EvidenceBriefSectionId id;
  final EvidenceBriefSectionLoad load;
  final String? emptyReason;

  String get subtitle {
    if (load.isFailed) {
      return "Couldn't load — turn off or retry before sharing.";
    }
    if (load.isLoading) {
      return 'Still loading…';
    }
    if (load.isEmpty && emptyReason != null) {
      return emptyReason!;
    }
    return 'Included when switched on.';
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({required this.section});

  final EvidenceBriefContextSection section;

  @override
  Widget build(BuildContext context) {
    return EvidenceBriefSectionCard(
      title: 'Current self-reported context',
      provenance: EvidenceProvenance.selfReported,
      semanticsIdentifier: 'evidence_brief_context',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.asOfLabel,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is a current snapshot — not evidence that these values were '
            'true throughout the selected period.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          _ContextGroup(
            title: 'Conditions',
            emptyLabel: !section.conditionsAnswered
                ? 'Not recorded'
                : section.noKnownConditions
                ? 'None reported'
                : 'None listed',
            items: section.conditions,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ConditionsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ContextGroup(
            title: 'Allergies',
            emptyLabel: !section.allergiesAnswered
                ? 'Not recorded'
                : section.noKnownAllergies
                ? 'No known allergies'
                : 'None listed',
            items: section.allergies,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AllergiesScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _ContextGroup(
            title: 'Current medicines',
            emptyLabel: !section.medicinesAnswered
                ? 'Not recorded'
                : section.takesNoMedication
                ? 'None'
                : 'None listed',
            items: section.medicines,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MedicationsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextGroup extends StatelessWidget {
  const _ContextGroup({
    required this.title,
    required this.emptyLabel,
    required this.items,
    required this.onOpen,
  });

  final String title;
  final String emptyLabel;
  final List<EvidenceBriefContextItem> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Semantics(
              button: true,
              label: 'Open $title source',
              child: TextButton(onPressed: onOpen, child: const Text('Open')),
            ),
          ],
        ),
        if (items.isEmpty)
          Text(emptyLabel, style: TextStyle(color: Colors.grey.shade700))
        else
          for (final EvidenceBriefContextItem item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (item.detail != null)
                    Text(
                      item.detail!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  Text(
                    '${EvidenceProvenance.selfReported.label} · '
                    'Current as of today',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _MeasurementsSection extends StatelessWidget {
  const _MeasurementsSection({required this.section});

  final EvidenceBriefMeasurementsSection section;

  @override
  Widget build(BuildContext context) {
    return EvidenceBriefSectionCard(
      title: 'Measurements',
      provenance: EvidenceProvenance.manualMeasurement,
      semanticsIdentifier: 'evidence_brief_measurements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.isEmpty)
            Text(
              'No weight or blood pressure recorded in this period.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else ...[
            Text(
              '${section.count} manual '
              '${section.count == 1 ? 'measurement' : 'measurements'} '
              'in this period',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            if (section.weights.isNotEmpty) ...[
              Text(
                'Weight (${section.weights.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _ExpandableMeasurementList(
                itemCount: section.weights.length,
                itemBuilder: (int index) {
                  final WeightMeasurement m = section.weights[index];
                  return _LinkRow(
                    title:
                        '${m.valueKg.toStringAsFixed(1)} kg · '
                        '${formatReportDate(m.recordedAt)}',
                    subtitle:
                        '${EvidenceProvenance.manualMeasurement.label}\n'
                        'Recorded ${formatReportDate(m.recordedAt)}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WeightHistoryScreen(),
                      ),
                    ),
                    semanticsLabel:
                        'Weight ${m.valueKg.toStringAsFixed(1)} kilograms, '
                        'open weight history',
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (section.bloodPressures.isNotEmpty) ...[
              Text(
                'Blood pressure (${section.bloodPressures.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _ExpandableMeasurementList(
                itemCount: section.bloodPressures.length,
                itemBuilder: (int index) {
                  final BloodPressureMeasurement m =
                      section.bloodPressures[index];
                  return _LinkRow(
                    title:
                        '${m.systolicMmHg}/${m.diastolicMmHg} mmHg · '
                        '${formatReportDate(m.recordedAt)}',
                    subtitle:
                        '${EvidenceProvenance.manualMeasurement.label}\n'
                        'Recorded ${formatReportDate(m.recordedAt)}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BloodPressureHistoryScreen(),
                      ),
                    ),
                    semanticsLabel:
                        'Blood pressure ${m.systolicMmHg} over '
                        '${m.diastolicMmHg}, open blood pressure history',
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExpandableMeasurementList extends StatefulWidget {
  const _ExpandableMeasurementList({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  State<_ExpandableMeasurementList> createState() =>
      _ExpandableMeasurementListState();
}

class _ExpandableMeasurementListState
    extends State<_ExpandableMeasurementList> {
  static const int _collapsedCount = 8;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bool needsExpand = widget.itemCount > _collapsedCount;
    final int visible = !_expanded && needsExpand
        ? _collapsedCount
        : widget.itemCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < visible; i++) widget.itemBuilder(i),
        if (needsExpand)
          Semantics(
            button: true,
            label: _expanded
                ? 'Show fewer measurements'
                : 'Show all ${widget.itemCount} measurements',
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show fewer' : 'Show all ${widget.itemCount}',
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({required this.section});

  final EvidenceBriefReportsSection section;

  @override
  Widget build(BuildContext context) {
    return EvidenceBriefSectionCard(
      title: 'Reports',
      provenance: EvidenceProvenance.reportRecord,
      semanticsIdentifier: 'evidence_brief_reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.isEmpty)
            Text(
              'No reports in this period.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            for (final EvidenceBriefReportItem item in section.reports)
              _LinkRow(
                title: item.report.title,
                subtitle:
                    '${item.report.category.label} · '
                    '${item.dateBasisLabel} · '
                    '${EvidenceProvenance.reportRecord.label}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReportDetailScreen(report: item.report),
                  ),
                ),
                semanticsLabel:
                    'Report ${item.report.title}, open report detail',
              ),
        ],
      ),
    );
  }
}

class _MedicineRoutineSection extends StatelessWidget {
  const _MedicineRoutineSection({required this.section});

  final EvidenceBriefRoutineSection section;

  @override
  Widget build(BuildContext context) {
    return EvidenceBriefSectionCard(
      title: 'Medicine routine',
      provenance: EvidenceProvenance.routineLog,
      semanticsIdentifier: 'evidence_brief_medicine_routine',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _medicineLine(section),
            style: TextStyle(height: 1.4, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 10),
          for (final String caveat in section.caveats.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                caveat,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          Semantics(
            button: true,
            label: 'Open Routine source',
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RoutineScreen()),
              ),
              child: const Text('Open Routine'),
            ),
          ),
        ],
      ),
    );
  }

  String _medicineLine(EvidenceBriefRoutineSection section) {
    if (section.noMedicinesConfigured) {
      return 'None configured.';
    }
    final AdherenceSummary? medicine = section.medicine;
    if (medicine == null || !medicine.hasData) {
      return 'No dose logs in this period.';
    }
    return '${medicine.taken} of about ${medicine.expected} expected doses '
        'logged as taken (from ${medicine.daysCovered} '
        '${medicine.daysCovered == 1 ? 'day' : 'days'} of tracking).';
  }
}

class _LifestyleRoutineSection extends StatelessWidget {
  const _LifestyleRoutineSection({required this.section});

  final EvidenceBriefRoutineSection section;

  @override
  Widget build(BuildContext context) {
    return EvidenceBriefSectionCard(
      title: 'Lifestyle routine',
      provenance: EvidenceProvenance.routineLog,
      semanticsIdentifier: 'evidence_brief_lifestyle_routine',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _lifestyleLine(section),
            style: TextStyle(height: 1.4, color: Colors.grey.shade900),
          ),
          if (section.lifestyle != null &&
              section.lifestyle!.hasData &&
              section.lifestyle!.byPillar.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final HabitPillarWeekStat pillar
                in section.lifestyle!.byPillar)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${pillar.pillar.label}: ${pillar.done}/${pillar.possible}',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            'Medicine and lifestyle are separate — there is no combined score.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          Semantics(
            button: true,
            label: 'Open Progress source',
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProgressScreen()),
              ),
              child: const Text('Open Progress'),
            ),
          ),
        ],
      ),
    );
  }

  String _lifestyleLine(EvidenceBriefRoutineSection section) {
    if (section.noActiveHabits) {
      return 'No enabled habits.';
    }
    final HabitAdherenceSummary? lifestyle = section.lifestyle;
    if (lifestyle == null || !lifestyle.hasData) {
      return 'No habit logs in this period.';
    }
    return '${lifestyle.done} of ${lifestyle.possible} enabled habit ticks '
        'logged as done across ${lifestyle.daysCovered} '
        '${lifestyle.daysCovered == 1 ? 'day' : 'days'} with a record.';
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return EvidenceBriefSectionCard(
      title: 'Notes / questions',
      provenance: EvidenceProvenance.selfReported,
      semanticsIdentifier: 'evidence_brief_notes',
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          alignLabelWithHint: true,
          labelText: 'Optional questions or notes for this share',
          hintText: 'These notes stay on this device until you leave.',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.semanticsLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
