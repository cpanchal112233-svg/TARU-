import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../widgets/report_widgets.dart';

/// Picks a PDF or image, then collects title/category before uploading.
Future<MedicalReport?> showReportUploadSheet(BuildContext context) {
  return showModalBottomSheet<MedicalReport>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xffF8FAFC),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ReportUploadSheet(),
  );
}

class _ReportUploadSheet extends ConsumerStatefulWidget {
  const _ReportUploadSheet();

  @override
  ConsumerState<_ReportUploadSheet> createState() => _ReportUploadSheetState();
}

class _ReportUploadSheetState extends ConsumerState<_ReportUploadSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  PlatformFile? _file;
  Uint8List? _bytes;
  ReportCategory _category = ReportCategory.lab;
  DateTime? _takenOn;
  bool _picking = false;
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  static const int _maxBytes = 20 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    // Open the picker immediately — the sheet is the "add" action, not a
    // second confirmation before choosing a file.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickFile());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_picking || _uploading) return;

    setState(() {
      _picking = true;
      _error = null;
    });

    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'heic',
          'webp',
        ],
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        if (_file == null) Navigator.of(context).pop();
        return;
      }

      final PlatformFile file = result.files.single;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        setState(() => _error = 'Could not read that file. Try another copy.');
        return;
      }

      if (bytes.length > _maxBytes) {
        setState(
          () => _error = 'That file is over 20 MB. Compress it or split it.',
        );
        return;
      }

      setState(() {
        _file = file;
        _bytes = bytes;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = p
              .basenameWithoutExtension(file.name)
              .replaceAll(RegExp(r'[_\-]+'), ' ');
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the file picker: $error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickTakenOn() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _takenOn ?? now,
      firstDate: DateTime(now.year - 40),
      lastDate: now,
      helpText: 'When was this test or letter dated?',
    );

    if (picked == null) return;
    setState(() => _takenOn = picked);
  }

  Future<void> _upload() async {
    final PlatformFile? file = _file;
    final Uint8List? bytes = _bytes;

    if (file == null || bytes == null || _uploading) return;

    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final MedicalReport report = await ref.read(uploadReportProvider)(
        title: _titleController.text,
        category: _category,
        fileName: file.name,
        mimeType: _mimeFor(file.name),
        bytes: bytes,
        takenOn: _takenOn,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        onProgress: (double value) {
          if (mounted) setState(() => _progress = value);
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(report);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'Upload failed: $error';
      });
    }
  }

  static String _mimeFor(String name) {
    final String ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.pdf' => 'application/pdf',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.heic' => 'image/heic',
      '.webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add a report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'PDF or photo of a lab result, scan, prescription or letter. '
            'Kept private to your account.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 18),

          if (_picking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_file == null)
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose a file'),
            )
          else ...[
            _SelectedFileTile(
              name: _file!.name,
              sizeLabel: _sizeLabel(_bytes!.length),
              onChange: _uploading ? null : _pickFile,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              enabled: !_uploading,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportCategory>(
              initialValue: _category,
              decoration: _decoration('What is it?'),
              items: [
                for (final ReportCategory category in ReportCategory.values)
                  DropdownMenuItem<ReportCategory>(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: _uploading
                  ? null
                  : (ReportCategory? value) {
                      if (value != null) setState(() => _category = value);
                    },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _uploading ? null : _pickTakenOn,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _decoration('Dated (optional)'),
                child: Text(
                  _takenOn == null ? 'Not set' : formatReportDate(_takenOn!),
                  style: TextStyle(
                    fontSize: 15,
                    color: _takenOn == null
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              enabled: !_uploading,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                'Notes (optional)',
                hint: 'e.g. fasting bloods, left knee',
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xffB3261E), fontSize: 13),
            ),
          ],

          if (_uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress.clamp(0.05, 1.0)),
            const SizedBox(height: 8),
            Text(
              'Uploading… ${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ],

          const SizedBox(height: 18),
          FilledButton(
            onPressed: _file == null || _uploading ? null : _upload,
            child: Text(_uploading ? 'Uploading…' : 'Save report'),
          ),
        ],
      ),
    );
  }

  static String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static InputDecoration _decoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _SelectedFileTile extends StatelessWidget {
  const _SelectedFileTile({
    required this.name,
    required this.sizeLabel,
    required this.onChange,
  });

  final String name;
  final String sizeLabel;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            name.toLowerCase().endsWith('.pdf')
                ? Icons.picture_as_pdf_outlined
                : Icons.image_outlined,
            color: const Color(0xff2E8BFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  sizeLabel,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}
