import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reliability/user_facing_error.dart';

class HealthContextRecordList<T> extends StatelessWidget {
  const HealthContextRecordList({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.async,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  final String title;
  final String emptyLabel;
  final AsyncValue<List<T>> async;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final VoidCallback onAdd;
  final ValueChanged<T> onOpen;
  final ValueChanged<T> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        tooltip: 'Add $title',
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(userFacingErrorMessage(error)),
          ),
        ),
        data: (List<T> items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  emptyLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final T item = items[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  title: Text(itemTitle(item)),
                  subtitle: Text(itemSubtitle(item)),
                  onTap: () => onOpen(item),
                  trailing: IconButton(
                    tooltip: 'Delete ${itemTitle(item)}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<bool> confirmHealthContextDelete(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete record'),
          ),
        ],
      );
    },
  );
  return ok == true;
}
