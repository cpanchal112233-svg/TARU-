import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/features/account/application/account_providers.dart';
import 'package:mobile/features/account/data/account_root_repository.dart';
import 'package:mobile/features/account/domain/account_integrity.dart';
import 'package:mobile/features/account/domain/pending_signup_identity.dart';
import 'package:mobile/features/account/presentation/pages/account_recovery_screen.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/signup_screen.dart';
import 'package:mobile/features/privacy/domain/purge_mode.dart';
import 'package:mobile/features/startup/presentation/pages/auth_gate.dart';

class _FakeUser extends Fake implements User {
  _FakeUser({required this.uid, this.email});

  @override
  final String uid;

  @override
  final String? email;
}

class _FakeSignupAuth extends AuthService {
  _FakeSignupAuth(this.result);

  final Object result;
  int calls = 0;

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    calls += 1;
    if (result is Exception) {
      throw result as Exception;
    }
    return result as UserCredential;
  }
}

void main() {
  test('A ready root is interpreted as ready', () {
    expect(
      interpretAccountRoot(
        exists: true,
        isFromCache: false,
        deletionInProgress: null,
      ),
      AccountIntegrity.ready,
    );
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.ready,
      ),
      AuthGateDestination.mainShell,
    );
  });

  testWidgets(
    'B auth succeeded but root failed is incomplete setup, not missing account',
    (WidgetTester tester) async {
      final _FakeSignupAuth fake = _FakeSignupAuth(
        const AccountRootSetupException(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWith((Ref ref) => fake)],
          child: const MaterialApp(home: SignupScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Ada');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
      await tester.enterText(find.byType(TextFormField).at(3), 'password');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Create Account'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('login was created, but TARU could not finish'),
        findsOneWidget,
      );
      expect(find.textContaining('account was not created'), findsNothing);
      expect(find.textContaining('Account created successfully'), findsNothing);
    },
  );

  test('C explicit retry create succeeds when missing', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    final AccountRootRepository repo = AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'u1',
    );

    expect(
      await repo.createIdentityRoot(name: 'Ada', email: 'ada@example.com'),
      AccountRootCreateResult.created,
    );
    final Map<String, dynamic>? data =
        (await firestore.collection('users').doc('u1').get()).data();
    expect(data!['name'], 'Ada');
    expect(data['email'], 'ada@example.com');
    expect(data.containsKey('deletionInProgress'), isFalse);
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.ready,
      ),
      AuthGateDestination.mainShell,
    );
  });

  test('D root read unavailable does not create a root', () {
    expect(
      interpretAccountRoot(
        exists: false,
        isFromCache: true,
        deletionInProgress: null,
      ),
      AccountIntegrity.temporarilyUnavailable,
    );
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.temporarilyUnavailable,
      ),
      AuthGateDestination.recovery,
    );
  });

  test('E signed-in missing root does not auto-bootstrap into MainShell', () {
    expect(
      interpretAccountRoot(
        exists: false,
        isFromCache: false,
        deletionInProgress: null,
      ),
      AccountIntegrity.missingRoot,
    );
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

  test('F explicit recovery bootstrap writes identity fields only', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    final AccountRootRepository repo = AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'u1',
    );
    await repo.createIdentityRoot(name: 'Ada', email: 'ada@example.com');
    final Map<String, dynamic> data =
        (await firestore.collection('users').doc('u1').get()).data()!;
    expect(data.keys.toSet(), <String>{'name', 'email', 'createdAt'});
  });

  test('G existing root is not rewritten', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('u1').set(<String, dynamic>{
      'name': 'Ada',
      'email': 'ada@example.com',
      'createdAt': Timestamp.now(),
    });
    final AccountRootRepository repo = AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'u1',
    );
    expect(
      await repo.createIdentityRoot(name: 'Other', email: 'other@example.com'),
      AccountRootCreateResult.alreadyExists,
    );
    final Map<String, dynamic> data =
        (await firestore.collection('users').doc('u1').get()).data()!;
    expect(data['name'], 'Ada');
    expect(data['email'], 'ada@example.com');
  });

  test(
    'H deletionInProgress is not bootstrapped or cleared; no MainShell',
    () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set(<String, dynamic>{
        'name': 'Ada',
        'email': 'ada@example.com',
        'deletionInProgress': PurgeMode.account.wireValue,
        'deletionStartedAt': 'server',
      });
      final AccountRootRepository repo = AccountRootRepository(
        firestore: firestore,
        currentUid: () => 'u1',
      );
      expect(
        await repo.createIdentityRoot(name: 'Hack', email: 'hack@example.com'),
        AccountRootCreateResult.alreadyExists,
      );
      final Map<String, dynamic> data =
          (await firestore.collection('users').doc('u1').get()).data()!;
      expect(data['deletionInProgress'], 'account');
      expect(data['deletionStartedAt'], 'server');
      expect(data['name'], 'Ada');
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
    },
  );

  test('I account purge with leftover Auth does not recreate root', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    final AccountRootRepository repo = AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'u1',
    );
    expect(
      (await firestore.collection('users').doc('u1').get()).exists,
      isFalse,
    );
    expect(
      interpretAccountRoot(
        exists: false,
        isFromCache: false,
        deletionInProgress: null,
      ),
      AccountIntegrity.missingRoot,
    );
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
    expect(
      (await firestore.collection('users').doc('u1').get()).exists,
      isFalse,
    );
    expect(repo, isNotNull);
  });

  test('J UID comes only from the current authenticated user', () async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    final AccountRootRepository repo = AccountRootRepository(
      firestore: firestore,
      currentUid: () => 'alice',
    );
    await repo.createIdentityRoot(name: 'Alice', email: 'alice@example.com');
    expect(
      (await firestore.collection('users').doc('alice').get()).exists,
      isTrue,
    );
    expect(
      (await firestore.collection('users').doc('bob').get()).exists,
      isFalse,
    );

    expect(
      () => AccountRootRepository(
        firestore: firestore,
        currentUid: () => null,
      ).createIdentityRoot(name: 'X', email: 'x@y.z'),
      throwsStateError,
    );
  });

  testWidgets('unavailable recovery does not offer finish setup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AccountRecoveryScreen(
            integrity: AccountIntegrity.temporarilyUnavailable,
          ),
        ),
      ),
    );

    expect(find.text('Finish account setup'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('missing-root recovery requires an explicit finish action', (
    WidgetTester tester,
  ) async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    int creates = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          authStateChangesProvider.overrideWith(
            (Ref ref) => Stream<User?>.value(
              _FakeUser(uid: 'u1', email: 'ada@example.com'),
            ),
          ),
          pendingSignupIdentityProvider.overrideWithValue(
            PendingSignupIdentity()
              ..remember(name: 'Ada', email: 'ada@example.com'),
          ),
          accountRootRepositoryProvider.overrideWith((Ref ref) {
            return AccountRootRepository(
              firestore: firestore,
              currentUid: () {
                creates += 1;
                return 'u1';
              },
            );
          }),
        ],
        child: const MaterialApp(
          home: AccountRecoveryScreen(integrity: AccountIntegrity.missingRoot),
        ),
      ),
    );
    await tester.pump();
    expect(creates, 0);
    expect(find.text('Finish account setup'), findsOneWidget);

    await tester.tap(find.text('Finish account setup'));
    await tester.pumpAndSettle();
    expect(creates, greaterThan(0));
    expect(
      (await firestore.collection('users').doc('u1').get()).exists,
      isTrue,
    );
  });

  testWidgets(
    'health deletion guard shows cleanup recovery, not MainShell or finish setup',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountRecoveryScreen(
              integrity: AccountIntegrity.deletionHealthInProgress,
            ),
          ),
        ),
      );

      expect(
        find.textContaining("couldn't finish removing your health data"),
        findsOneWidget,
      );
      expect(find.text('Continue health-data cleanup'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Finish account setup'), findsNothing);
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
        isNot(AuthGateDestination.mainShell),
      );
    },
  );

  testWidgets(
    'account deletion guard shows cleanup recovery, not MainShell or finish setup',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountRecoveryScreen(
              integrity: AccountIntegrity.deletionAccountInProgress,
            ),
          ),
        ),
      );

      expect(
        find.textContaining("couldn't finish removing this account"),
        findsOneWidget,
      );
      expect(find.text('Continue account cleanup'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Finish account setup'), findsNothing);
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
    },
  );

  test('ready root maps to MainShell only when no deletion guard', () {
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.ready,
      ),
      AuthGateDestination.mainShell,
    );
  });

  test('read failure maps to temporary recovery without bootstrap', () {
    expect(
      interpretAccountRoot(
        exists: false,
        isFromCache: true,
        deletionInProgress: null,
      ),
      AccountIntegrity.temporarilyUnavailable,
    );
    expect(
      resolveAuthGate(
        splashPending: false,
        onboardingPending: false,
        onboardingComplete: true,
        authPending: false,
        signedIn: true,
        integrityPending: false,
        integrity: AccountIntegrity.temporarilyUnavailable,
      ),
      AuthGateDestination.recovery,
    );
  });
}
