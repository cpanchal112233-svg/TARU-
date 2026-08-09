import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/application/auth_providers.dart';
import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../../domain/report_extraction.dart';
import '../widgets/report_widgets.dart';
import 'report_metadata_edit_sheet.dart';
import 'report_text_review_screen.dart';

/// Full view of one report: image preview in-app, PDF opened externally.
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.report});

  final MedicalReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MedicalReport current = ref
        .watch(reportsProvider)
        .maybeWhen(
          data: (List<MedicalReport> items) {
            for (final MedicalReport item in items) {
              if (item.id == report.id) return item;
            }
            return report;
          },
          orElse: () => report,
        );

    final AsyncValue<String> url = ref.watch(
      reportDownloadUrlProvider(current),
    );
    final AsyncValue<ReportExtraction?> extraction = ref.watch(
      reportExtractionProvider(current.id),
    );

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(current.title),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editMetadata(context, ref, current),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, current),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _MetaCard(
            report: current,
            onEdit: () => _editMetadata(context, ref, current),
          ),
          const SizedBox(height: 16),
          url.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stack) =>
                const _ErrorBox(message: 'Could not open this file.'),
            data: (String downloadUrl) => current.isImage
                ? _ImagePreview(url: downloadUrl)
                : _PdfActions(url: downloadUrl, fileName: current.fileName),
          ),
          const SizedBox(height: 16),
          _ExtractedTextSection(
            report: current,
            extraction: extraction,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The original upload is the source. Reviewed extracted text '
                  'is derived and is not treated as clinical truth. '
                  'Understanding and explaining what a report means comes later.',
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

  Future<void> _editMetadata(
    BuildContext context,
    WidgetRef ref,
    MedicalReport current,
  ) async {
    final MedicalReport? updated = await showReportMetadataEditSheet(
      context,
      current,
    );
    if (updated == null || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Details saved.')));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MedicalReport current,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete this report?'),
        content: Text(
          '"${current.title}" will be removed from TARU. This cannot be undone.',
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
      await ref.read(deleteReportProvider)(current);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this report.')),
      );
    }
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.report, required this.onEdit});

  final MedicalReport report;
  final VoidCallback onEdit;

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
              TextButton(onPressed: onEdit, child: const Text('Edit')),
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

class _ExtractedTextSection extends ConsumerStatefulWidget {
  const _ExtractedTextSection({
    required this.report,
    required this.extraction,
  });

  final MedicalReport report;
  final AsyncValue<ReportExtraction?> extraction;

  @override
  ConsumerState<_ExtractedTextSection> createState() =>
      _ExtractedTextSectionState();
}

class _ExtractedTextSectionState
    extends ConsumerState<_ExtractedTextSection> {
  bool _busy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted text',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!widget.report.isPdf) ...[
            Text(
              'Text extraction currently supports digital PDFs only.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
          ] else
            widget.extraction.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stack) => const Text(
                'Could not load extraction details.',
                style: TextStyle(color: Color(0xffB3261E)),
              ),
              data: (ReportExtraction? extraction) {
                if (extraction == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pull selectable text from this PDF on your device, '
                        'review it, then save if you want to keep it.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _extract(replace: false),
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.text_snippet_outlined),
                        label: Text(_busy ? 'Extracting…' : 'Extract text'),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Machine-extracted from PDF text · reviewed by you',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reviewed ${formatReportDate(extraction.reviewedAt)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: _busy ? null : _viewReviewed,
                          child: const Text('View'),
                        ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _extract(replace: true),
                          child: const Text('Replace'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _remove,
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _message!.startsWith('Could')
                    ? const Color(0xffB3261E)
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _extract({required bool replace}) async {
    if (_busy) return;

    String? previous;
    if (replace) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Replace reviewed text?'),
          content: const Text(
            'The current reviewed text will be overwritten after you '
            'confirm the new review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      try {
        previous = await ref.read(
          loadReviewedTextProvider(widget.report.id).future,
        );
      } catch (error, stack) {
        developer.log(
          'load previous reviewed text failed',
          name: 'reports.extract',
          error: error,
          stackTrace: stack,
        );
        previous = null;
      }
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final File file = await ref
          .read(reportsRepositoryProvider)
          .downloadToTemp(widget.report);
      final String text = await ref
          .read(pdfSelectableTextExtractorProvider)
          .extractFromFile(file);

      if (!mounted) return;

      if (text.trim().isEmpty) {
        setState(() {
          _busy = false;
          _message =
              "This report doesn't appear to contain selectable text. "
              'Scanned or image-based report text extraction isn\'t '
              'supported yet.';
        });
        return;
      }

      setState(() => _busy = false);

      final bool? saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReportTextReviewScreen(
            report: widget.report,
            initialText: text,
            previousReviewedText: previous,
          ),
        ),
      );

      if (!mounted) return;
      if (saved == true) {
        setState(() => _message = 'Reviewed text saved.');
      }
    } catch (error, stack) {
      developer.log(
        'extract failed',
        name: 'reports.extract',
        error: error,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Could not extract text from this PDF. Please try again.';
      });
    }
  }

  Future<void> _viewReviewed() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final String text = await ref.read(
        loadReviewedTextProvider(widget.report.id).future,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (BuildContext context) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController controller) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Reviewed extracted text',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Machine-extracted from PDF text · reviewed by you',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: SelectableText(
                          text,
                          style: const TextStyle(fontSize: 14, height: 1.45),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (error, stack) {
      developer.log(
        'view reviewed failed',
        name: 'reports.extract',
        error: error,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Could not load reviewed text.';
      });
    }
  }

  Future<void> _remove() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Remove reviewed text?'),
        content: const Text(
          'The original report file stays. Only the reviewed extracted '
          'text will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await ref
          .read(reportsRepositoryProvider)
          .removeReviewedExtraction(user.uid, widget.report.id);
      ref.invalidate(reportExtractionProvider(widget.report.id));
      ref.invalidate(loadReviewedTextProvider(widget.report.id));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Reviewed text removed.';
      });
    } catch (error, stack) {
      developer.log(
        'remove reviewed failed',
        name: 'reports.extract',
        error: error,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Could not remove reviewed text. Please try again.';
      });
    }
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
              const _ErrorBox(message: 'Could not load the image.'),
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
