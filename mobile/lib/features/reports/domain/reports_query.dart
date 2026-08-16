import 'medical_report.dart';

/// In-memory filter/search over an already-loaded reports list.
///
/// Search is case-insensitive substring match on title and notes only.
/// [category] null means All. Blank search means no text constraint.
List<MedicalReport> filterReports(
  List<MedicalReport> reports, {
  String query = '',
  ReportCategory? category,
}) {
  final String needle = query.trim().toLowerCase();

  return reports
      .where((MedicalReport report) {
        if (category != null && report.category != category) return false;
        if (needle.isEmpty) return true;

        final String title = report.title.toLowerCase();
        if (title.contains(needle)) return true;

        final String? notes = report.notes;
        if (notes == null) return false;
        return notes.toLowerCase().contains(needle);
      })
      .toList(growable: false);
}
