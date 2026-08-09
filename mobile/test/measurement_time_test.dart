import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/measurements/domain/measurement_time.dart';

void main() {
  group('measurement recordedAt validation', () {
    final DateTime now = DateTime.utc(2026, 8, 9, 12, 0);

    test('accepts past recordedAt', () {
      expect(
        () => ensureRecordedAtAllowed(
          now.subtract(const Duration(days: 3)),
          now: now,
        ),
        returnsNormally,
      );
    });

    test('accepts within 2-minute future skew', () {
      expect(
        () => ensureRecordedAtAllowed(
          now.add(const Duration(minutes: 2)),
          now: now,
        ),
        returnsNormally,
      );
    });

    test('rejects more than 2 minutes in the future', () {
      expect(
        () => ensureRecordedAtAllowed(
          now.add(const Duration(minutes: 2, seconds: 1)),
          now: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('authoritative latest comparison', () {
    final DateTime t = DateTime.utc(2026, 8, 1, 10);

    test('empty latest makes candidate newer', () {
      expect(
        isAuthoritativeNewer(
          candidateRecordedAt: t,
          candidateDocumentId: 'aaa',
          latestRecordedAt: null,
          latestDocumentId: null,
        ),
        isTrue,
      );
    });

    test('newer recordedAt wins', () {
      expect(
        isAuthoritativeNewer(
          candidateRecordedAt: t.add(const Duration(hours: 1)),
          candidateDocumentId: 'aaa',
          latestRecordedAt: t,
          latestDocumentId: 'zzz',
        ),
        isTrue,
      );
      expect(
        isAuthoritativeNewer(
          candidateRecordedAt: t.subtract(const Duration(hours: 1)),
          candidateDocumentId: 'zzz',
          latestRecordedAt: t,
          latestDocumentId: 'aaa',
        ),
        isFalse,
      );
    });

    test('equal recordedAt uses documentId DESC', () {
      expect(
        isAuthoritativeNewer(
          candidateRecordedAt: t,
          candidateDocumentId: 'bbb',
          latestRecordedAt: t,
          latestDocumentId: 'aaa',
        ),
        isTrue,
      );
      expect(
        isAuthoritativeNewer(
          candidateRecordedAt: t,
          candidateDocumentId: 'aaa',
          latestRecordedAt: t,
          latestDocumentId: 'bbb',
        ),
        isFalse,
      );
    });
  });
}
