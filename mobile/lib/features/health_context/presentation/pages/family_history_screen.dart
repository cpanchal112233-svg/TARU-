import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/health_context_providers.dart';
import '../../domain/approximate_date.dart';
import '../../domain/family_history_record.dart';
import '../widgets/approximate_date_fields.dart';
import '../widgets/health_context_record_list.dart';

class FamilyHistoryScreen extends ConsumerWidget {
  const FamilyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HealthContextRecordList<FamilyHistoryRecord>(
      title: 'Family history',
      emptyLabel:
          'No family history recorded. TARU does not calculate inherited risk.',
      async: ref.watch(familyHistoryProvider),
      itemTitle: (FamilyHistoryRecord item) =>
          item.condition.isEmpty ? item.relationship : item.condition,
      itemSubtitle: (FamilyHistoryRecord item) =>
          '${item.relationship} · ${item.onset.displayLabel}',
      onAdd: () => _open(context, null),
      onOpen: (FamilyHistoryRecord item) => _open(context, item),
      onDelete: (FamilyHistoryRecord item) async {
        final bool ok = await confirmHealthContextDelete(
          context,
          title: 'Delete this family history entry?',
          body:
              'Removes this record from TARU. It does not change any risk calculation — TARU does not calculate genetic risk.',
        );
        if (!ok) return;
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await ref
            .read(familyHistoryRepositoryProvider)
            .delete(user.uid, item.id);
      },
    );
  }

  void _open(BuildContext context, FamilyHistoryRecord? existing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FamilyHistoryEditor(existing: existing),
      ),
    );
  }
}

class _FamilyHistoryEditor extends ConsumerStatefulWidget {
  const _FamilyHistoryEditor({this.existing});

  final FamilyHistoryRecord? existing;

  @override
  ConsumerState<_FamilyHistoryEditor> createState() =>
      _FamilyHistoryEditorState();
}

class _FamilyHistoryEditorState extends ConsumerState<_FamilyHistoryEditor> {
  late final TextEditingController _relationship;
  late final TextEditingController _condition;
  late final TextEditingController _notes;
  late ApproximateDate _onset;
  late bool _current;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _relationship = TextEditingController(
      text: widget.existing?.relationship ?? '',
    );
    _condition = TextEditingController(text: widget.existing?.condition ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _onset = widget.existing?.onset ?? ApproximateDate.unknown;
    _current = widget.existing?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _relationship.dispose();
    _condition.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Family history entry'),
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
          const Text(
            'TARU does not infer inherited risk from this information.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final String suggestion in familyRelationshipSuggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _relationship.text = suggestion,
                ),
            ],
          ),
          TextField(
            controller: _relationship,
            decoration: const InputDecoration(labelText: 'Relationship'),
          ),
          TextField(
            controller: _condition,
            decoration: const InputDecoration(
              labelText: 'Condition or problem',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Currently relevant'),
            value: _current,
            onChanged: (bool value) => setState(() => _current = value),
          ),
          ApproximateDateFields(
            label: 'Age or date of onset if known',
            value: _onset,
            onChanged: (ApproximateDate value) =>
                setState(() => _onset = value),
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
    if (_relationship.text.trim().isEmpty && _condition.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a relationship or condition.')),
      );
      return;
    }
    if (showIncompleteDateSnack(context, _onset, 'onset')) return;
    setState(() => _saving = true);
    final String id =
        widget.existing?.id ??
        ref.read(familyHistoryRepositoryProvider).newId(user.uid);
    try {
      await ref
          .read(familyHistoryRepositoryProvider)
          .upsert(
            user.uid,
            id,
            FamilyHistoryRecord(
              id: id,
              relationship: _relationship.text.trim(),
              condition: _condition.text.trim(),
              onset: _onset,
              isCurrent: _current,
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
