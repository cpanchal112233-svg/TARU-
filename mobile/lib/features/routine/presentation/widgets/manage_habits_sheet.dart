import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/habit_providers.dart';
import '../../domain/habit.dart';
import 'habit_section.dart';

/// Lets the user turn catalog habits on or off. Custom habits are out of scope.
Future<void> showManageHabitsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) => const _ManageHabitsSheet(),
  );
}

class _ManageHabitsSheet extends ConsumerWidget {
  const _ManageHabitsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HabitPreferences prefs =
        ref.watch(habitPreferencesProvider).value ?? HabitPreferences.allEnabled;
    final MediaQueryData media = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + media.viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              'Your lifestyle habits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Turn off anything that does not fit your day. Off habits leave '
              'today\'s progress alone.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.55,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final HabitPillar pillar in HabitPillar.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            habitPillarIcon(pillar),
                            size: 16,
                            color: habitPillarColor(pillar),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            pillar.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final HabitItem habit in habitsFor(pillar))
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: prefs.isEnabled(habit.id),
                        onChanged: (bool value) => ref.read(
                          setHabitEnabledProvider,
                        )(habit.id, value),
                        title: Text(
                          habit.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          habit.detail,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
