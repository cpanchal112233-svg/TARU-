import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/reports/domain/reports_query.dart';

MedicalReport _report({
  required String id,
  required String title,
  ReportCategory category = ReportCategory.lab,
  String? notes,
}) {
  return MedicalReport(
    id: id,
    title: title,
    category: category,
    fileName: '$id.pdf',
    mimeType: 'application/pdf',
    storagePath: 'users/u/reports/$id/$id.pdf',
    sizeBytes: 100,
    uploadedAt: DateTime.utc(2026, 8, 1),
    notes: notes,
  );
}

void main() {
  final List<MedicalReport> reports = <MedicalReport>[
    _report(id: '1', title: 'CBC Panel', notes: 'Fasting morning'),
    _report(
      id: '2',
      title: 'Chest X-ray',
      category: ReportCategory.imaging,
      notes: null,
    ),
    _report(
      id: '3',
      title: 'Discharge letter',
      category: ReportCategory.discharge,
      notes: 'Follow up Friday',
    ),
  ];

  group('filterReports', () {
    test('blank search and All category returns all', () {
      expect(filterReports(reports).length, 3);
    });

    test('matches title case-insensitively', () {
      final List<MedicalReport> result = filterReports(reports, query: 'cbc');
      expect(result.map((MedicalReport r) => r.id), <String>['1']);
    });

    test('matches notes case-insensitively', () {
      final List<MedicalReport> result = filterReports(
        reports,
        query: 'FRIDAY',
      );
      expect(result.map((MedicalReport r) => r.id), <String>['3']);
    });

    test('null notes do not match search', () {
      final List<MedicalReport> result = filterReports(
        reports,
        query: 'x-ray-extra',
      );
      expect(result, isEmpty);
    });

    test('filters by category', () {
      final List<MedicalReport> result = filterReports(
        reports,
        category: ReportCategory.imaging,
      );
      expect(result.map((MedicalReport r) => r.id), <String>['2']);
    });

    test('combines search and category', () {
      final List<MedicalReport> result = filterReports(
        reports,
        query: 'follow',
        category: ReportCategory.discharge,
      );
      expect(result.map((MedicalReport r) => r.id), <String>['3']);
    });

    test('no matches', () {
      expect(filterReports(reports, query: 'zzz').isEmpty, isTrue);
    });
  });
}
