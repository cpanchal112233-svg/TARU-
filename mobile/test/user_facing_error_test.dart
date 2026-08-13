import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/reliability/user_facing_error.dart';
import 'package:mobile/features/privacy/domain/purge_mode.dart';

void main() {
  const String secret = 'WEIGHT_123_DO_NOT_SEND';

  test('network errors map to network copy', () {
    expect(userFacingErrorMessage(const SocketException('failed')), kNetworkError);
    expect(
      userFacingErrorMessage(TimeoutException('late')),
      kNetworkError,
    );
    expect(
      userFacingErrorMessage(
        FirebaseAuthException(code: 'network-request-failed', message: secret),
      ),
      kNetworkError,
    );
  });

  test('authentication and reauth map to safe copy', () {
    expect(
      userFacingErrorMessage(
        FirebaseAuthException(code: 'invalid-credential', message: secret),
      ),
      kAuthenticationError,
    );
    expect(
      userFacingErrorMessage(
        const PurgeException(
          PurgeFailureCode.recentAuthRequired,
          message: 'RECENT_AUTH_REQUIRED',
        ),
      ),
      kReauthenticationRequired,
    );
  });

  test('temporary service failure maps without raw text', () {
    expect(
      userFacingErrorMessage(
        FirebaseAuthException(code: 'too-many-requests', message: secret),
      ),
      kTemporaryServiceError,
    );
  });

  test('device storage exhaustion is recognized', () {
    expect(
      userFacingErrorMessage(
        const FileSystemException('write failed', '/tmp/x', OSError('No space left on device', 28)),
      ),
      kDeviceStorageError,
    );
    expect(
      userFacingErrorMessage(const FileSystemException('denied', '/secret/path')),
      kDeviceOperationError,
    );
  });

  test('permission maps to permission copy', () {
    expect(
      userFacingErrorMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: secret),
      ),
      kPermissionError,
    );
  });

  test('unknown never includes raw exception text', () {
    final String message = userFacingErrorMessage(StateError(secret));
    expect(message, kGenericOperationFailed);
    expect(message, isNot(contains(secret)));
    expect(
      userFacingErrorMessage(Exception('USER_EMAIL_DO_NOT_SEND')),
      isNot(contains('USER_EMAIL_DO_NOT_SEND')),
    );
    expect(
      userFacingErrorMessage(PlatformException(code: 'weird', message: secret)),
      isNot(contains(secret)),
    );
  });
}
