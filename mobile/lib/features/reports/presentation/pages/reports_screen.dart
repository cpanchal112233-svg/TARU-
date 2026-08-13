import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../../domain/reports_query.dart';
import '../widgets/report_widgets.dart';
import 'report_detail_screen.dart';
import 'report_upload_sheet.dart';

/// Lists the user's uploaded medical documents and starts new uploads.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ReportCategory? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'Could not load your reports. ${userFacingErrorMessage(error)}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (List<MedicalReport> items) => items.isEmpty
            ? _EmptyState(onAdd: () => _upload(context))
            : _ReportsListBody(
                reports: items,
                searchController: _searchController,
                categoryFilter: _categoryFilter,
                onCategoryChanged: (ReportCategory? value) {
                  setState(() => _categoryFilter = value);
                },
                onSearchChanged: (_) => setState(() {}),
              ),
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
              'TARU keeps it private to your account. You can extract text '
              'on this device and review it before saving.',
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

class _ReportsListBody extends StatelessWidget {
  const _ReportsListBody({
    required this.reports,
    required this.searchController,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  final List<MedicalReport> reports;
  final TextEditingController searchController;
  final ReportCategory? categoryFilter;
  final ValueChanged<ReportCategory?> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final List<MedicalReport> filtered = filterReports(
      reports,
      query: searchController.text,
      category: categoryFilter,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search title or notes',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: categoryFilter == null,
                onSelected: (_) => onCategoryChanged(null),
              ),
              const SizedBox(width: 8),
              for (final ReportCategory category in ReportCategory.values) ...[
                FilterChip(
                  label: Text(category.label),
                  selected: categoryFilter == category,
                  onSelected: (_) => onCategoryChanged(
                    categoryFilter == category ? null : category,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          filtered.isEmpty
              ? 'No matching reports'
              : '${filtered.length} ${filtered.length == 1 ? 'report' : 'reports'}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'Try a different search or category.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          for (final MedicalReport report in filtered)
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
