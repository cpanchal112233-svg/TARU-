import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/reliability/user_facing_error.dart';
import 'package:mobile/features/account/data/account_root_repository.dart';
import 'package:mobile/features/account/domain/account_integrity.dart';
import 'package:mobile/features/privacy/domain/purge_mode.dart';
import 'package:mobile/features/startup/presentation/pages/auth_gate.dart';

void main() {
  test('client identity helper never writes deletion guard fields', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    await AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'u1',
    ).createIdentityRoot(name: 'Ada', email: 'ada@example.com');

    final Map<String, dynamic> data =
        (await firestore.collection('users').doc('u1').get()).data()!;
    expect(data.containsKey('deletionInProgress'), isFalse);
    expect(data.containsKey('deletionStartedAt'), isFalse);
    expect(data.keys.toSet(), <String>{'name', 'email', 'createdAt'});
  });

  test('partial account-delete leftover Auth stays in recovery', () {
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.missingRoot,
      ),
      AuthGateDestination.recovery,
    );
  });

  test('recent-auth purge failure stays a product error, not a crash payload', () {
    const PurgeException error = PurgeException(
      PurgeFailureCode.recentAuthRequired,
      message: 'RECENT_AUTH_REQUIRED',
    );
    expect(userFacingErrorMessage(error), kReauthenticationRequired);
    expect(userFacingErrorMessage(error), isNot(contains('RECENT_AUTH_REQUIRED')));
  });

  test('health deletion guard blocks MainShell and leaves guard untouched', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('u1').set(<String, dynamic>{
      'name': 'Ada',
      'email': 'ada@example.com',
      'deletionInProgress': PurgeMode.health.wireValue,
      'deletionStartedAt': 'keep-me',
    });
    await AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'u1',
    ).createIdentityRoot(name: 'Nope', email: 'nope@example.com');
    final Map<String, dynamic> data =
        (await firestore.collection('users').doc('u1').get()).data()!;
    expect(data['deletionInProgress'], 'health');
    expect(data['deletionStartedAt'], 'keep-me');
    expect(
      interpretAccountRoot(
        exists: true,
        isFromCache: false,
        deletionInProgress: 'health',
      ),
      AccountIntegrity.deletionHealthInProgress,
    );
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.deletionHealthInProgress,
      ),
      AuthGateDestination.recovery,
    );
  });

  test('account deletion guard blocks MainShell', () {
    expect(
      interpretAccountRoot(
        exists: true,
        isFromCache: false,
        deletionInProgress: 'account',
      ),
      AccountIntegrity.deletionAccountInProgress,
    );
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.deletionAccountInProgress,
      ),
      AuthGateDestination.recovery,
    );
  });
}
