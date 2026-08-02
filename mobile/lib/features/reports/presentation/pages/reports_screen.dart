import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../widgets/report_widgets.dart';
import 'report_detail_screen.dart';
import 'report_upload_sheet.dart';

/// Lists the user's uploaded medical documents and starts new uploads.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MedicalReport>> reports = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upload(context),
        icon: const Icon(Icons.add),
        label: const Text('Add report'),
      ),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your reports.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (List<MedicalReport> items) => items.isEmpty
            ? _EmptyState(onAdd: () => _upload(context))
            : _ReportsList(reports: items),
      ),
    );
  }

  Future<void> _upload(BuildContext context) async {
    final MedicalReport? uploaded = await showReportUploadSheet(context);

    if (uploaded == null || !context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved "${uploaded.title}".')));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No reports yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a lab result, scan, prescription or discharge letter. '
              'TARU keeps it private to your account — explanations in plain '
              'language come next.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload a report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList({required this.reports});

  final List<MedicalReport> reports;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          '${reports.length} ${reports.length == 1 ? 'report' : 'reports'}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        for (final MedicalReport report in reports)
          _ReportCard(
            report: report,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReportDetailScreen(report: report),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final MedicalReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: const Color(0xffEAF1FE),
            child: Icon(
              report.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : reportCategoryIcon(report.category),
              color: report.isPdf
                  ? const Color(0xffB3261E)
                  : const Color(0xff2E8BFF),
            ),
          ),
          title: Text(
            report.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportTypeChip(category: report.category),
                const SizedBox(height: 6),
                Text(
                  [
                    if (report.takenOn != null)
                      'Dated ${formatReportDate(report.takenOn!)}'
                    else
                      'Uploaded ${formatReportDate(report.uploadedAt)}',
                    report.sizeLabel,
                  ].join('  •  '),
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
