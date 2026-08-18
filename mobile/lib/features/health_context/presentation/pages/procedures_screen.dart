import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/health_context_providers.dart';
import '../../domain/approximate_date.dart';
import '../../domain/procedure_record.dart';
import '../widgets/approximate_date_fields.dart';
import '../widgets/health_context_record_list.dart';

class ProceduresScreen extends ConsumerWidget {
  const ProceduresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HealthContextRecordList<ProcedureRecord>(
      title: 'Procedures & surgeries',
      emptyLabel: 'No procedures recorded.',
      async: ref.watch(proceduresProvider),
      itemTitle: (ProcedureRecord item) => item.name,
      itemSubtitle: (ProcedureRecord item) => item.occurredOn.displayLabel,
      onAdd: () => _open(context, null),
      onOpen: (ProcedureRecord item) => _open(context, item),
      onDelete: (ProcedureRecord item) async {
        final bool ok = await confirmHealthContextDelete(
          context,
          title: 'Delete this procedure?',
          body: 'Removes ${item.name} from your TARU records.',
        );
        if (!ok) return;
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await ref.read(procedureRepositoryProvider).delete(user.uid, item.id);
      },
    );
  }

  void _open(BuildContext context, ProcedureRecord? existing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProcedureEditor(existing: existing),
      ),
    );
  }
}

class _ProcedureEditor extends ConsumerStatefulWidget {
  const _ProcedureEditor({this.existing});

  final ProcedureRecord? existing;

  @override
  ConsumerState<_ProcedureEditor> createState() => _ProcedureEditorState();
}

class _ProcedureEditorState extends ConsumerState<_ProcedureEditor> {
  late final TextEditingController _name;
  late final TextEditingController _reason;
  late final TextEditingController _facility;
  late final TextEditingController _clinician;
  late final TextEditingController _notes;
  late ApproximateDate _occurredOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _reason = TextEditingController(text: widget.existing?.reason ?? '');
    _facility = TextEditingController(text: widget.existing?.facility ?? '');
    _clinician = TextEditingController(text: widget.existing?.clinician ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _occurredOn = widget.existing?.occurredOn ?? ApproximateDate.unknown;
  }

  @override
  void dispose() {
    _name.dispose();
    _reason.dispose();
    _facility.dispose();
    _clinician.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Procedure'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Procedure name'),
          ),
          ApproximateDateFields(
            label: 'When',
            value: _occurredOn,
            onChanged: (ApproximateDate value) =>
                setState(() => _occurredOn = value),
          ),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason if you know'),
          ),
          TextField(
            controller: _facility,
            decoration: const InputDecoration(labelText: 'Facility (optional)'),
          ),
          TextField(
            controller: _clinician,
            decoration: const InputDecoration(
              labelText: 'Clinician (optional)',
            ),
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final User? user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a procedure name.')));
      return;
    }
    if (showIncompleteDateSnack(context, _occurredOn, 'procedure date')) return;
    setState(() => _saving = true);
    final String id =
        widget.existing?.id ??
        ref.read(procedureRepositoryProvider).newId(user.uid);
    try {
      await ref
          .read(procedureRepositoryProvider)
          .upsert(
            user.uid,
            id,
            ProcedureRecord(
              id: id,
              name: _name.text.trim(),
              occurredOn: _occurredOn,
              reason: _reason.text.trim(),
              facility: _facility.text.trim(),
              clinician: _clinician.text.trim(),
              notes: _notes.text.trim(),
              recordedAt: widget.existing?.recordedAt,
              updatedAt: widget.existing?.updatedAt,
            ).stamped(now: DateTime.now().toUtc()),
          );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
