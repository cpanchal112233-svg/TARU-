import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/health_context_providers.dart';
import '../../domain/approximate_date.dart';
import '../../domain/immunization_record.dart';
import '../widgets/approximate_date_fields.dart';
import '../widgets/health_context_record_list.dart';

class ImmunizationsScreen extends ConsumerWidget {
  const ImmunizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HealthContextRecordList<ImmunizationRecord>(
      title: 'Vaccinations',
      emptyLabel:
          'No vaccinations recorded. TARU does not recommend or infer missing doses.',
      async: ref.watch(immunizationsProvider),
      itemTitle: (ImmunizationRecord item) => item.vaccine,
      itemSubtitle: (ImmunizationRecord item) => item.givenOn.displayLabel,
      onAdd: () => _open(context, null),
      onOpen: (ImmunizationRecord item) => _open(context, item),
      onDelete: (ImmunizationRecord item) async {
        final bool ok = await confirmHealthContextDelete(
          context,
          title: 'Delete this vaccination record?',
          body: 'Removes ${item.vaccine} from your TARU records.',
        );
        if (!ok) return;
        final User? user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await ref
            .read(immunizationRepositoryProvider)
            .delete(user.uid, item.id);
      },
    );
  }

  void _open(BuildContext context, ImmunizationRecord? existing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ImmunizationEditor(existing: existing),
      ),
    );
  }
}

class _ImmunizationEditor extends ConsumerStatefulWidget {
  const _ImmunizationEditor({this.existing});

  final ImmunizationRecord? existing;

  @override
  ConsumerState<_ImmunizationEditor> createState() =>
      _ImmunizationEditorState();
}

class _ImmunizationEditorState extends ConsumerState<_ImmunizationEditor> {
  late final TextEditingController _vaccine;
  late final TextEditingController _dose;
  late final TextEditingController _notes;
  late ApproximateDate _givenOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _vaccine = TextEditingController(text: widget.existing?.vaccine ?? '');
    _dose = TextEditingController(text: widget.existing?.doseDescription ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _givenOn = widget.existing?.givenOn ?? ApproximateDate.unknown;
  }

  @override
  void dispose() {
    _vaccine.dispose();
    _dose.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Vaccination'),
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
            controller: _vaccine,
            decoration: const InputDecoration(labelText: 'Vaccine'),
          ),
          TextField(
            controller: _dose,
            decoration: const InputDecoration(
              labelText: 'Dose number or description (optional)',
            ),
          ),
          ApproximateDateFields(
            label: 'When',
            value: _givenOn,
            onChanged: (ApproximateDate value) =>
                setState(() => _givenOn = value),
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
    if (_vaccine.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a vaccine name.')));
      return;
    }
    if (showIncompleteDateSnack(context, _givenOn, 'vaccination date')) return;
    setState(() => _saving = true);
    final String id =
        widget.existing?.id ??
        ref.read(immunizationRepositoryProvider).newId(user.uid);
    try {
      await ref
          .read(immunizationRepositoryProvider)
          .upsert(
            user.uid,
            id,
            ImmunizationRecord(
              id: id,
              vaccine: _vaccine.text.trim(),
              doseDescription: _dose.text.trim(),
              givenOn: _givenOn,
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
