import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/health_context_providers.dart';
import '../../domain/health_goal_record.dart';
import '../widgets/health_context_record_list.dart';

class HealthGoalsScreen extends ConsumerWidget {
  const HealthGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HealthContextRecordList<HealthGoalRecord>(
      title: 'Health goals',
      emptyLabel:
          'No goals recorded. A target date is your aim, not a predicted recovery date.',
      async: ref.watch(healthGoalsProvider),
      itemTitle: (HealthGoalRecord item) => item.title,
      itemSubtitle: (HealthGoalRecord item) {
        final String status = item.status.name;
        if (item.desiredBy == null) return status;
        return '$status · desired by ${item.desiredBy!.toLocal().toIso8601String().split('T').first} (user target)';
      },
      onAdd: () => _open(context, null),
      onOpen: (HealthGoalRecord item) => _open(context, item),
      onDelete: (HealthGoalRecord item) async {
        final bool ok = await confirmHealthContextDelete(
          context,
          title: 'Delete this goal?',
          body:
              'Removes “${item.title}” from TARU. TARU does not judge whether a goal is achievable.',
        );
        if (!ok) return;
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await ref.read(healthGoalRepositoryProvider).delete(user.uid, item.id);
      },
    );
  }

  void _open(BuildContext context, HealthGoalRecord? existing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _GoalEditor(existing: existing)),
    );
  }
}

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.existing});

  final HealthGoalRecord? existing;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _notes;
  late HealthGoalArea _area;
  late HealthGoalStatus _status;
  DateTime? _desiredBy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _description = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _area = widget.existing?.area ?? HealthGoalArea.other;
    _status = widget.existing?.status ?? HealthGoalStatus.active;
    _desiredBy = widget.existing?.desiredBy;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Health goal'),
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
            'A “desired by” date is your own target. It is not a predicted recovery date, cure date, or medical promise.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          DropdownButtonFormField<HealthGoalArea>(
            initialValue: _area,
            decoration: const InputDecoration(labelText: 'Goal area'),
            items: <DropdownMenuItem<HealthGoalArea>>[
              for (final HealthGoalArea area in HealthGoalArea.values)
                DropdownMenuItem<HealthGoalArea>(
                  value: area,
                  child: Text(healthGoalAreaLabel(area)),
                ),
            ],
            onChanged: (HealthGoalArea? value) {
              if (value != null) setState(() => _area = value);
            },
          ),
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            maxLines: 3,
          ),
          DropdownButtonFormField<HealthGoalStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const <DropdownMenuItem<HealthGoalStatus>>[
              DropdownMenuItem<HealthGoalStatus>(
                value: HealthGoalStatus.active,
                child: Text('Active'),
              ),
              DropdownMenuItem<HealthGoalStatus>(
                value: HealthGoalStatus.paused,
                child: Text('Paused'),
              ),
              DropdownMenuItem<HealthGoalStatus>(
                value: HealthGoalStatus.completed,
                child: Text('Completed'),
              ),
            ],
            onChanged: (HealthGoalStatus? value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Desired by (user target date)'),
            subtitle: Text(
              _desiredBy == null
                  ? 'Not set'
                  : _desiredBy!.toLocal().toIso8601String().split('T').first,
            ),
            trailing: TextButton(
              onPressed: () async {
                final DateTime now = DateTime.now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _desiredBy ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 20),
                );
                if (picked != null) setState(() => _desiredBy = picked);
              },
              child: const Text('Choose'),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _desiredBy = null),
            child: const Text('Clear target date'),
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
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a title.')));
      return;
    }
    setState(() => _saving = true);
    final String id =
        widget.existing?.id ??
        ref.read(healthGoalRepositoryProvider).newId(user.uid);
    try {
      await ref
          .read(healthGoalRepositoryProvider)
          .upsert(
            user.uid,
            id,
            HealthGoalRecord(
              id: id,
              title: _title.text.trim(),
              area: _area,
              description: _description.text.trim(),
              recordedAt: widget.existing?.recordedAt,
              updatedAt: widget.existing?.updatedAt,
              desiredBy: _desiredBy,
              status: _status,
              notes: _notes.text.trim(),
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
