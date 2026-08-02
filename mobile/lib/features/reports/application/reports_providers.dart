import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/reports_repository.dart';
import '../domain/medical_report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  ),
);

final reportsProvider = StreamProvider<List<MedicalReport>>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) {
    return Stream<List<MedicalReport>>.value(const <MedicalReport>[]);
  }

  return ref.watch(reportsRepositoryProvider).watch(user.uid);
});

typedef ReportUpload =
    Future<MedicalReport> Function({
      required String title,
      required ReportCategory category,
      required String fileName,
      required String mimeType,
      required Uint8List bytes,
      DateTime? takenOn,
      String? notes,
      void Function(double progress)? onProgress,
    });

final uploadReportProvider = Provider<ReportUpload>((ref) {
  return ({
    required String title,
    required ReportCategory category,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    DateTime? takenOn,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    final User? user = ref.read(authStateChangesProvider).value;

    if (user == null) {
      throw StateError('Cannot upload a report while signed out.');
    }

    return ref
        .read(reportsRepositoryProvider)
        .upload(
          uid: user.uid,
          title: title,
          category: category,
          fileName: fileName,
          mimeType: mimeType,
          bytes: bytes,
          takenOn: takenOn,
          notes: notes,
          onProgress: onProgress,
        );
  };
});

final deleteReportProvider = Provider<Future<void> Function(MedicalReport)>((
  ref,
) {
  return (MedicalReport report) async {
    final User? user = ref.read(authStateChangesProvider).value;

    if (user == null) {
      throw StateError('Cannot delete a report while signed out.');
    }

    await ref.read(reportsRepositoryProvider).delete(user.uid, report);
  };
});

final reportDownloadUrlProvider = FutureProvider.family<String, MedicalReport>((
  ref,
  report,
) {
  return ref.watch(reportsRepositoryProvider).downloadUrl(report);
});
