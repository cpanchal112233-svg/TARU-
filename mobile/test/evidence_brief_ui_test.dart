import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/evidence_brief/application/evidence_brief_providers.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_period.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_provenance.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_section_load.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_sections.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_text.dart';
import 'package:mobile/features/evidence_brief/presentation/pages/evidence_brief_screen.dart';
import 'package:mobile/features/evidence_brief/presentation/pages/evidence_brief_share_preview_screen.dart';
import 'package:mobile/features/evidence_brief/presentation/widgets/evidence_brief_section_card.dart';
import 'package:mobile/features/health_profile/application/health_profile_providers.dart';
import 'package:mobile/features/health_profile/domain/health_profile.dart';
import 'package:mobile/features/measurements/application/measurements_providers.dart';
import 'package:mobile/features/measurements/domain/blood_pressure_measurement.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';
import 'package:mobile/features/reports/application/reports_providers.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';
import 'package:mobile/features/reports/presentation/pages/report_detail_screen.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:share_plus/share_plus.dart';

EvidenceBrief _sampleBrief({String notes = ''}) {
  final DateTime now = DateTime(2026, 8, 16);
  final EvidenceBriefPeriod period = EvidenceBriefPeriod.lastDays(7, now: now);
  return EvidenceBrief(
    period: period,
    context: EvidenceBriefContextSection(
      conditions: const <EvidenceBriefContextItem>[
        EvidenceBriefContextItem(label: 'Hypertension', detail: null),
      ],
      allergies: const <EvidenceBriefContextItem>[],
      medicines: const <EvidenceBriefContextItem>[
        EvidenceBriefContextItem(label: 'Amlodipine', detail: '5 mg'),
      ],
      conditionsAnswered: true,
      allergiesAnswered: true,
      medicinesAnswered: true,
      noKnownConditions: false,
      noKnownAllergies: true,
      takesNoMedication: false,
      asOf: now,
    ),
    measurements: EvidenceBriefMeasurementsSection(
      weights: <WeightMeasurement>[
        WeightMeasurement(
          id: 'w1',
          valueKg: 72,
          recordedAt: DateTime(2026, 8, 14),
        ),
      ],
      bloodPressures: <BloodPressureMeasurement>[
        BloodPressureMeasurement(
          id: 'bp1',
          systolicMmHg: 122,
          diastolicMmHg: 78,
          recordedAt: DateTime(2026, 8, 15),
        ),
      ],
    ),
    reports: EvidenceBriefReportsSection(
      reports: <EvidenceBriefReportItem>[
        EvidenceBriefReportItem(
          report: MedicalReport(
            id: 'r1',
            title: 'Lipid panel',
            category: ReportCategory.lab,
            fileName: 'lipids.pdf',
            mimeType: 'application/pdf',
            storagePath: 'users/u/reports/r1/lipids.pdf',
            sizeBytes: 100,
            uploadedAt: DateTime(2026, 8, 13),
            notes: 'hemoglobin 14.2 must not appear',
          ),
        ),
      ],
    ),
    routine: const EvidenceBriefRoutineSection(
      medicine: AdherenceSummary(taken: 5, expected: 7, daysCovered: 7),
      lifestyle: null,
      noMedicinesConfigured: false,
      noActiveHabits: true,
      caveats: <String>[
        'Medicine expected doses use your current medicine schedule, not a '
            'historical prescription record.',
        'Routine figures are self-reported logs, not a clinical adherence score.',
        'Medicine and lifestyle are separate — there is no combined score.',
      ],
    ),
    notes: notes,
    createdAt: now,
  );
}

void main() {
  testWidgets('renders sections, provenance, period controls, and share', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evidenceBriefProvider.overrideWithValue(_sampleBrief()),
          evidenceBriefPeriodProvider.overrideWith(
            EvidenceBriefPeriodController.new,
          ),
        ],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    expect(find.text('Evidence Brief'), findsWidgets);
    expect(find.text('Current self-reported context'), findsOneWidget);
    expect(find.textContaining('as of'), findsWidgets);
    expect(find.text('Measurements'), findsWidgets);
    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Medicine routine'), findsWidgets);
    expect(find.text('Lifestyle routine'), findsWidgets);
    expect(find.text('Notes / questions'), findsOneWidget);
    expect(find.text('Sources in this brief'), findsOneWidget);
    expect(find.text('Choose what to include'), findsOneWidget);
    expect(find.text(EvidenceProvenance.selfReported.label), findsWidgets);
    expect(find.text(EvidenceProvenance.manualMeasurement.label), findsWidgets);
    expect(
      find.textContaining(EvidenceProvenance.reportRecord.label),
      findsWidgets,
    );
    expect(find.text(EvidenceProvenance.routineLog.label), findsWidgets);
    expect(find.text('Last 7 days'), findsWidgets);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('Last 90 days'), findsOneWidget);
    expect(find.text('Custom range'), findsOneWidget);
    expect(find.text('Review & share'), findsOneWidget);
    expect(find.text('Hypertension'), findsOneWidget);
    expect(find.text('Lipid panel'), findsOneWidget);
    expect(find.textContaining('no combined score'), findsWidgets);
    expect(find.textContaining('current medicine schedule'), findsOneWidget);
    expect(find.textContaining('hemoglobin'), findsNothing);

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('notes field is ephemeral and labeled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [evidenceBriefProvider.overrideWithValue(_sampleBrief())],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Question for my clinician');
    await tester.pump();
    expect(find.text('Question for my clinician'), findsOneWidget);
    expect(
      find.text('Optional questions or notes for this share'),
      findsOneWidget,
    );
  });

  testWidgets('200% text scale keeps core controls', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [evidenceBriefProvider.overrideWithValue(_sampleBrief())],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const MaterialApp(home: EvidenceBriefScreen()),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Review & share'), findsOneWidget);
    expect(find.text('Last 7 days'), findsWidgets);
    expect(find.byType(EvidenceBriefSectionCard), findsWidgets);
    await tester.ensureVisible(find.text('Review & share'));
    expect(tester.getRect(find.text('Review & share')).height, greaterThan(0));
  });

  testWidgets('section headers expose semantics headers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [evidenceBriefProvider.overrideWithValue(_sampleBrief())],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Period')),
      matchesSemantics(isHeader: true, label: 'Period'),
    );
    final SemanticsNode contextHeader = tester.getSemantics(
      find.text('Current self-reported context'),
    );
    expect(contextHeader.flagsCollection.isHeader, isTrue);
    expect(
      tester
          .getSemantics(find.text('Choose what to include'))
          .flagsCollection
          .isHeader,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('measurement and report rows expose source navigation', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evidenceBriefProvider.overrideWithValue(_sampleBrief()),
          weightHistoryProvider.overrideWith(
            (Ref ref) => Stream<List<WeightMeasurement>>.value(
              const <WeightMeasurement>[],
            ),
          ),
          healthProfileProvider.overrideWith(
            (Ref ref) => Stream<HealthProfile>.value(HealthProfile.empty),
          ),
          reportsProvider.overrideWith(
            (Ref ref) =>
                Stream<List<MedicalReport>>.value(const <MedicalReport>[]),
          ),
          reportDownloadUrlProvider.overrideWith(
            (Ref ref, MedicalReport report) async =>
                'https://example.test/file',
          ),
          reportExtractionProvider.overrideWith(
            (Ref ref, String id) => Stream<ReportExtraction?>.value(null),
          ),
        ],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    final Finder weightRow = find.textContaining('72.0 kg');
    await tester.ensureVisible(weightRow);
    await tester.tap(weightRow);
    await tester.pumpAndSettle();
    expect(find.text('Weight history'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final Finder reportRow = find.text('Lipid panel');
    await tester.ensureVisible(reportRow);
    await tester.tap(reportRow);
    await tester.pumpAndSettle();
    expect(find.byType(ReportDetailScreen), findsOneWidget);
  });

  testWidgets('share preview uses canonical text and share invoker', (
    WidgetTester tester,
  ) async {
    String? sharedText;
    final EvidenceBrief brief = _sampleBrief(notes: 'Bring questions');

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evidenceBriefProvider.overrideWithValue(brief),
          evidenceBriefShareSelectionProvider.overrideWith(
            EvidenceBriefShareSelectionController.new,
          ),
          evidenceBriefShareInvokerProvider.overrideWithValue((
            String text,
          ) async {
            sharedText = text;
            return ShareResultStatus.success;
          }),
        ],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    // Align selection with defaults for this brief.
    final EvidenceBriefShareSelection defaults =
        EvidenceBriefShareSelection.defaultsFor(brief);
    final String expected = formatEvidenceBriefText(brief, selection: defaults);

    await tester.ensureVisible(find.text('Review & share'));
    await tester.tap(find.text('Review & share'));
    await tester.pumpAndSettle();

    expect(find.byType(EvidenceBriefSharePreviewScreen), findsOneWidget);
    expect(find.textContaining('TARU Evidence Brief'), findsOneWidget);
    expect(find.textContaining('Bring questions'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(sharedText, isNotNull);
    expect(sharedText, expected);
  });

  testWidgets('deselecting reports removes them from preview text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final EvidenceBrief brief = _sampleBrief();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          evidenceBriefProvider.overrideWithValue(brief),
          evidenceBriefShareSelectionProvider.overrideWith(
            EvidenceBriefShareSelectionController.new,
          ),
        ],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    // Wait for selection listener to apply defaults, then deselect Reports.
    await tester.pump();
    final Finder reportsSwitch = find.widgetWithText(SwitchListTile, 'Reports');
    await tester.ensureVisible(reportsSwitch);
    await tester.tap(reportsSwitch);
    await tester.pump();

    await tester.ensureVisible(find.text('Review & share'));
    await tester.tap(find.text('Review & share'));
    await tester.pumpAndSettle();

    expect(find.textContaining('REPORTS'), findsNothing);
    expect(find.textContaining('Lipid panel'), findsNothing);
    expect(find.textContaining('MEASUREMENTS'), findsOneWidget);
  });

  testWidgets('failure state blocks sharing and stays honest', (
    WidgetTester tester,
  ) async {
    final EvidenceBrief failed = EvidenceBrief(
      period: EvidenceBriefPeriod.lastDays(7, now: DateTime(2026, 8, 16)),
      context: EvidenceBriefContextSection(
        conditions: const <EvidenceBriefContextItem>[],
        allergies: const <EvidenceBriefContextItem>[],
        medicines: const <EvidenceBriefContextItem>[],
        conditionsAnswered: false,
        allergiesAnswered: false,
        medicinesAnswered: false,
        noKnownConditions: false,
        noKnownAllergies: false,
        takesNoMedication: false,
        asOf: DateTime(2026, 8, 16),
      ),
      measurements: const EvidenceBriefMeasurementsSection(
        weights: <WeightMeasurement>[],
        bloodPressures: <BloodPressureMeasurement>[],
      ),
      reports: const EvidenceBriefReportsSection(
        reports: <EvidenceBriefReportItem>[],
      ),
      routine: const EvidenceBriefRoutineSection(
        medicine: null,
        lifestyle: null,
        noMedicinesConfigured: false,
        noActiveHabits: false,
        caveats: <String>[],
      ),
      measurementsLoad: EvidenceBriefSectionLoad.failed(
        StateError('measurements unavailable'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [evidenceBriefProvider.overrideWithValue(failed)],
        child: const MaterialApp(home: EvidenceBriefScreen()),
      ),
    );

    expect(find.textContaining("Couldn't load measurements"), findsOneWidget);
    expect(find.text('Retry'), findsWidgets);
    expect(find.textContaining('could not load'), findsWidgets);
    expect(find.text('Review & share'), findsOneWidget);
  });

  testWidgets('Home Evidence Brief entry copy is present in dedicated card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            button: true,
            label:
                'Evidence Brief. Create a factual summary from information '
                'you have recorded. Create brief',
            child: Column(
              children: const [
                Text('Evidence Brief'),
                Text(
                  "Create a factual summary from information you've recorded.",
                ),
                Text('Create brief'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Evidence Brief'), findsOneWidget);
    expect(find.textContaining('factual summary'), findsOneWidget);
    expect(find.text('Create brief'), findsOneWidget);
  });
}
