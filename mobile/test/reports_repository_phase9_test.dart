import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/data/reports_repository.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';

import 'support/memory_report_object_store.dart';

MedicalReport _sampleReport(String id) {
  return MedicalReport(
    id: id,
    title: 'CBC',
    category: ReportCategory.lab,
    fileName: 'cbc.pdf',
    mimeType: 'application/pdf',
    storagePath: 'users/u1/reports/$id/cbc.pdf',
    sizeBytes: 12,
    uploadedAt: DateTime.utc(2026, 8, 1),
    notes: 'Fasting',
  );
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

void main() {
  late FakeFirebaseFirestore firestore;
  late MemoryReportObjectStore objects;
  late ReportsRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    objects = MemoryReportObjectStore();
    repo = ReportsRepository(firestore, objects: objects);
  });

  test('updateMetadata edits only mutable fields', () async {
    final MedicalReport report = _sampleReport('r1');
    await firestore
        .collection('users')
        .doc('u1')
        .collection('reports')
        .doc('r1')
        .set(report.toMap());

    await repo.updateMetadata(
      'u1',
      MedicalReport(
        id: report.id,
        title: 'CBC updated',
        category: ReportCategory.other,
        fileName: report.fileName,
        mimeType: report.mimeType,
        storagePath: report.storagePath,
        sizeBytes: report.sizeBytes,
        uploadedAt: report.uploadedAt,
        takenOn: DateTime.utc(2026, 7, 1),
        notes: 'Evening',
      ),
    );

    final Map<String, dynamic>? data =
        (await firestore
                .collection('users')
                .doc('u1')
                .collection('reports')
                .doc('r1')
                .get())
            .data();

    expect(data?['title'], 'CBC updated');
    expect(data?['category'], 'other');
    expect(data?['notes'], 'Evening');
    expect(data?['takenOn'], '2026-07-01T00:00:00.000Z');
    expect(data?['storagePath'], report.storagePath);
    expect(data?['fileName'], report.fileName);
    expect(data?['mimeType'], report.mimeType);
    expect(data?['sizeBytes'], report.sizeBytes);
    expect(data?['uploadedAt'], report.uploadedAt.toIso8601String());
  });

  test('first save writes sidecar then metadata', () async {
    final ReportExtraction saved = await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'r1',
      reviewedText: 'Hemoglobin 13.8',
      method: ReportExtractionMethod.pdfText,
    );

    expect(saved.method, 'pdf_text');
    final String path = reviewedExtractionStoragePath('u1', 'r1');
    expect(utf8.decode(objects.objects[path]!), 'Hemoglobin 13.8');
    expect(objects.contentTypes[path], 'text/plain');

    final Map<String, dynamic>? meta =
        (await firestore
                .collection('users')
                .doc('u1')
                .collection('reports')
                .doc('r1')
                .collection('extraction')
                .doc('current')
                .get())
            .data();
    expect(meta?['method'], 'pdf_text');
    expect(meta?['reviewedAt'], isNotNull);
  });

  test('first-save metadata failure cleans sidecar', () async {
    final ReportsRepository failing = _FailingMetaRepository(
      firestore,
      objects: objects,
    );

    await expectLater(
      failing.saveReviewedText(
        uid: 'u1',
        reportId: 'r1',
        reviewedText: 'transient',
        method: ReportExtractionMethod.pdfText,
      ),
      throwsA(isA<FirebaseException>()),
    );

    expect(
      objects.objects.containsKey(reviewedExtractionStoragePath('u1', 'r1')),
      isFalse,
    );
  });

  test('loadReviewedText returns saved UTF-8 text', () async {
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'r1',
      reviewedText: 'Platelets 250',
      method: ReportExtractionMethod.pdfText,
    );
    expect(await repo.loadReviewedText('u1', 'r1'), 'Platelets 250');
  });

  test('replace overwrites same deterministic path', () async {
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'r1',
      reviewedText: 'old text',
      method: ReportExtractionMethod.pdfText,
    );
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'r1',
      reviewedText: 'new text',
      previousReviewedText: 'old text',
      method: ReportExtractionMethod.pdfText,
    );

    final String path = reviewedExtractionStoragePath('u1', 'r1');
    expect(utf8.decode(objects.objects[path]!), 'new text');
    expect(
      objects.objects.keys.where((String k) => k.contains('derived')),
      hasLength(1),
    );
  });

  test('replace metadata failure restores previous sidecar', () async {
    final MemoryReportObjectStore store = MemoryReportObjectStore()
      ..objects[reviewedExtractionStoragePath('u1', 'r1')] = Uint8List.fromList(
        utf8.encode('old text'),
      )
      ..contentTypes[reviewedExtractionStoragePath('u1', 'r1')] = 'text/plain';

    final ReportsRepository failing = _FailingMetaRepository(
      firestore,
      objects: store,
    );

    await expectLater(
      failing.saveReviewedText(
        uid: 'u1',
        reportId: 'r1',
        reviewedText: 'new text',
        previousReviewedText: 'old text',
        method: ReportExtractionMethod.pdfText,
      ),
      throwsA(isA<FirebaseException>()),
    );

    expect(
      utf8.decode(store.objects[reviewedExtractionStoragePath('u1', 'r1')]!),
      'old text',
    );
  });

  test('remove deletes sidecar and metadata; missing sidecar is ok', () async {
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'r1',
      reviewedText: 'to remove',
      method: ReportExtractionMethod.pdfText,
    );
    await repo.removeReviewedExtraction('u1', 'r1');
    expect(
      objects.objects.containsKey(reviewedExtractionStoragePath('u1', 'r1')),
      isFalse,
    );
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('reports')
              .doc('r1')
              .collection('extraction')
              .doc('current')
              .get())
          .exists,
      isFalse,
    );

    await repo.removeReviewedExtraction('u1', 'r1');
  });

  test('size guard rejects oversized reviewed text', () async {
    final String huge = 'a' * (kMaxReviewedTextUtf8Bytes + 1);
    await expectLater(
      repo.saveReviewedText(
        uid: 'u1',
        reportId: 'r1',
        reviewedText: huge,
        method: ReportExtractionMethod.pdfText,
      ),
      throwsA(isA<StateError>()),
    );
    expect(objects.objects, isEmpty);
  });

  test('delete cascade removes derived, source, metadata, report', () async {
    final MedicalReport report = _sampleReport('r1');
    objects.objects[report.storagePath] = Uint8List.fromList(<int>[1, 2, 3]);
    await firestore
        .collection('users')
        .doc('u1')
        .collection('reports')
        .doc('r1')
        .set(report.toMap());
    await repo.saveReviewedText(
      uid: 'u1',
      reportId: 'r1',
      reviewedText: 'derived',
      method: ReportExtractionMethod.pdfText,
    );

    await repo.delete('u1', report);

    expect(objects.objects, isEmpty);
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('reports')
              .doc('r1')
              .get())
          .exists,
      isFalse,
    );
  });

  test('delete tolerates already-missing storage objects', () async {
    final MedicalReport report = _sampleReport('r2');
    await firestore
        .collection('users')
        .doc('u1')
        .collection('reports')
        .doc('r2')
        .set(report.toMap());

    await repo.delete('u1', report);
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('reports')
              .doc('r2')
              .get())
          .exists,
      isFalse,
    );
  });

  test('delete surfaces source delete failure before parent removal', () async {
    final MedicalReport report = _sampleReport('r3');
    final String derived = reviewedExtractionStoragePath('u1', 'r3');
    objects.objects[derived] = Uint8List.fromList(utf8.encode('x'));
    objects.objects[report.storagePath] = Uint8List.fromList(<int>[9]);
    // Derived delete succeeds; source delete fails; parent remains.
    objects.failDeletePaths.add(report.storagePath);
    await firestore
        .collection('users')
        .doc('u1')
        .collection('reports')
        .doc('r3')
        .set(report.toMap());

    await expectLater(
      repo.delete('u1', report),
      throwsA(isA<FirebaseException>()),
    );
    expect(objects.objects.containsKey(derived), isFalse);
    expect(objects.objects.containsKey(report.storagePath), isTrue);
    expect(
      (await firestore
              .collection('users')
              .doc('u1')
              .collection('reports')
              .doc('r3')
              .get())
          .exists,
      isTrue,
    );
  });
}
