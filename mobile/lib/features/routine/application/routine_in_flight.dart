import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoutineInFlight extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  static String dose(String doseKey) => 'dose:$doseKey';

  static String habit(String habitId) => 'habit:$habitId';

  bool isBusy(String token) => state.contains(token);

  Future<void> run(String token, Future<void> Function() action) async {
    if (state.contains(token)) return;
    state = <String>{...state, token};
    try {
      await action();
    } finally {
      final Set<String> next = <String>{...state}..remove(token);
      state = next;
    }
  }
}

Future<void> performRoutineWrite({
  required RoutineInFlight guard,
  required String token,
  required Future<void> Function() action,
  required void Function(Object error) onError,
}) async {
  if (guard.isBusy(token)) return;
  try {
    await guard.run(token, action);
  } catch (error) {
    onError(error);
  }
}

final routineInFlightProvider =
    NotifierProvider<RoutineInFlight, Set<String>>(RoutineInFlight.new);
