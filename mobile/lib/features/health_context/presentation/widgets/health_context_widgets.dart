import 'package:flutter/material.dart';

class HealthContextTile extends StatelessWidget {
  const HealthContextTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommaSeparatedField extends StatelessWidget {
  const CommaSeparatedField({
    super.key,
    required this.label,
    required this.helper,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String helper;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: values.join(', '),
      decoration: InputDecoration(labelText: label, helperText: helper),
      minLines: 1,
      maxLines: 3,
      onChanged: (String raw) {
        onChanged(
          raw
              .split(',')
              .map((String part) => part.trim())
              .where((String part) => part.isNotEmpty)
              .toList(),
        );
      },
    );
  }
}
