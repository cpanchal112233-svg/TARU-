import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/data/reports_repository.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';

import 'support/memory_report_object_store.dart';

MedicalReport _imageReport(String id) {
  return MedicalReport(
    id: id,
    title: 'Scan',
    category: ReportCategory.lab,
    fileName: 'scan.jpg',
    mimeType: 'image/jpeg',
    storagePath: 'users/u1/reports/$id/scan.jpg',
    sizeBytes: 42,
    uploadedAt: DateTime.utc(2026, 8, 1),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late MemoryReportObjectStore objects;
  late ReportsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    objects = MemoryReportObjectStore();
    repo = ReportsRepository(firestore, objects: objects);
  });

  test('OCR save writes sidecar and method ocr metadata', () async {
    final ReportExtraction saved = await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'img1',
      reviewedText: 'OCR line one\nOCR line two',
      method: ReportExtractionMethod.ocr,
    );

    expect(saved.method, ReportExtraction.ocrMethod);
    expect(saved.isOcr, isTrue);

    final String path = reviewedExtractionStoragePath('u1', 'img1');
    expect(utf8.decode(objects.objects[path]!), 'OCR line one\nOCR line two');
    expect(objects.objects.keys, <String>{path});

    final Map<String, dynamic>? meta =
        (await firestore
                .collection('users')
                .doc('u1')
                .collection('reports')
                .doc('img1')
                .collection('extraction')
                .doc('current')
                .get())
            .data();
    expect(meta?['method'], 'ocr');
    expect(meta?['reviewedAt'], isNotNull);
  });

  test('OCR replace updates method and reviewedAt', () async {
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'img1',
      reviewedText: 'first pass',
      method: ReportExtractionMethod.ocr,
    );

    final Map<String, dynamic>? firstMeta =
        (await firestore
                .collection('users')
                .doc('u1')
                .collection('reports')
                .doc('img1')
                .collection('extraction')
                .doc('current')
                .get())
            .data();
    final Object? firstReviewedAt = firstMeta?['reviewedAt'];

    await Future<void>.delayed(const Duration(milliseconds: 2));

    final ReportExtraction replaced = await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'img1',
      reviewedText: 'edited pass',
      previousReviewedText: 'first pass',
      method: ReportExtractionMethod.pdfText,
    );

    expect(replaced.method, ReportExtraction.pdfTextMethod);
    expect(replaced.isPdfText, isTrue);

    final Map<String, dynamic>? secondMeta =
        (await firestore
                .collection('users')
                .doc('u1')
                .collection('reports')
                .doc('img1')
                .collection('extraction')
                .doc('current')
                .get())
            .data();
    expect(secondMeta?['method'], 'pdf_text');
    expect(secondMeta?['reviewedAt'], isNot(equals(firstReviewedAt)));

    final String path = reviewedExtractionStoragePath('u1', 'img1');
    expect(utf8.decode(objects.objects[path]!), 'edited pass');
    expect(objects.objects.keys, <String>{path});
  });

  test('OCR remove deletes sidecar and metadata', () async {
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'img1',
      reviewedText: 'discard me',
      method: ReportExtractionMethod.ocr,
    );

    await repo.removeReviewedExtraction('u1', 'img1');

    expect(objects.objects, isEmpty);
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('reports')
              .doc('img1')
              .collection('extraction')
              .doc('current')
              .get())
          .exists,
      isFalse,
    );
  });

  test('OCR delete cascade removes derived sidecar only', () async {
    final MedicalReport report = _imageReport('img2');
    objects.objects[report.storagePath] = Uint8List.fromList(<int>[1, 2, 3]);
    await firestore
        .collection('users')
        .doc('u1')
        .collection('reports')
        .doc('img2')
        .set(report.toMap());

    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'img2',
      reviewedText: 'derived ocr',
      method: ReportExtractionMethod.ocr,
    );

    await repo.delete('u1', report);

    expect(objects.objects, isEmpty);
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('reports')
              .doc('img2')
              .get())
          .exists,
      isFalse,
    );
  });

  test('OCR save rejects oversized reviewed text without sidecar', () async {
    final String huge = 'x' * (kMaxReviewedTextUtf8Bytes + 1);
    await expectLater(
      repo.saveReviewedText(
        uid: 'u1',
        reportId: 'img1',
        reviewedText: huge,
        method: ReportExtractionMethod.ocr,
      ),
      throwsA(isA<StateError>()),
    );
    expect(objects.objects, isEmpty);
  });

  test('OCR first-save metadata failure cleans sidecar', () async {
    final ReportsRepository failing = _FailingMetaRepository(
      firestore,
      objects: objects,
    );

    await expectLater(
      failing.saveReviewedText(
        uid: 'u1',
        reportId: 'img1',
        reviewedText: 'transient ocr',
        method: ReportExtractionMethod.ocr,
      ),
      throwsA(isA<FirebaseException>()),
    );

    expect(
      objects.objects.containsKey(reviewedExtractionStoragePath('u1', 'img1')),
      isFalse,
    );
  });
}

class _FailingMetaRepository extends ReportsRepository {
  _FailingMetaRepository(super.firestore, {super.objects});

  @override
  Future<void> writeExtractionMetadata(
    String uid,
    String reportId,
    ReportExtraction extraction,
  ) {
    throw FirebaseException(
      plugin: 'firestore',
      code: 'permission-denied',
      message: 'forced',
    );
  }
}
