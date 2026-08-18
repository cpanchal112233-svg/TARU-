import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/health_context_providers.dart';
import '../../domain/approximate_date.dart';
import '../../domain/supplement_record.dart';
import '../widgets/approximate_date_fields.dart';
import '../widgets/health_context_record_list.dart';

class SupplementsScreen extends ConsumerWidget {
  const SupplementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HealthContextRecordList<SupplementRecord>(
      title: 'Supplements',
      emptyLabel:
          'No supplements recorded. This is not a recommendation to start any.',
      async: ref.watch(supplementsProvider),
      itemTitle: (SupplementRecord item) => item.name,
      itemSubtitle: (SupplementRecord item) => item.isCurrent
          ? 'Current · ${item.provenance.label}'
          : 'Past · ${item.provenance.label}',
      onAdd: () => _edit(context, ref, null),
      onOpen: (SupplementRecord item) => _edit(context, ref, item),
      onDelete: (SupplementRecord item) async {
        final bool ok = await confirmHealthContextDelete(
          context,
          title: 'Delete this supplement?',
          body:
              'Removes ${item.name} from your TARU records. This is not medical advice.',
        );
        if (!ok) return;
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await ref.read(supplementRepositoryProvider).delete(user.uid, item.id);
      },
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    SupplementRecord? existing,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SupplementEditor(existing: existing),
      ),
    );
  }
}

class _SupplementEditor extends ConsumerStatefulWidget {
  const _SupplementEditor({this.existing});

  final SupplementRecord? existing;

  @override
  ConsumerState<_SupplementEditor> createState() => _SupplementEditorState();
}

class _SupplementEditorState extends ConsumerState<_SupplementEditor> {
  late final TextEditingController _name;
  late final TextEditingController _form;
  late final TextEditingController _dose;
  late final TextEditingController _frequency;
  late final TextEditingController _reason;
  late final TextEditingController _notes;
  late ApproximateDate _started;
  late ApproximateDate _stopped;
  late bool _current;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final SupplementRecord? existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _form = TextEditingController(text: existing?.form ?? '');
    _dose = TextEditingController(text: existing?.doseText ?? '');
    _frequency = TextEditingController(text: existing?.frequency ?? '');
    _reason = TextEditingController(text: existing?.reason ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _started = existing?.started ?? ApproximateDate.unknown;
    _stopped = existing?.stopped ?? ApproximateDate.unknown;
    _current = existing?.isCurrent ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _form.dispose();
    _dose.dispose();
    _frequency.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Add supplement' : 'Edit supplement',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Text(
            'TARU does not prescribe supplements. Dose can be left blank if you do not know it.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _form,
            decoration: const InputDecoration(labelText: 'Form or product'),
          ),
          TextField(
            controller: _dose,
            decoration: const InputDecoration(labelText: 'Dose (optional)'),
          ),
          TextField(
            controller: _frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Currently taking'),
            value: _current,
            onChanged: (bool value) => setState(() => _current = value),
          ),
          ApproximateDateFields(
            label: 'Started',
            value: _started,
            onChanged: (ApproximateDate value) =>
                setState(() => _started = value),
          ),
          const SizedBox(height: 16),
          ApproximateDateFields(
            label: 'Stopped',
            value: _stopped,
            onChanged: (ApproximateDate value) =>
                setState(() => _stopped = value),
          ),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason or purpose'),
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
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a name.')));
      return;
    }
    if (showIncompleteDateSnack(context, _started, 'started date')) return;
    if (!_current &&
        showIncompleteDateSnack(context, _stopped, 'stopped date')) {
      return;
    }
    setState(() => _saving = true);
    final String id =
        widget.existing?.id ??
        ref.read(supplementRepositoryProvider).newId(user.uid);
    final SupplementRecord record = SupplementRecord(
      id: id,
      name: name,
      form: _form.text.trim(),
      doseText: _dose.text.trim(),
      frequency: _frequency.text.trim(),
      started: _started,
      stopped: _current ? ApproximateDate.unknown : _stopped,
      reason: _reason.text.trim(),
      notes: _notes.text.trim(),
      isCurrent: _current,
      recordedAt: widget.existing?.recordedAt,
      updatedAt: widget.existing?.updatedAt,
    ).stamped(now: DateTime.now().toUtc());
    if (!record.isTemporallyConsistent) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Stopped date cannot be before started date. TARU does not infer missing dates.',
          ),
        ),
      );
      return;
    }
    try {
      await ref.read(supplementRepositoryProvider).upsert(user.uid, id, record);
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
