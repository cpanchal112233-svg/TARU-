import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/local_report_ocr.dart';
import '../data/pdf_selectable_text_extractor.dart';
import '../data/reports_repository.dart';
import '../domain/medical_report.dart';
import '../domain/report_extraction.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(
    ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  ),
);

final pdfSelectableTextExtractorProvider = Provider<PdfSelectableTextExtractor>(
  (ref) => PdfSelectableTextExtractor(),
);

final localReportOcrProvider = Provider<LocalReportOcr>(
  (ref) => LocalReportOcr(),
);

final reportsProvider = StreamProvider<List<MedicalReport>>((ref) {
  final User? user = ref.watch(authStateChangesProvider).value;

  if (user == null) {
    return Stream<List<MedicalReport>>.value(const <MedicalReport>[]);
  }

  return ref.watch(reportsRepositoryProvider).watch(user.uid);
});

/// Extraction provenance for one report. List screens must not watch this
/// for every row.
final reportExtractionProvider =
    StreamProvider.family<ReportExtraction?, String>((ref, reportId) {
      final User? user = ref.watch(authStateChangesProvider).value;
      if (user == null) {
        return Stream<ReportExtraction?>.value(null);
      }
      return ref
          .watch(reportsRepositoryProvider)
          .watchExtraction(user.uid, reportId);
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

final updateReportMetadataProvider =
    Provider<Future<void> Function(MedicalReport)>((ref) {
      return (MedicalReport report) async {
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) {
          throw StateError('Cannot edit a report while signed out.');
        }
        await ref
            .read(reportsRepositoryProvider)
            .updateMetadata(user.uid, report);
      };
    });

final reportDownloadUrlProvider = FutureProvider.family<String, MedicalReport>((
  ref,
  report,
) {
  return ref.watch(reportsRepositoryProvider).downloadUrl(report);
});

final loadReviewedTextProvider =
    FutureProvider.family<String, String>((ref, reportId) async {
      final User? user = ref.watch(authStateChangesProvider).value;
      if (user == null) {
        throw StateError('Cannot load reviewed text while signed out.');
      }
      return ref
          .watch(reportsRepositoryProvider)
          .loadReviewedText(user.uid, reportId);
    });
