import 'package:flutter/material.dart';

import '../../domain/approximate_date.dart';

/// Explicit date-precision picker. Unknown is a real choice.
class ApproximateDateFields extends StatelessWidget {
  const ApproximateDateFields({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ApproximateDate value;
  final ValueChanged<ApproximateDate> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final DatePrecision precision in DatePrecision.values)
              ChoiceChip(
                label: Text(_precisionLabel(precision)),
                selected: value.precision == precision,
                onSelected: (bool selected) {
                  if (!selected) return;
                  onChanged(
                    ApproximateDate(
                      precision: precision,
                      year: precision == DatePrecision.unknown
                          ? null
                          : value.year,
                      month:
                          precision == DatePrecision.exact ||
                              precision == DatePrecision.monthYear
                          ? value.month
                          : null,
                      day: precision == DatePrecision.exact ? value.day : null,
                    ),
                  );
                },
              ),
          ],
        ),
        if (value.precision != DatePrecision.unknown) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  initialValue: value.year?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year'),
                  onChanged: (String raw) {
                    onChanged(
                      ApproximateDate(
                        precision: value.precision,
                        year: int.tryParse(raw),
                        month: value.month,
                        day: value.day,
                      ),
                    );
                  },
                ),
              ),
              if (value.precision == DatePrecision.monthYear ||
                  value.precision == DatePrecision.exact) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: value.month?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Month'),
                    onChanged: (String raw) {
                      onChanged(
                        ApproximateDate(
                          precision: value.precision,
                          year: value.year,
                          month: int.tryParse(raw),
                          day: value.day,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (value.precision == DatePrecision.exact) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: value.day?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Day'),
                    onChanged: (String raw) {
                      onChanged(
                        ApproximateDate(
                          precision: value.precision,
                          year: value.year,
                          month: value.month,
                          day: int.tryParse(raw),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 4),
        Text(
          value.displayLabel,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ],
    );
  }

  static String _precisionLabel(DatePrecision precision) {
    switch (precision) {
      case DatePrecision.exact:
        return 'Exact date';
      case DatePrecision.monthYear:
        return 'Month and year';
      case DatePrecision.year:
        return 'Year';
      case DatePrecision.unknown:
        return 'Unknown';
    }
  }
}

String? incompleteApproximateDateMessage(
  ApproximateDate value,
  String fieldLabel,
) {
  if (value.isUnknown || value.isValid) return null;
  return 'Finish $fieldLabel or choose Unknown. TARU will not invent a calendar date.';
}

bool showIncompleteDateSnack(
  BuildContext context,
  ApproximateDate value,
  String fieldLabel,
) {
  final String? message = incompleteApproximateDateMessage(value, fieldLabel);
  if (message == null) return false;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  return true;
}
