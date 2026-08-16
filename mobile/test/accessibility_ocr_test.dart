import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/medical_report.dart';
import 'package:mobile/features/reports/domain/report_extraction.dart';
import 'package:mobile/features/reports/presentation/pages/report_text_review_screen.dart';

MedicalReport _sampleReport() {
  return MedicalReport(
    id: 'r1',
    title: 'Lab panel',
    category: ReportCategory.lab,
    fileName: 'lab.pdf',
    mimeType: 'application/pdf',
    storagePath: 'users/test/reports/r1.pdf',
    sizeBytes: 1200,
    uploadedAt: DateTime(2026, 8, 1),
  );
}

void main() {
  testWidgets('OCR review editor and actions are accessible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReportTextReviewScreen(
            report: _sampleReport(),
            initialText: 'Sample extracted text for accessibility review.',
            method: ReportExtractionMethod.pdfText,
          ),
        ),
      ),
    );

    expect(find.text('Reviewed text'), findsOneWidget);
    expect(find.textContaining('PDF'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('OCR review remains present at large text scale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            home: ReportTextReviewScreen(
              report: _sampleReport(),
              initialText: List<String>.filled(
                40,
                'Line of reviewed text.',
              ).join('\n'),
              method: ReportExtractionMethod.ocr,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Reviewed text'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
