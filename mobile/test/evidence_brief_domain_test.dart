import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_period.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_provenance.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_section_load.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_sections.dart';
import 'package:mobile/features/evidence_brief/domain/evidence_brief_text.dart';
import 'package:mobile/features/measurements/domain/blood_pressure_measurement.dart';
import 'package:mobile/features/measurements/domain/weight_measurement.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:mobile/features/routine/domain/habit.dart';

void main() {
  final DateTime now = DateTime(2026, 8, 16, 12);
  final DateTime asOf = DateTime(2026, 8, 16);

  group('EvidenceBriefPeriod', () {
    test('last 7 includes today and exact 7-day boundary', () {
      final EvidenceBriefPeriod seven = EvidenceBriefPeriod.lastDays(
        7,
        now: now,
      );
      expect(seven.dayCount, 7);
      expect(seven.start, DateTime(2026, 8, 10));
      expect(seven.end, DateTime(2026, 8, 16));
      expect(seven.containsDateKey('2026-08-16'), isTrue);
      expect(seven.containsDateKey('2026-08-10'), isTrue);
      expect(seven.containsDateKey('2026-08-09'), isFalse);
      expect(seven.containsInstant(DateTime(2026, 8, 16, 23, 59)), isTrue);
    });

    test('last 30 and last 90 include today', () {
      final EvidenceBriefPeriod thirty = EvidenceBriefPeriod.lastDays(
        30,
        now: now,
      );
      final EvidenceBriefPeriod ninety = EvidenceBriefPeriod.lastDays(
        90,
        now: now,
      );
      expect(thirty.dayCount, 30);
      expect(ninety.dayCount, 90);
      expect(thirty.end, DateTime(2026, 8, 16));
      expect(ninety.end, DateTime(2026, 8, 16));
      expect(thirty.start, DateTime(2026, 7, 18));
      expect(ninety.start, DateTime(2026, 5, 19));
    });

    test('custom inclusive start/end keeps full end day', () {
      final EvidenceBriefPeriod period = EvidenceBriefPeriod.custom(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 16),
      );
      expect(period.dayCount, 16);
      expect(period.containsInstant(DateTime(2026, 8, 16, 23, 30)), isTrue);
      expect(period.containsInstant(DateTime(2026, 8, 1, 0, 1)), isTrue);
      expect(period.containsInstant(DateTime(2026, 7, 31, 23, 59)), isFalse);
    });

    test('invalid custom range is rejected', () {
      expect(
        EvidenceBriefPeriod.tryCustom(
          start: DateTime(2026, 8, 20),
          end: DateTime(2026, 8, 10),
        ),
        isNull,
      );
      expect(
        () => EvidenceBriefPeriod.custom(
          start: DateTime(2026, 8, 20),
          end: DateTime(2026, 8, 10),
        ),
        throwsArgumentError,
      );
    });
  });

  group('period filtering', () {
    final EvidenceBriefPeriod period = EvidenceBriefPeriod.lastDays(
      7,
      now: now,
    );

    test('includes weight and BP by recorded calendar day', () {
      final List<WeightMeasurement> weights = <WeightMeasurement>[
        WeightMeasurement(
          id: 'w1',
          valueKg: 70,
          recordedAt: DateTime(2026, 8, 12, 8),
        ),
        WeightMeasurement(
          id: 'w2',
          valueKg: 71,
          recordedAt: DateTime(2026, 8, 1, 8),
        ),
      ];
      final List<BloodPressureMeasurement> bps = <BloodPressureMeasurement>[
        BloodPressureMeasurement(
          id: 'bp1',
          systolicMmHg: 120,
          diastolicMmHg: 80,
          recordedAt: DateTime(2026, 8, 15, 9),
        ),
        BloodPressureMeasurement(
          id: 'bp2',
          systolicMmHg: 118,
          diastolicMmHg: 76,
          recordedAt: DateTime(2026, 7, 1, 9),
        ),
      ];

      expect(weightsInPeriod(weights, period).map((e) => e.id), <String>['w1']);
      expect(bloodPressuresInPeriod(bps, period).map((e) => e.id), <String>[
        'bp1',
      ]);
    });

    test('does not silently drop beyond a UI history cap of 50', () {
      final List<WeightMeasurement> many = List<WeightMeasurement>.generate(
        60,
        (int i) => WeightMeasurement(
          id: 'w$i',
          valueKg: 70 + i * 0.1,
          recordedAt: DateTime(2026, 8, 12).add(Duration(minutes: i)),
        ),
      );
      expect(weightsInPeriod(many, period), hasLength(60));
    });
  });

  group('report date basis', () {
    final EvidenceBriefPeriod period = EvidenceBriefPeriod.lastDays(
      7,
      now: now,
    );

    test('takenOn inside / uploadedAt outside → include on takenOn', () {
      final MedicalReport report = MedicalReport(
        id: 'r1',
        title: 'Labs',
        category: ReportCategory.lab,
        fileName: 'labs.pdf',
        mimeType: 'application/pdf',
        storagePath: 'users/u/reports/r1/labs.pdf',
        sizeBytes: 12,
        uploadedAt: DateTime(2026, 1, 1),
        takenOn: DateTime(2026, 8, 14),
      );
      expect(reportsInPeriod(<MedicalReport>[report], period).single.id, 'r1');
      expect(reportDateBasis(report), ReportDateBasis.taken);
      expect(reportDateBasisLabel(report), contains('Taken'));
      expect(reportDateBasisLabel(report), isNot(contains('Uploaded')));
    });

    test('takenOn outside / uploadedAt inside → exclude on takenOn', () {
      final MedicalReport report = MedicalReport(
        id: 'r2',
        title: 'Old',
        category: ReportCategory.other,
        fileName: 'old.pdf',
        mimeType: 'application/pdf',
        storagePath: 'users/u/reports/r2/old.pdf',
        sizeBytes: 8,
        uploadedAt: DateTime(2026, 8, 12),
        takenOn: DateTime(2026, 1, 2),
      );
      expect(reportsInPeriod(<MedicalReport>[report], period), isEmpty);
    });

    test('no takenOn + uploadedAt inside → include and label Uploaded', () {
      final MedicalReport report = MedicalReport(
        id: 'r3',
        title: 'Scan',
        category: ReportCategory.imaging,
        fileName: 'scan.jpg',
        mimeType: 'image/jpeg',
        storagePath: 'users/u/reports/r3/scan.jpg',
        sizeBytes: 20,
        uploadedAt: DateTime(2026, 8, 11, 10),
      );
      expect(reportsInPeriod(<MedicalReport>[report], period).single.id, 'r3');
      expect(reportDateBasis(report), ReportDateBasis.uploaded);
      expect(reportDateBasisLabel(report), contains('Uploaded'));
    });

    test('no takenOn + uploadedAt outside → exclude', () {
      final MedicalReport report = MedicalReport(
        id: 'r4',
        title: 'Far',
        category: ReportCategory.other,
        fileName: 'far.pdf',
        mimeType: 'application/pdf',
        storagePath: 'users/u/reports/r4/far.pdf',
        sizeBytes: 8,
        uploadedAt: DateTime(2026, 1, 1),
      );
      expect(reportsInPeriod(<MedicalReport>[report], period), isEmpty);
    });
  });

  group('current vs historical', () {
    test('current medicine is labeled current context, not period-long', () {
      final EvidenceBriefPeriod ninety = EvidenceBriefPeriod.lastDays(
        90,
        now: now,
      );
      final EvidenceBrief brief = EvidenceBrief(
        period: ninety,
        context: EvidenceBriefContextSection(
          conditions: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Asthma', detail: null),
          ],
          allergies: const <EvidenceBriefContextItem>[],
          medicines: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Metformin', detail: '500 mg'),
          ],
          conditionsAnswered: true,
          allergiesAnswered: true,
          medicinesAnswered: true,
          noKnownConditions: false,
          noKnownAllergies: true,
          takesNoMedication: false,
          asOf: asOf,
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
          noMedicinesConfigured: true,
          noActiveHabits: true,
          caveats: <String>[],
        ),
      );

      final String text = formatEvidenceBriefText(brief);
      expect(text.contains('CURRENT SELF-REPORTED CONTEXT'), isTrue);
      expect(text.contains('current as of'), isTrue);
      expect(text.contains('Metformin'), isTrue);
      expect(text.toLowerCase().contains('throughout'), isFalse);
      expect(text.toLowerCase().contains('for 90 days'), isFalse);
      expect(text.contains('medicine taken for 90'), isFalse);
      expect(brief.context.asOfLabel, contains('as of'));
    });
  });

  group('routine section', () {
    test('preserves Phase 7 caveats and has no combined score', () {
      final String today = DailyDoseLog.keyFor(now);
      final EvidenceBriefPeriod period = EvidenceBriefPeriod.lastDays(
        7,
        now: now,
      );
      final EvidenceBriefRoutineSection section = buildRoutineSection(
        period: period,
        doseLogs: <DailyDoseLog>[
          DailyDoseLog(
            dateKey: today,
            statuses: const <String, DoseStatus>{'a_morning': DoseStatus.taken},
          ),
        ],
        habitLogs: <DailyHabitLog>[
          DailyHabitLog(
            dateKey: today,
            statuses: const <String, HabitStatus>{'h1': HabitStatus.done},
          ),
        ],
        dosesPerDay: 2,
        activeHabits: const <HabitItem>[
          HabitItem(
            id: 'h1',
            pillar: HabitPillar.sleep,
            slot: HabitSlot.evening,
            title: 'Wind down',
            detail: 'Quiet time',
          ),
        ],
      );

      expect(section.medicine, isNotNull);
      expect(section.medicine!.taken, 1);
      expect(section.medicine!.expected, 2);
      expect(section.lifestyle, isNotNull);
      expect(section.lifestyle!.done, 1);
      expect(section.caveats, isNotEmpty);
      expect(
        section.caveats.any(
          (String c) => c.contains('current medicine schedule'),
        ),
        isTrue,
      );
      expect(
        section.caveats.any((String c) => c.contains('no combined score')),
        isTrue,
      );
      expect(section.provenance, EvidenceProvenance.routineLog);

      final String text = formatEvidenceBriefText(
        EvidenceBrief(
          period: period,
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
            asOf: asOf,
          ),
          measurements: const EvidenceBriefMeasurementsSection(
            weights: <WeightMeasurement>[],
            bloodPressures: <BloodPressureMeasurement>[],
          ),
          reports: const EvidenceBriefReportsSection(
            reports: <EvidenceBriefReportItem>[],
          ),
          routine: section,
        ),
      );
      expect(text.contains('MEDICINE ROUTINE'), isTrue);
      expect(text.contains('LIFESTYLE ROUTINE'), isTrue);
      expect(text.toLowerCase().contains('adherent'), isFalse);
      expect(text.toLowerCase().contains('non-adherent'), isFalse);
      expect(RegExp(r'\bgood\b', caseSensitive: false).hasMatch(text), isFalse);
      expect(RegExp(r'\bpoor\b', caseSensitive: false).hasMatch(text), isFalse);
    });

    test('empty period yields empty routine without inventing scores', () {
      final EvidenceBriefRoutineSection section = buildRoutineSection(
        period: EvidenceBriefPeriod.lastDays(7, now: now),
        doseLogs: const <DailyDoseLog>[],
        habitLogs: const <DailyHabitLog>[],
        dosesPerDay: 2,
        activeHabits: const <HabitItem>[
          HabitItem(
            id: 'h1',
            pillar: HabitPillar.diet,
            slot: HabitSlot.morning,
            title: 'Breakfast',
            detail: 'Eat something',
          ),
        ],
      );
      expect(section.isEmpty, isTrue);
      expect(section.medicine, isNull);
      expect(section.lifestyle, isNull);
    });
  });

  group('share text', () {
    EvidenceBrief sampleBrief({String notes = 'Ask about dizziness'}) {
      final EvidenceBriefPeriod period = EvidenceBriefPeriod.lastDays(
        7,
        now: now,
      );
      return EvidenceBrief(
        period: period,
        context: EvidenceBriefContextSection(
          conditions: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Type 2 diabetes', detail: null),
          ],
          allergies: const <EvidenceBriefContextItem>[],
          medicines: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Metformin', detail: '500 mg'),
          ],
          conditionsAnswered: true,
          allergiesAnswered: true,
          medicinesAnswered: true,
          noKnownConditions: false,
          noKnownAllergies: true,
          takesNoMedication: false,
          asOf: asOf,
        ),
        measurements: EvidenceBriefMeasurementsSection(
          weights: <WeightMeasurement>[
            WeightMeasurement(
              id: 'w1',
              valueKg: 70.5,
              recordedAt: DateTime(2026, 8, 12),
            ),
          ],
          bloodPressures: <BloodPressureMeasurement>[
            BloodPressureMeasurement(
              id: 'bp1',
              systolicMmHg: 120,
              diastolicMmHg: 80,
              recordedAt: DateTime(2026, 8, 13),
            ),
          ],
        ),
        reports: EvidenceBriefReportsSection(
          reports: <EvidenceBriefReportItem>[
            EvidenceBriefReportItem(
              report: MedicalReport(
                id: 'r1',
                title: 'CBC',
                category: ReportCategory.lab,
                fileName: 'cbc.pdf',
                mimeType: 'application/pdf',
                storagePath: 'users/u/reports/r1/cbc.pdf',
                sizeBytes: 10,
                uploadedAt: DateTime(2026, 8, 14),
                notes: 'should not appear as OCR body',
                takenOn: DateTime(2026, 8, 14),
              ),
            ),
          ],
        ),
        routine: buildRoutineSection(
          period: period,
          doseLogs: <DailyDoseLog>[
            DailyDoseLog(
              dateKey: DailyDoseLog.keyFor(now),
              statuses: const <String, DoseStatus>{
                'a_morning': DoseStatus.taken,
              },
            ),
          ],
          habitLogs: const <DailyHabitLog>[],
          dosesPerDay: 1,
          activeHabits: const <HabitItem>[],
        ),
        notes: notes,
        createdAt: asOf,
      );
    }

    test('includes header, disclaimer, provenance, and omits OCR body', () {
      final EvidenceBrief brief = sampleBrief();
      final String text = formatEvidenceBriefText(brief);
      expect(text.startsWith('TARU Evidence Brief'), isTrue);
      expect(text.contains('Not a certified medical record'), isTrue);
      expect(text.contains('Sources in this brief'), isTrue);
      expect(text.contains(EvidenceProvenance.selfReported.label), isTrue);
      expect(text.contains(EvidenceProvenance.manualMeasurement.label), isTrue);
      expect(text.contains(EvidenceProvenance.reportRecord.label), isTrue);
      expect(text.contains(EvidenceProvenance.routineLog.label), isTrue);
      expect(text.contains('Type 2 diabetes'), isTrue);
      expect(text.contains('Metformin'), isTrue);
      expect(text.contains('70.5 kg'), isTrue);
      expect(text.contains('120/80 mmHg'), isTrue);
      expect(text.contains('CBC'), isTrue);
      expect(text.contains('Taken'), isTrue);
      expect(text.contains('Ask about dizziness'), isTrue);
      expect(text.contains('should not appear as OCR body'), isFalse);
      expect(text.toLowerCase().contains('combined score'), isTrue);
      expect(text.contains('current medicine schedule'), isTrue);
      expect(text.contains('hemoglobin'), isFalse);
      expect(text.contains('users/u/reports'), isFalse);
      expect(text.toLowerCase().contains('verified'), isFalse);
    });

    test('selective sharing excludes deselected sections', () {
      final EvidenceBrief brief = sampleBrief();
      final String withoutReports = formatEvidenceBriefText(
        brief,
        selection: const EvidenceBriefShareSelection(
          currentContext: true,
          measurements: true,
          reports: false,
          medicineRoutine: true,
          lifestyleRoutine: true,
          notes: true,
        ),
      );
      expect(withoutReports.contains('REPORTS'), isFalse);
      expect(withoutReports.contains('CBC'), isFalse);

      final String withoutMeasurements = formatEvidenceBriefText(
        brief,
        selection: const EvidenceBriefShareSelection(
          currentContext: true,
          measurements: false,
          reports: true,
          medicineRoutine: true,
          lifestyleRoutine: true,
          notes: false,
        ),
      );
      expect(withoutMeasurements.contains('MEASUREMENTS'), isFalse);
      expect(withoutMeasurements.contains('70.5 kg'), isFalse);
      expect(withoutMeasurements.contains('Ask about dizziness'), isFalse);
      expect(withoutMeasurements.contains('CBC'), isTrue);
    });

    test('preview/share formatter parity uses one function', () {
      final EvidenceBrief brief = sampleBrief();
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        reports: false,
        notes: true,
      );
      final String preview = formatEvidenceBriefText(
        brief,
        selection: selection,
        createdAt: asOf,
      );
      final String shared = formatEvidenceBriefText(
        brief,
        selection: selection,
        createdAt: asOf,
      );
      expect(preview, shared);
    });

    test('empty brief still formats honestly', () {
      final EvidenceBrief brief = EvidenceBrief(
        period: EvidenceBriefPeriod.lastDays(30, now: now),
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
          asOf: asOf,
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
          noMedicinesConfigured: true,
          noActiveHabits: true,
          caveats: <String>[
            'Medicine and lifestyle are separate — there is no combined score.',
          ],
        ),
      );

      final String text = formatEvidenceBriefText(
        brief,
        selection: const EvidenceBriefShareSelection(),
      );
      expect(text.contains('Not recorded'), isTrue);
      expect(text.contains('No weight or blood pressure'), isTrue);
      expect(text.contains('No reports'), isTrue);
      expect(brief.isEffectivelyEmpty, isTrue);
      expect(brief.hasNoPeriodEvidence, isTrue);
    });

    test('reviewed extracted text body is never included', () {
      final EvidenceBrief brief = sampleBrief();
      final String text = formatEvidenceBriefText(brief);
      expect(text.contains('hemoglobin 14.2'), isFalse);
      expect(text.contains('OCR'), isFalse);
      expect(text.contains('extracted'), isFalse);
    });
  });

  group('provenance labels', () {
    test('context / measurement / report / routine map correctly', () {
      expect(
        const EvidenceBriefContextItem(label: 'x', detail: null).provenance,
        EvidenceProvenance.selfReported,
      );
      expect(
        EvidenceBriefMeasurementItem.weight(
          WeightMeasurement(id: 'w', valueKg: 1, recordedAt: now),
        ).provenance,
        EvidenceProvenance.manualMeasurement,
      );
      expect(
        EvidenceBriefReportItem(
          report: MedicalReport(
            id: 'r',
            title: 't',
            category: ReportCategory.other,
            fileName: 'f.pdf',
            mimeType: 'application/pdf',
            storagePath: 'p',
            sizeBytes: 1,
            uploadedAt: now,
          ),
        ).provenance,
        EvidenceProvenance.reportRecord,
      );
      for (final EvidenceProvenance p in EvidenceProvenance.values) {
        expect(p.label.toLowerCase().contains('verified'), isFalse);
        expect(p.label.toLowerCase().contains('ai '), isFalse);
      }
    });
  });

  group('sources summary', () {
    test('lists factual counts without scores', () {
      final EvidenceBrief brief = EvidenceBrief(
        period: EvidenceBriefPeriod.lastDays(7, now: now),
        context: EvidenceBriefContextSection(
          conditions: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Hypertension', detail: null),
          ],
          allergies: const <EvidenceBriefContextItem>[],
          medicines: const <EvidenceBriefContextItem>[],
          conditionsAnswered: true,
          allergiesAnswered: false,
          medicinesAnswered: false,
          noKnownConditions: false,
          noKnownAllergies: false,
          takesNoMedication: false,
          asOf: asOf,
        ),
        measurements: EvidenceBriefMeasurementsSection(
          weights: List<WeightMeasurement>.generate(
            8,
            (int i) => WeightMeasurement(
              id: 'w$i',
              valueKg: 70,
              recordedAt: DateTime(2026, 8, 12),
            ),
          ),
          bloodPressures: const <BloodPressureMeasurement>[],
        ),
        reports: EvidenceBriefReportsSection(
          reports: <EvidenceBriefReportItem>[
            EvidenceBriefReportItem(
              report: MedicalReport(
                id: 'r1',
                title: 'A',
                category: ReportCategory.lab,
                fileName: 'a.pdf',
                mimeType: 'application/pdf',
                storagePath: 'p',
                sizeBytes: 1,
                uploadedAt: DateTime(2026, 8, 12),
              ),
            ),
            EvidenceBriefReportItem(
              report: MedicalReport(
                id: 'r2',
                title: 'B',
                category: ReportCategory.lab,
                fileName: 'b.pdf',
                mimeType: 'application/pdf',
                storagePath: 'p',
                sizeBytes: 1,
                uploadedAt: DateTime(2026, 8, 13),
              ),
            ),
          ],
        ),
        routine: const EvidenceBriefRoutineSection(
          medicine: AdherenceSummary(taken: 3, expected: 7, daysCovered: 5),
          lifestyle: HabitAdherenceSummary(
            done: 4,
            possible: 10,
            daysCovered: 4,
            byPillar: <HabitPillarWeekStat>[],
          ),
          noMedicinesConfigured: false,
          noActiveHabits: false,
          caveats: <String>[],
          medicineDaysWithRecords: 5,
          lifestyleDaysWithRecords: 4,
        ),
      );

      final List<String> lines = brief.sourcesSummary.lines;
      expect(lines, contains('Current self-reported context'));
      expect(lines, contains('8 weight readings'));
      expect(lines, contains('2 report records'));
      expect(lines, contains('Medicine logs on 5 days'));
      expect(lines, contains('Lifestyle logs on 4 days'));
      expect(lines.join(' ').toLowerCase().contains('score'), isFalse);
      expect(lines.join(' ').contains('%'), isFalse);
    });
  });

  group('query bounds', () {
    test('inclusive calendar end becomes next-day exclusive query end', () {
      final EvidenceBriefPeriod period = EvidenceBriefPeriod.custom(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 16),
      );
      expect(period.queryStartInclusive, DateTime(2026, 8, 1));
      expect(period.queryEndExclusive, DateTime(2026, 8, 17));
    });
  });

  group('current-context as-of date', () {
    test('uses generation/current date, not selected period end', () {
      final EvidenceBriefPeriod may = EvidenceBriefPeriod.custom(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 31),
      );
      final DateTime generatedOn = DateTime(2026, 8, 16);
      final EvidenceBrief brief = EvidenceBrief(
        period: may,
        context: EvidenceBriefContextSection(
          conditions: const <EvidenceBriefContextItem>[],
          allergies: const <EvidenceBriefContextItem>[],
          medicines: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Metformin', detail: null),
          ],
          conditionsAnswered: true,
          allergiesAnswered: true,
          medicinesAnswered: true,
          noKnownConditions: true,
          noKnownAllergies: true,
          takesNoMedication: false,
          asOf: generatedOn,
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
          noMedicinesConfigured: true,
          noActiveHabits: true,
          caveats: <String>[],
        ),
        createdAt: generatedOn,
      );
      final String text = formatEvidenceBriefText(brief);
      expect(text.contains('current as of 16 Aug 2026'), isTrue);
      expect(text.contains('current as of 31 May'), isFalse);
      expect(brief.context.asOf, generatedOn);
      expect(brief.context.asOf, isNot(may.end));
    });
  });

  group('section failure share matrix', () {
    EvidenceBrief base({
      EvidenceBriefSectionLoad reportsLoad =
          const EvidenceBriefSectionLoad.ready(),
      EvidenceBriefSectionLoad measurementsLoad =
          const EvidenceBriefSectionLoad.ready(),
      EvidenceBriefSectionLoad medicineLoad =
          const EvidenceBriefSectionLoad.ready(),
      EvidenceBriefSectionLoad lifestyleLoad =
          const EvidenceBriefSectionLoad.ready(),
      EvidenceBriefSectionLoad contextLoad =
          const EvidenceBriefSectionLoad.ready(),
    }) {
      return EvidenceBrief(
        period: EvidenceBriefPeriod.lastDays(7, now: now),
        context: EvidenceBriefContextSection(
          conditions: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Asthma', detail: null),
          ],
          allergies: const <EvidenceBriefContextItem>[],
          medicines: const <EvidenceBriefContextItem>[],
          conditionsAnswered: true,
          allergiesAnswered: true,
          medicinesAnswered: false,
          noKnownConditions: false,
          noKnownAllergies: true,
          takesNoMedication: false,
          asOf: asOf,
        ),
        measurements: EvidenceBriefMeasurementsSection(
          weights: <WeightMeasurement>[
            WeightMeasurement(
              id: 'w1',
              valueKg: 70,
              recordedAt: DateTime(2026, 8, 12),
            ),
          ],
          bloodPressures: const <BloodPressureMeasurement>[],
        ),
        reports: EvidenceBriefReportsSection(
          reports: <EvidenceBriefReportItem>[
            EvidenceBriefReportItem(
              report: MedicalReport(
                id: 'r1',
                title: 'CBC',
                category: ReportCategory.lab,
                fileName: 'cbc.pdf',
                mimeType: 'application/pdf',
                storagePath: 'p',
                sizeBytes: 1,
                uploadedAt: DateTime(2026, 8, 12),
              ),
            ),
          ],
        ),
        routine: const EvidenceBriefRoutineSection(
          medicine: AdherenceSummary(taken: 1, expected: 2, daysCovered: 1),
          lifestyle: HabitAdherenceSummary(
            done: 1,
            possible: 2,
            daysCovered: 1,
            byPillar: <HabitPillarWeekStat>[],
          ),
          noMedicinesConfigured: false,
          noActiveHabits: false,
          caveats: <String>[
            'Medicine and lifestyle are separate — there is no combined score.',
          ],
          medicineDaysWithRecords: 1,
          lifestyleDaysWithRecords: 1,
        ),
        contextLoad: contextLoad,
        measurementsLoad: measurementsLoad,
        reportsLoad: reportsLoad,
        medicineLoad: medicineLoad,
        lifestyleLoad: lifestyleLoad,
      );
    }

    test('A reports fail + excluded → measurements-only share allowed', () {
      final EvidenceBrief brief = base(
        reportsLoad: EvidenceBriefSectionLoad.failed(StateError('reports')),
      );
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        reports: false,
        notes: false,
        medicineRoutine: false,
        lifestyleRoutine: false,
      );
      expect(selection.isShareableFor(brief), isTrue);
      final String text = formatEvidenceBriefText(brief, selection: selection);
      expect(text.contains('MEASUREMENTS'), isTrue);
      expect(text.contains('REPORTS'), isFalse);
      expect(text.contains('CBC'), isFalse);
    });

    test('B reports fail + selected → share blocked', () {
      final EvidenceBrief brief = base(
        reportsLoad: EvidenceBriefSectionLoad.failed(StateError('reports')),
      );
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        reports: true,
      );
      expect(selection.isShareableFor(brief), isFalse);
    });

    test('C reports retry ready → can select/share', () {
      final EvidenceBrief brief = base();
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        reports: true,
      );
      expect(selection.isShareableFor(brief), isTrue);
      expect(
        formatEvidenceBriefText(brief, selection: selection).contains('CBC'),
        isTrue,
      );
    });

    test('D reports empty successfully is not failure', () {
      final EvidenceBrief brief = base(
        reportsLoad: const EvidenceBriefSectionLoad.empty(),
      ).copyWithEmptyReports();
      expect(brief.reportsLoad.isFailed, isFalse);
      expect(brief.reportsLoad.isEmpty, isTrue);
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        reports: true,
        notes: false,
      );
      expect(selection.isShareableFor(brief), isTrue);
      expect(
        formatEvidenceBriefText(
          brief,
          selection: selection,
        ).contains('No reports'),
        isTrue,
      );
    });

    test('E measurements fail + excluded → reports-only allowed', () {
      final EvidenceBrief brief = base(
        measurementsLoad: EvidenceBriefSectionLoad.failed(StateError('m')),
      );
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        measurements: false,
        notes: false,
        medicineRoutine: false,
        lifestyleRoutine: false,
      );
      expect(selection.isShareableFor(brief), isTrue);
      final String text = formatEvidenceBriefText(brief, selection: selection);
      expect(text.contains('REPORTS'), isTrue);
      expect(text.contains('MEASUREMENTS'), isFalse);
    });

    test('F medicine fails + excluded → lifestyle allowed', () {
      final EvidenceBrief brief = base(
        medicineLoad: EvidenceBriefSectionLoad.failed(StateError('dose')),
      );
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        medicineRoutine: false,
        measurements: false,
        reports: false,
        currentContext: false,
        notes: false,
        lifestyleRoutine: true,
      );
      expect(selection.isShareableFor(brief), isTrue);
      final String text = formatEvidenceBriefText(brief, selection: selection);
      expect(text.contains('LIFESTYLE ROUTINE'), isTrue);
      expect(text.contains('MEDICINE ROUTINE'), isFalse);
    });

    test('G selected loading section blocks share', () {
      final EvidenceBrief brief = base(
        reportsLoad: const EvidenceBriefSectionLoad.loading(),
      );
      const EvidenceBriefShareSelection selection = EvidenceBriefShareSelection(
        reports: true,
      );
      expect(selection.isShareableFor(brief), isFalse);
    });
  });

  group('human formatter contract', () {
    test('realistic brief order, labels, and forbidden language', () {
      final EvidenceBriefPeriod period = EvidenceBriefPeriod.lastDays(
        30,
        now: now,
      );
      final EvidenceBrief brief = EvidenceBrief(
        period: period,
        context: EvidenceBriefContextSection(
          conditions: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Type 2 diabetes', detail: null),
          ],
          allergies: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Penicillin', detail: 'rash'),
          ],
          medicines: const <EvidenceBriefContextItem>[
            EvidenceBriefContextItem(label: 'Metformin', detail: '500 mg'),
          ],
          conditionsAnswered: true,
          allergiesAnswered: true,
          medicinesAnswered: true,
          noKnownConditions: false,
          noKnownAllergies: false,
          takesNoMedication: false,
          asOf: asOf,
        ),
        measurements: EvidenceBriefMeasurementsSection(
          weights: <WeightMeasurement>[
            WeightMeasurement(
              id: 'w1',
              valueKg: 72.4,
              recordedAt: DateTime(2026, 8, 10),
            ),
          ],
          bloodPressures: <BloodPressureMeasurement>[
            BloodPressureMeasurement(
              id: 'bp1',
              systolicMmHg: 118,
              diastolicMmHg: 76,
              recordedAt: DateTime(2026, 8, 11),
            ),
          ],
        ),
        reports: EvidenceBriefReportsSection(
          reports: <EvidenceBriefReportItem>[
            EvidenceBriefReportItem(
              report: MedicalReport(
                id: 'r-taken',
                title: 'Lipid panel',
                category: ReportCategory.lab,
                fileName: 'lipids.pdf',
                mimeType: 'application/pdf',
                storagePath: 'users/u/reports/r-taken/lipids.pdf',
                sizeBytes: 10,
                uploadedAt: DateTime(2026, 1, 1),
                takenOn: DateTime(2026, 8, 5),
                notes: 'OCR BODY MUST NOT APPEAR hemoglobin 14.2',
              ),
            ),
            EvidenceBriefReportItem(
              report: MedicalReport(
                id: 'r-uploaded',
                title: 'Chest X-ray',
                category: ReportCategory.imaging,
                fileName: 'xray.jpg',
                mimeType: 'image/jpeg',
                storagePath: 'users/u/reports/r-uploaded/xray.jpg',
                sizeBytes: 20,
                uploadedAt: DateTime(2026, 8, 8),
              ),
            ),
          ],
        ),
        routine: buildRoutineSection(
          period: period,
          doseLogs: <DailyDoseLog>[
            DailyDoseLog(
              dateKey: DailyDoseLog.keyFor(now),
              statuses: const <String, DoseStatus>{
                'a_morning': DoseStatus.taken,
              },
            ),
          ],
          habitLogs: <DailyHabitLog>[
            DailyHabitLog(
              dateKey: DailyDoseLog.keyFor(now),
              statuses: const <String, HabitStatus>{'h1': HabitStatus.done},
            ),
          ],
          dosesPerDay: 1,
          activeHabits: const <HabitItem>[
            HabitItem(
              id: 'h1',
              pillar: HabitPillar.exercise,
              slot: HabitSlot.morning,
              title: 'Walk',
              detail: 'Short walk',
            ),
          ],
        ),
        notes: 'Please review my recent readings.',
        createdAt: asOf,
      );

      final String text = formatEvidenceBriefText(brief, createdAt: asOf);

      expect(text.indexOf('TARU Evidence Brief'), 0);
      expect(text.indexOf('Period:'), lessThan(text.indexOf('Created:')));
      expect(
        text.indexOf('CURRENT SELF-REPORTED CONTEXT'),
        lessThan(text.indexOf('MEASUREMENTS')),
      );
      expect(text.indexOf('MEASUREMENTS'), lessThan(text.indexOf('REPORTS')));
      expect(
        text.indexOf('REPORTS'),
        lessThan(text.indexOf('MEDICINE ROUTINE')),
      );
      expect(
        text.indexOf('MEDICINE ROUTINE'),
        lessThan(text.indexOf('LIFESTYLE ROUTINE')),
      );
      expect(
        text.indexOf('LIFESTYLE ROUTINE'),
        lessThan(text.indexOf('NOTES / QUESTIONS')),
      );
      expect(text.contains('Current information you have recorded'), isTrue);
      expect(text.contains('current as of 16 Aug 2026'), isTrue);
      expect(text.contains(EvidenceProvenance.selfReported.label), isTrue);
      expect(text.contains(EvidenceProvenance.manualMeasurement.label), isTrue);
      expect(text.contains(EvidenceProvenance.reportRecord.label), isTrue);
      expect(text.contains(EvidenceProvenance.routineLog.label), isTrue);
      expect(text.contains('Taken'), isTrue);
      expect(text.contains('Uploaded'), isTrue);
      expect(text.contains('Please review my recent readings.'), isTrue);
      expect(text.contains('Contains information recorded in TARU'), isTrue);
      expect(
        text.toLowerCase().contains('not a certified medical record'),
        isTrue,
      );
      expect(text.contains('users/u/reports'), isFalse);
      expect(text.contains('OCR BODY MUST NOT APPEAR'), isFalse);
      expect(text.contains('hemoglobin'), isFalse);
      for (final String banned in <String>[
        'diagnosis',
        'abnormal',
        'unhealthy',
        'good adherence',
        'poor adherence',
        'health score',
        'clinical summary',
        'clinically verified',
        'doctor verified',
      ]) {
        expect(
          text.toLowerCase().contains(banned.toLowerCase()),
          isFalse,
          reason: 'banned term leaked: $banned',
        );
      }
      expect(RegExp(r'\bAI\b').hasMatch(text), isFalse);
      expect(
        RegExp(r'\bnormal\b', caseSensitive: false).hasMatch(text),
        isFalse,
      );
      expect(
        RegExp(r'\bhealthy\b', caseSensitive: false).hasMatch(text),
        isFalse,
      );
    });
  });
}

extension on EvidenceBrief {
  EvidenceBrief copyWithEmptyReports() {
    return EvidenceBrief(
      period: period,
      context: context,
      measurements: measurements,
      reports: const EvidenceBriefReportsSection(
        reports: <EvidenceBriefReportItem>[],
      ),
      routine: routine,
      notes: notes,
      createdAt: createdAt,
      contextLoad: contextLoad,
      measurementsLoad: measurementsLoad,
      reportsLoad: const EvidenceBriefSectionLoad.empty(),
      medicineLoad: medicineLoad,
      lifestyleLoad: lifestyleLoad,
    );
  }
}
