import 'package:flutter/material.dart';

import '../../domain/evidence_brief_period.dart';
import '../../domain/evidence_brief_provenance.dart';
import 'evidence_brief_provenance_label.dart';

class EvidenceBriefSectionCard extends StatelessWidget {
  const EvidenceBriefSectionCard({
    super.key,
    required this.title,
    required this.provenance,
    required this.child,
    this.semanticsIdentifier,
  });

  final String title;
  final EvidenceProvenance provenance;
  final Widget child;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      identifier: semanticsIdentifier,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            EvidenceBriefProvenanceLabel(provenance: provenance),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class EvidenceBriefPeriodPicker extends StatelessWidget {
  const EvidenceBriefPeriodPicker({
    super.key,
    required this.period,
    required this.onPresetSelected,
    required this.onCustomPressed,
  });

  final EvidenceBriefPeriod period;
  final ValueChanged<EvidenceBriefPeriodPreset> onPresetSelected;
  final VoidCallback onCustomPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PeriodChip(
              label: 'Last 7 days',
              selected: period.preset == EvidenceBriefPeriodPreset.last7,
              onTap: () => onPresetSelected(EvidenceBriefPeriodPreset.last7),
            ),
            _PeriodChip(
              label: 'Last 30 days',
              selected: period.preset == EvidenceBriefPeriodPreset.last30,
              onTap: () => onPresetSelected(EvidenceBriefPeriodPreset.last30),
            ),
            _PeriodChip(
              label: 'Last 90 days',
              selected: period.preset == EvidenceBriefPeriodPreset.last90,
              onTap: () => onPresetSelected(EvidenceBriefPeriodPreset.last90),
            ),
            _PeriodChip(
              label: period.preset == EvidenceBriefPeriodPreset.custom
                  ? period.label
                  : 'Custom range',
              selected: period.preset == EvidenceBriefPeriodPreset.custom,
              onTap: onCustomPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Material(
          color: selected ? const Color(0xff2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xff2563EB)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
