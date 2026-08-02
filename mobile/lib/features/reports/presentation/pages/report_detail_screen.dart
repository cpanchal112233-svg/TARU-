import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../widgets/report_widgets.dart';

/// Full view of one report: image preview in-app, PDF opened externally.
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.report});

  final MedicalReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String> url = ref.watch(reportDownloadUrlProvider(report));

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(report.title),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _MetaCard(report: report),
          const SizedBox(height: 16),
          url.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stack) =>
                _ErrorBox(message: 'Could not open this file.\n$error'),
            data: (String downloadUrl) => report.isImage
                ? _ImagePreview(url: downloadUrl)
                : _PdfActions(url: downloadUrl, fileName: report.fileName),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TARU stores this privately for you. Understanding and '
                  'explaining what it means comes in a later step — for now '
                  'this is a secure place to keep it.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete this report?'),
        content: Text(
          '"${report.title}" will be removed from TARU. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(deleteReportProvider)(report);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete: $error')));
    }
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.report});

  final MedicalReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reportCategoryIcon(report.category),
                color: const Color(0xff2E8BFF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReportTypeChip(category: report.category),
          const SizedBox(height: 12),
          _MetaLine(
            label: 'File',
            value: '${report.fileName}  •  ${report.sizeLabel}',
          ),
          _MetaLine(
            label: 'Uploaded',
            value: formatReportDate(report.uploadedAt),
          ),
          if (report.takenOn != null)
            _MetaLine(label: 'Dated', value: formatReportDate(report.takenOn!)),
          if (report.notes != null && report.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.notes!,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InteractiveViewer(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
          errorBuilder: (_, Object error, StackTrace? stack) =>
              _ErrorBox(message: 'Could not load the image.\n$error'),
        ),
      ),
    );
  }
}

class _PdfActions extends StatelessWidget {
  const _PdfActions({required this.url, required this.fileName});

  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 48,
            color: Color(0xffB3261E),
          ),
          const SizedBox(height: 12),
          Text(
            fileName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'PDFs open in your device viewer so you can zoom, share or print.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the PDF.')));
    }
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFDECEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xff7F1D1D), height: 1.45),
      ),
    );
  }
}
