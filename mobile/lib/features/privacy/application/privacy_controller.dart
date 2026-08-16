import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../data/health_export_service.dart';
import '../data/local_privacy_cleanup.dart';
import '../data/purge_client.dart';
import '../domain/purge_mode.dart';

class PrivacyController {
  PrivacyController({
    required this._auth,
    required this._firestore,
    required this._purgeClient,
    required this._exportService,
    required this._localCleanup,
    required this.onAfterHealthReset,
  });

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PurgeClient _purgeClient;
  final HealthExportService _exportService;
  final LocalPrivacyCleanup _localCleanup;
  final void Function() onAfterHealthReset;

  Future<bool> reauthenticate(String password) async {
    final User? user = _auth.currentUser;
    final String? email = user?.email;
    if (user == null || email == null) {
      throw const PurgeException(PurgeFailureCode.unauthenticated);
    }
    final AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await user.getIdToken(true);
    return true;
  }

  /// Builds ZIP then opens the OS share sheet. Cancelling share is not failure.
  Future<ShareResultStatus> exportHealthData({
    void Function(String step)? onProgress,
  }) async {
    final File zip = await _exportService.exportToZip(onProgress: onProgress);
    try {
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(zip.path, mimeType: 'application/zip')],
          subject: 'TARU health data export',
        ),
      );
      return result.status;
    } finally {
      try {
        if (zip.existsSync()) await zip.delete();
      } catch (_) {}
      await _localCleanup.clearTaruTempFiles();
    }
  }

  Future<void> deleteHealthData({required String password}) async {
    await _localCleanup.cancelHealthNotifications();
    await reauthenticate(password);
    await _purgeClient.purge(PurgeMode.health);
    // Drop deletion claim from the local ID token so Storage writes work again.
    await _auth.currentUser?.getIdToken(true);
    await _localCleanup.disableReminderPreferences();
    await _localCleanup.clearTaruTempFiles();
    onAfterHealthReset();
  }

  /// Returns true when Auth identity was deleted.
  /// Throws [PurgeException] / [FirebaseAuthException] with honest semantics.
  Future<AccountDeleteOutcome> deleteAccount({required String password}) async {
    await _localCleanup.cancelHealthNotifications();
    await reauthenticate(password);
    await _purgeClient.purge(PurgeMode.account);
    await _localCleanup.disableReminderPreferences();
    await _localCleanup.clearTaruTempFiles();

    final User? user = _auth.currentUser;
    if (user == null) {
      return AccountDeleteOutcome.signedOutAlready;
    }

    try {
      await user.delete();
      return AccountDeleteOutcome.deleted;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        return AccountDeleteOutcome.dataPurgedAuthRemaining;
      }
      rethrow;
    }
  }

  Future<AccountDeleteOutcome> retryAuthDelete({
    required String password,
  }) async {
    await reauthenticate(password);
    final User? user = _auth.currentUser;
    if (user == null) {
      return AccountDeleteOutcome.signedOutAlready;
    }
    // Ensure server data is clean; purge is idempotent.
    final DocumentSnapshot<Map<String, dynamic>> root = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (root.exists) {
      await _purgeClient.purge(PurgeMode.account);
    }
    await user.delete();
    return AccountDeleteOutcome.deleted;
  }
}

enum AccountDeleteOutcome { deleted, signedOutAlready, dataPurgedAuthRemaining }
