import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../account/application/account_providers.dart';
import '../../account/data/account_root_repository.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user == null) {
      throw Exception('User account was not created.');
    }

    try {
      await AccountRootRepository(
        firestore: _firestore,
        currentUid: () => user.uid,
      ).createIdentityRoot(name: name, email: email);
    } catch (_) {
      throw const AccountRootSetupException();
    }

    return userCredential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sends Firebase Auth password-reset email for [email] (trimmed).
  ///
  /// Uses the project’s Firebase Auth email template. Does not confirm whether
  /// an account exists — callers should use privacy-safe success copy.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  /// Emits the signed-in user, or null when signed out.
  ///
  /// Firebase restores the previous session on launch, so the first event may
  /// already contain a user.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
