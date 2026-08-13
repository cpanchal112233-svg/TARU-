import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/routine/domain/dose_schedule.dart';
import 'package:mobile/features/routine/domain/habit.dart';

void main() {
  test('adherence percent math unchanged (Phase 7)', () {
    const AdherenceSummary summary = AdherenceSummary(
      taken: 8,
      expected: 10,
      daysCovered: 5,
    );
    expect(summary.percent, 80);
    expect(summary.rate, 0.8);
    expect(summary.hasData, isTrue);
  });

  test('medicine and lifestyle summaries stay independent types', () {
    const AdherenceSummary medicine = AdherenceSummary(
      taken: 3,
      expected: 6,
      daysCovered: 2,
    );
    const HabitAdherenceSummary lifestyle = HabitAdherenceSummary(
      done: 4,
      possible: 8,
      daysCovered: 2,
      byPillar: <HabitPillarWeekStat>[],
    );
    expect(medicine.percent, 50);
    expect(lifestyle.percent, 50);
  });
}
