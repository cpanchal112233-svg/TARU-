import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/features/health_context/application/health_context_providers.dart';
import 'package:mobile/features/health_context/domain/approximate_date.dart';
import 'package:mobile/features/health_context/domain/care_team_member.dart';
import 'package:mobile/features/health_context/domain/dietary_profile.dart';
import 'package:mobile/features/health_context/domain/family_history_record.dart';
import 'package:mobile/features/health_context/domain/health_context_paths.dart';
import 'package:mobile/features/health_context/domain/health_context_snapshot.dart';
import 'package:mobile/features/health_context/domain/health_goal_record.dart';
import 'package:mobile/features/health_context/domain/immunization_record.dart';
import 'package:mobile/features/health_context/domain/lifestyle_context.dart';
import 'package:mobile/features/health_context/domain/procedure_record.dart';
import 'package:mobile/features/health_context/domain/record_provenance.dart';
import 'package:mobile/features/health_context/domain/supplement_record.dart';
import 'package:mobile/features/health_context/presentation/pages/dietary_profile_screen.dart';
import 'package:mobile/features/health_context/presentation/pages/health_context_hub_screen.dart';
import 'package:mobile/features/health_profile/domain/allergy.dart';
import 'package:mobile/features/health_profile/domain/health_profile.dart';
import 'package:mobile/features/health_profile/domain/medical_condition.dart';
import 'package:mobile/features/health_profile/domain/medication.dart';
import 'package:mobile/features/privacy/domain/your_data_inventory.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';

void main() {
  test('vegetarian excludes eggs; eggetarian allows eggs', () {
    expect(DietarySemantics.allowsEggs(DietaryPattern.vegetarian), isFalse);
    expect(DietarySemantics.allowsMeat(DietaryPattern.vegetarian), isFalse);
    expect(DietarySemantics.allowsFish(DietaryPattern.vegetarian), isFalse);
    expect(DietarySemantics.allowsEggs(DietaryPattern.eggetarian), isTrue);
    expect(DietarySemantics.allowsMeat(DietaryPattern.eggetarian), isFalse);
    expect(DietarySemantics.allowsFish(DietaryPattern.eggetarian), isFalse);
  });

  test('non-vegetarian may use animal foods; vegan forbids animal-derived', () {
    expect(DietarySemantics.allowsMeat(DietaryPattern.nonVegetarian), isTrue);
    expect(DietarySemantics.allowsFish(DietaryPattern.nonVegetarian), isTrue);
    expect(DietarySemantics.allowsEggs(DietaryPattern.nonVegetarian), isTrue);
    expect(
      DietarySemantics.allowsAnimalDerivedFoods(DietaryPattern.vegan),
      isFalse,
    );
  });

  test('pescatarian allows fish and eggs; not meat', () {
    expect(DietarySemantics.allowsFish(DietaryPattern.pescatarian), isTrue);
    expect(DietarySemantics.allowsEggs(DietaryPattern.pescatarian), isTrue);
    expect(DietarySemantics.allowsMeat(DietaryPattern.pescatarian), isFalse);
  });

  test('lifestyle missing fields stay not recorded', () {
    expect(LifestyleContext.empty.isRecorded, isFalse);
    final LifestyleContext recorded = LifestyleContext.fromMap(
      <String, dynamic>{
        'usualSleepHours': 7.5,
        'usualSleepWindow': '22:00-06:00',
      },
    );
    expect(recorded.isRecorded, isTrue);
    expect(recorded.tobaccoUse, isNull);
  });

  test('immunization records stay factual without inferred doses', () {
    const ImmunizationRecord shot = ImmunizationRecord(
      id: 'i1',
      vaccine: 'Tetanus',
      doseDescription: 'Booster',
      givenOn: ApproximateDate(precision: DatePrecision.year, year: 2020),
    );
    expect(ImmunizationRecord.fromMap('i1', shot.toMap())?.vaccine, 'Tetanus');
    expect(shot.toMap()['recommended'], isNull);
    expect(shot.toMap()['missingDoses'], isNull);
  });

  test('food restrictions stay independent of allergy records', () {
    const DietaryProfile diet = DietaryProfile(
      pattern: DietaryPattern.vegetarian,
      avoidedFoods: <String>['peanuts'],
    );
    expect(diet.avoidedFoods, contains('peanuts'));
    expect(AllergyRecord.empty.allergies, isEmpty);
    expect(
      YourDataInventory.categories.any(
        (YourDataCategory c) => c.bullets.any(
          (String b) => b.toLowerCase().contains('not medical allergy'),
        ),
      ),
      isTrue,
    );
  });

  test('desiredBy is a user goal date, not a recovery prediction', () {
    final HealthGoalRecord goal = HealthGoalRecord(
      id: 'g1',
      title: 'Improve sleep consistency',
      area: HealthGoalArea.sleep,
      recordedAt: DateTime.utc(2026, 1, 1),
      desiredBy: DateTime.utc(2026, 6, 1),
    );
    expect(goal.toMap()['desiredByMeaning'], 'userGoalDate');
    expect(goal.toMap().containsKey('predictedRecoveryDate'), isFalse);
    expect(goal.toMap().containsKey('cureDate'), isFalse);
  });

  test('procedure date precision includes unknown', () {
    expect(ApproximateDate.unknown.displayLabel, 'Date not recorded');
    final ProcedureRecord procedure = ProcedureRecord(
      id: 'p1',
      name: 'Appendectomy',
      occurredOn: const ApproximateDate(
        precision: DatePrecision.year,
        year: 2019,
      ),
    );
    expect(procedure.toMap()['occurredOn']['precision'], 'year');
    expect(ImmunizationRecord.fromMap('i1', <String, dynamic>{}), isNull);
  });

  test('missing diet and lifestyle mean not recorded', () {
    expect(DietaryProfile.empty.isRecorded, isFalse);
    expect(DietaryProfile.empty.pattern, isNull);
    expect(LifestyleContext.empty.isRecorded, isFalse);
    expect(LifestyleContext.empty.tobaccoUse, isNull);
  });

  test('HealthContextSnapshot is not a persisted aggregate', () {
    final HealthContextSnapshot snapshot = HealthContextSnapshot(
      generatedAt: DateTime.utc(2026, 8, 18, 12),
      profile: HealthProfile.empty,
      conditions: ConditionRecord.empty,
      allergies: AllergyRecord.empty,
      medications: MedicationRecord.empty,
      diet: DietaryProfile.empty,
      supplements: <SupplementRecord>[],
      familyHistory: <FamilyHistoryRecord>[],
      procedures: <ProcedureRecord>[],
      immunizations: <ImmunizationRecord>[],
      lifestyle: LifestyleContext.empty,
      goals: <HealthGoalRecord>[],
      careTeam: <CareTeamMember>[],
    );
    expect(snapshot.toDebugMap()['snapshotPersisted'], isFalse);
    expect(snapshot.toDebugMap()['generatedAt'], '2026-08-18T12:00:00.000Z');
  });

  test('provenance labels are not verification claims', () {
    for (final RecordProvenance provenance in RecordProvenance.values) {
      expect(provenance.label.toLowerCase().contains('verified'), isFalse);
    }
  });

  test('Dart does not own the destructive purge-root list', () {
    expect(
      HealthContextPaths.collectionNames,
      containsAll(<String>[
        'supplements',
        'familyHistory',
        'procedures',
        'immunizations',
        'healthGoals',
        'careTeam',
      ]),
    );
    expect(HealthContextPaths.dietaryProfileDoc, 'dietaryProfile');
    expect(HealthContextPaths.lifestyleDoc, 'lifestyle');
  });

  test(
    'shared purge-root manifest includes every Health Context collection',
    () {
      final List<dynamic> roots =
          jsonDecode(_purgeRootsFile().readAsStringSync()) as List<dynamic>;
      expect(roots, contains('health'));
      for (final String name in HealthContextPaths.collectionNames) {
        expect(roots, contains(name), reason: name);
      }
      expect(roots.contains('dietaryProfile'), isFalse);
      expect(roots.contains('lifestyle'), isFalse);
    },
  );

  test('supplement and family-history round-trip', () {
    const SupplementRecord supplement = SupplementRecord(
      id: 's1',
      name: 'Vitamin D',
      doseText: '',
      isCurrent: true,
    );
    expect(
      SupplementRecord.fromMap('s1', supplement.toMap())?.name,
      'Vitamin D',
    );
    const FamilyHistoryRecord family = FamilyHistoryRecord(
      id: 'f1',
      relationship: 'Mother',
      condition: 'Hypertension',
    );
    expect(
      FamilyHistoryRecord.fromMap('f1', family.toMap())?.relationship,
      'Mother',
    );
  });

  test('care team is user-owned reference data', () {
    const CareTeamMember member = CareTeamMember(
      id: 'c1',
      name: 'Dr Example',
      role: 'GP',
    );
    expect(member.hasContent, isTrue);
    expect(member.toMap()['email'], '');
  });

  test('recordedAt is TARU time; event fields stay event time', () {
    final DateTime recorded = DateTime.utc(2026, 8, 1);
    final ProcedureRecord procedure = ProcedureRecord(
      id: 'p1',
      name: 'Appendectomy',
      occurredOn: const ApproximateDate(
        precision: DatePrecision.year,
        year: 2019,
      ),
      recordedAt: recorded,
      updatedAt: recorded,
    );
    expect(procedure.toMap()['recordedAt'], '2026-08-01T00:00:00.000Z');
    expect(procedure.toMap()['occurredOn']['year'], 2019);
    expect(procedure.toMap()['occurredOn']['month'], isNull);
    expect(procedure.toMap()['occurredOn']['day'], isNull);
  });

  test('snapshot documents carry updatedAt without inventing history', () {
    final DietaryProfile diet = const DietaryProfile(
      pattern: DietaryPattern.vegetarian,
    ).stamped(now: DateTime.utc(2026, 8, 18, 10));
    expect(diet.recordedAt, DateTime.utc(2026, 8, 18, 10));
    expect(diet.updatedAt, DateTime.utc(2026, 8, 18, 10));
    final DietaryProfile later = diet.stamped(
      now: DateTime.utc(2026, 8, 19, 9),
    );
    expect(later.recordedAt, DateTime.utc(2026, 8, 18, 10));
    expect(later.updatedAt, DateTime.utc(2026, 8, 19, 9));
  });

  test('selfReported is the default provenance and is not verification', () {
    const SupplementRecord supplement = SupplementRecord(
      id: 's1',
      name: 'Vitamin D',
    );
    expect(supplement.provenance, RecordProvenance.selfReported);
    expect(supplement.provenance.label, 'Self-reported');
  });

  test('ApproximateDate preserves precision without fake exact dates', () {
    final ApproximateDate year = ApproximateDate.tryCreate(
      precision: DatePrecision.year,
      year: 2019,
    )!;
    expect(year.toMap()['month'], isNull);
    expect(year.toMap()['day'], isNull);
    expect(year.sortAnchor, DateTime.utc(2019, 1, 1));
    final ApproximateDate monthYear = ApproximateDate.tryCreate(
      precision: DatePrecision.monthYear,
      year: 2019,
      month: 6,
    )!;
    expect(monthYear.toMap()['day'], isNull);
    expect(monthYear.sortAnchor, DateTime.utc(2019, 6, 1));
    expect(
      ApproximateDate.tryCreate(
        precision: DatePrecision.exact,
        year: 2019,
        month: 6,
        day: 15,
      )!.toMap()['day'],
      15,
    );
    expect(ApproximateDate.unknown.toMap()['year'], isNull);
  });

  test('invalid ApproximateDate combinations are rejected', () {
    expect(
      ApproximateDate.tryCreate(precision: DatePrecision.exact, year: 2019),
      isNull,
    );
    expect(
      ApproximateDate.tryCreate(
        precision: DatePrecision.monthYear,
        year: 2019,
        month: 6,
        day: 1,
      ),
      isNull,
    );
    expect(
      ApproximateDate.tryCreate(
        precision: DatePrecision.year,
        year: 2019,
        month: 1,
      ),
      isNull,
    );
    expect(
      ApproximateDate.tryCreate(precision: DatePrecision.unknown, year: 2019),
      isNull,
    );
    expect(
      ApproximateDate.tryCreate(
        precision: DatePrecision.exact,
        year: 2019,
        month: 2,
        day: 31,
      ),
      isNull,
    );
    final ApproximateDate recovered = ApproximateDate.fromMap(<String, dynamic>{
      'precision': 'year',
      'year': 2019,
      'month': 1,
      'day': 1,
    });
    expect(recovered.isUnknown, isTrue);
    expect(recovered.toMap()['year'], isNull);
  });

  test('supplement current plus stopped date is rejected', () {
    expect(
      SupplementRecord.fromMap('s1', <String, dynamic>{
        'name': 'Iron',
        'isCurrent': true,
        'stopped': <String, dynamic>{'precision': 'year', 'year': 2020},
      }),
      isNull,
    );
  });

  test('supplement stopped before started is rejected', () {
    expect(
      SupplementRecord.fromMap('s1', <String, dynamic>{
        'name': 'Iron',
        'isCurrent': false,
        'started': <String, dynamic>{'precision': 'year', 'year': 2021},
        'stopped': <String, dynamic>{'precision': 'year', 'year': 2019},
      }),
      isNull,
    );
  });

  test('past desiredBy remains a user goal date, not recovery', () {
    final HealthGoalRecord goal = HealthGoalRecord(
      id: 'g1',
      title: 'Walk comfortably',
      area: HealthGoalArea.movement,
      recordedAt: DateTime.utc(2026, 8, 1),
      desiredBy: DateTime.utc(2026, 3, 1),
    );
    expect(goal.toMap()['desiredByMeaning'], 'userGoalDate');
    expect(
      DateTime.parse(
        goal.toMap()['desiredBy'] as String,
      ).isBefore(DateTime.parse(goal.toMap()['recordedAt'] as String)),
      isTrue,
    );
  });

  test('AdherenceSummary is deterministic for a fixed asOf', () {
    final DateTime asOf = DateTime(2026, 8, 16);
    final AdherenceSummary first = AdherenceSummary.fromLogs(
      logs: <DailyDoseLog>[
        DailyDoseLog(
          dateKey: '2026-08-16',
          statuses: const <String, DoseStatus>{'a': DoseStatus.taken},
        ),
      ],
      dosesPerDay: 2,
      windowDays: 7,
      asOf: asOf,
    );
    final AdherenceSummary second = AdherenceSummary.fromLogs(
      logs: <DailyDoseLog>[
        DailyDoseLog(
          dateKey: '2026-08-16',
          statuses: const <String, DoseStatus>{'a': DoseStatus.taken},
        ),
      ],
      dosesPerDay: 2,
      windowDays: 7,
      asOf: asOf,
    );
    expect(first.expected, 2);
    expect(first.expected, second.expected);
    expect(first.daysCovered, 1);
  });

  testWidgets('Health context hub lists new domains and existing links', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HealthContextHubScreen())),
    );
    expect(find.text('Health context'), findsWidgets);
    expect(find.text('Diet & food preferences'), findsOneWidget);
    expect(find.text('Supplements'), findsOneWidget);
    expect(find.text('Family history'), findsOneWidget);
    expect(find.text('Procedures & surgeries'), findsOneWidget);
    expect(find.text('Vaccinations'), findsOneWidget);
    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Health goals'), findsOneWidget);
    expect(find.text('Care team'), findsOneWidget);
    expect(find.text('Allergies'), findsOneWidget);
  });

  testWidgets('200% text keeps Health context and diet screens operable', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Widget scaled(Widget home) {
      return MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          );
        },
        home: home,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dietaryProfileProvider.overrideWith(
            (Ref ref) => Stream<DietaryProfile>.value(DietaryProfile.empty),
          ),
        ],
        child: scaled(const HealthContextHubScreen()),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Care team'));
    expect(find.text('Care team'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dietaryProfileProvider.overrideWith(
            (Ref ref) => Stream<DietaryProfile>.value(DietaryProfile.empty),
          ),
        ],
        child: scaled(const DietaryProfileScreen()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Diet & food preferences'), findsWidgets);
    expect(find.text('Vegetarian'), findsOneWidget);
  });

  test('collection CRUD is owner-scoped in Firestore paths', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    const String alice = 'alice';
    const String bob = 'bob';
    final ProviderContainer container = ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(firestore)],
    );
    addTearDown(container.dispose);
    await firestore.collection('users').doc(alice).set(<String, dynamic>{
      'name': 'A',
      'email': 'a@example.com',
    });
    await firestore.collection('users').doc(bob).set(<String, dynamic>{
      'name': 'B',
      'email': 'b@example.com',
    });
    await container
        .read(supplementRepositoryProvider)
        .upsert(alice, 's1', const SupplementRecord(id: 's1', name: 'Iron'));
    await container
        .read(supplementRepositoryProvider)
        .upsert(bob, 's2', const SupplementRecord(id: 's2', name: 'B12'));
    final List<SupplementRecord> aliceItems = await container
        .read(supplementRepositoryProvider)
        .watch(alice)
        .first;
    expect(aliceItems.single.name, 'Iron');
    expect(aliceItems.where((SupplementRecord s) => s.name == 'B12'), isEmpty);
  });
}

File _purgeRootsFile() {
  final File fromMobile = File('../functions/src/health_collection_roots.json');
  if (fromMobile.existsSync()) return fromMobile;
  return File('functions/src/health_collection_roots.json');
}
