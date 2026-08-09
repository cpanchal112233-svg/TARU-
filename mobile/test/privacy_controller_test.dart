import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/privacy/domain/purge_mode.dart';

void main() {
  test('PurgeException carries stable codes', () {
    const PurgeException error = PurgeException(
      PurgeFailureCode.recentAuthRequired,
      message: 'RECENT_AUTH_REQUIRED',
    );
    expect(error.code, PurgeFailureCode.recentAuthRequired);
    expect(error.toString(), contains('RECENT_AUTH_REQUIRED'));
  });
}
