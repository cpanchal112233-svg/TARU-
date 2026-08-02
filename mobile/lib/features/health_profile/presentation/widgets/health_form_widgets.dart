import 'package:flutter/material.dart';

/// Small uppercase heading that keeps long health lists navigable.
class HealthSectionLabel extends StatelessWidget {
  const HealthSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Explains why a health form asks for something, so it does not feel like
/// data collection for its own sake.
class HealthNote extends StatelessWidget {
  const HealthNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.blueGrey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets someone say "none of these apply to me".
///
/// Without it, an empty list is ambiguous: it could mean nothing to report, or
/// simply never answered, and those two lead to different advice. The toggle
/// locks while items are listed, since the two answers contradict each other.
class HealthNoneKnownTile extends StatelessWidget {
  const HealthNoneKnownTile({
    super.key,
    required this.title,
    required this.lockedHint,
    required this.value,
    required this.canToggle,
    required this.onChanged,
  });

  final String title;

  /// Shown instead of the usual prompt when the toggle is locked.
  final String lockedHint;

  final bool value;
  final bool canToggle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: SwitchListTile(
        value: value,
        onChanged: canToggle ? onChanged : null,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          canToggle
              ? 'Tell us either way, so TARU knows you were asked.'
              : lockedHint,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class HealthSaveBar extends StatelessWidget {
  const HealthSaveBar({
    super.key,
    required this.onSave,
    required this.isSaving,
    required this.hasChanges,
    required this.label,
  });

  final VoidCallback? onSave;
  final bool isSaving;
  final bool hasChanges;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: FilledButton(
          onPressed: onSave,
          child: Text(
            isSaving
                ? 'Saving...'
                : hasChanges
                ? label
                : 'Saved',
          ),
        ),
      ),
    );
  }
}

/// Asks before throwing away medical details someone just entered.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  required String message,
}) async {
  final bool? shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Discard changes?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );

  return shouldDiscard ?? false;
}
