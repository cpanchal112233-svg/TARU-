import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reports_providers.dart';
import '../../domain/medical_report.dart';
import '../widgets/report_widgets.dart';

Future<MedicalReport?> showReportMetadataEditSheet(
  BuildContext context,
  MedicalReport report,
) {
  return showModalBottomSheet<MedicalReport>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xffF8FAFC),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ReportMetadataEditSheet(report: report),
  );
}

class ReportMetadataEditSheet extends ConsumerStatefulWidget {
  const ReportMetadataEditSheet({super.key, required this.report});

  final MedicalReport report;

  @override
  ConsumerState<ReportMetadataEditSheet> createState() =>
      _ReportMetadataEditSheetState();
}

class _ReportMetadataEditSheetState
    extends ConsumerState<ReportMetadataEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late ReportCategory _category;
  DateTime? _takenOn;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _notesController = TextEditingController(text: widget.report.notes ?? '');
    _category = widget.report.category;
    _takenOn = widget.report.takenOn;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportCategory>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final ReportCategory category in ReportCategory.values)
                  DropdownMenuItem<ReportCategory>(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (ReportCategory? value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dated'),
              subtitle: Text(
                _takenOn == null ? 'Not set' : formatReportDate(_takenOn!),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_takenOn != null)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _takenOn = null),
                      child: const Text('Clear'),
                    ),
                  TextButton(
                    onPressed: _saving ? null : _pickDate,
                    child: const Text('Pick'),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xffB3261E))),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _takenOn ?? now,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _takenOn = picked);
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Add a title.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final String notesRaw = _notesController.text.trim();
    final MedicalReport updated = MedicalReport(
      id: widget.report.id,
      title: title,
      category: _category,
      fileName: widget.report.fileName,
      mimeType: widget.report.mimeType,
      storagePath: widget.report.storagePath,
      sizeBytes: widget.report.sizeBytes,
      uploadedAt: widget.report.uploadedAt,
      takenOn: _takenOn,
      notes: notesRaw.isEmpty ? null : notesRaw,
    );

    try {
      await ref.read(updateReportMetadataProvider)(updated);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save details.';
      });
    }
  }
}
