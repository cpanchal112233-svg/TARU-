import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/health_context_providers.dart';
import '../../domain/care_team_member.dart';
import '../widgets/health_context_record_list.dart';

class CareTeamScreen extends ConsumerWidget {
  const CareTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HealthContextRecordList<CareTeamMember>(
      title: 'Care team',
      emptyLabel:
          'No care-team contacts recorded. TARU does not message clinicians or sync your phone contacts.',
      async: ref.watch(careTeamProvider),
      itemTitle: (CareTeamMember item) => item.name.isEmpty
          ? (item.role.isEmpty ? 'Care contact' : item.role)
          : item.name,
      itemSubtitle: (CareTeamMember item) => <String>[
        item.role,
        item.organisation,
      ].where((String p) => p.isNotEmpty).join(' · '),
      onAdd: () => _open(context, null),
      onOpen: (CareTeamMember item) => _open(context, item),
      onDelete: (CareTeamMember item) async {
        final bool ok = await confirmHealthContextDelete(
          context,
          title: 'Delete this care-team contact?',
          body:
              'Removes this reference from TARU. TARU does not notify anyone.',
        );
        if (!ok) return;
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await ref.read(careTeamRepositoryProvider).delete(user.uid, item.id);
      },
    );
  }

  void _open(BuildContext context, CareTeamMember? existing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CareTeamEditor(existing: existing),
      ),
    );
  }
}

class _CareTeamEditor extends ConsumerStatefulWidget {
  const _CareTeamEditor({this.existing});

  final CareTeamMember? existing;

  @override
  ConsumerState<_CareTeamEditor> createState() => _CareTeamEditorState();
}

class _CareTeamEditorState extends ConsumerState<_CareTeamEditor> {
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _organisation;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _role = TextEditingController(text: widget.existing?.role ?? '');
    _organisation = TextEditingController(
      text: widget.existing?.organisation ?? '',
    );
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _organisation.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Care-team contact'),
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
            'For your reference only. TARU does not contact this person.',
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _role,
            decoration: const InputDecoration(labelText: 'Role or specialty'),
          ),
          TextField(
            controller: _organisation,
            decoration: const InputDecoration(
              labelText: 'Clinic or organisation',
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
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
    final CareTeamMember member = CareTeamMember(
      id:
          widget.existing?.id ??
          ref.read(careTeamRepositoryProvider).newId(user.uid),
      name: _name.text.trim(),
      role: _role.text.trim(),
      organisation: _organisation.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      notes: _notes.text.trim(),
      recordedAt: widget.existing?.recordedAt,
      updatedAt: widget.existing?.updatedAt,
    ).stamped(now: DateTime.now().toUtc());
    if (!member.hasContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one field.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(careTeamRepositoryProvider)
          .upsert(user.uid, member.id, member);
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
