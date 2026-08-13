import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../../domain/report_extraction.dart';

/// Review/edit extracted report text before it is saved as derived content.
class ReportTextReviewScreen extends ConsumerStatefulWidget {
  const ReportTextReviewScreen({
    super.key,
    required this.report,
    required this.initialText,
    required this.method,
    this.previousReviewedText,
  });

  final MedicalReport report;
  final String initialText;
  final ReportExtractionMethod method;

  /// When non-null, Save is a replace and prior bytes can be restored.
  final String? previousReviewedText;

  @override
  ConsumerState<ReportTextReviewScreen> createState() =>
      _ReportTextReviewScreenState();
}

class _ReportTextReviewScreenState
    extends ConsumerState<ReportTextReviewScreen> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _utf8Bytes => utf8.encode(_controller.text).length;

  bool get _overLimit => _utf8Bytes > kMaxReviewedTextUtf8Bytes;

  String get _provenanceLabel => switch (widget.method) {
    ReportExtractionMethod.pdfText => 'From PDF text',
    ReportExtractionMethod.ocr => 'From on-device scan (OCR)',
  };

  String get _methodHint => switch (widget.method) {
    ReportExtractionMethod.pdfText =>
      'Machine-extracted from PDF selectable text. It may not be '
          'exact — review before saving.',
    ReportExtractionMethod.ocr =>
      'Text was read from this report on your device. Review it carefully '
          'before saving.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.previousReviewedText == null
              ? 'Review extracted text'
              : 'Replace extracted text',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Text is extracted on this device. It is saved to your TARU '
                'account only after you review and confirm it.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _provenanceLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _methodHint,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    hintText: 'Edit the extracted text before saving',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _overLimit
                    ? 'Too large to save ($_utf8Bytes bytes; max '
                          '$kMaxReviewedTextUtf8Bytes bytes).'
                    : '$_utf8Bytes / $kMaxReviewedTextUtf8Bytes bytes',
                style: TextStyle(
                  fontSize: 12,
                  color: _overLimit
                      ? const Color(0xffB3261E)
                      : Colors.grey.shade600,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xffB3261E)),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _overLimit ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || _overLimit) return;

    final String text = _controller.text;
    if (utf8.encode(text).length > kMaxReviewedTextUtf8Bytes) {
      setState(() {
        _error =
            'Reviewed text is too large to save in this release. '
            'Shorten it and try again.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      setState(() {
        _saving = false;
        _error = 'Sign in to save reviewed text.';
      });
      return;
    }

    try {
      await ref
          .read(reportsRepositoryProvider)
          .saveReviewedText(
            uid: user.uid,
            reportId: widget.report.id,
            reviewedText: text,
            method: widget.method,
            previousReviewedText: widget.previousReviewedText,
          );
      ref.invalidate(reportExtractionProvider(widget.report.id));
      ref.invalidate(loadReviewedTextProvider(widget.report.id));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is StateError
            ? error.message
            : 'Could not save reviewed text. Please try again.';
      });
    }
  }
}
