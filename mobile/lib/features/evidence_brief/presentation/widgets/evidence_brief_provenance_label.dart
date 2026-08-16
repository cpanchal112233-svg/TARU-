import 'package:flutter/material.dart';

import '../../domain/evidence_brief_provenance.dart';

/// Text provenance label — never color-only.
class EvidenceBriefProvenanceLabel extends StatelessWidget {
  const EvidenceBriefProvenanceLabel({super.key, required this.provenance});

  final EvidenceProvenance provenance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Source: ${provenance.label}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xffF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffCBD5E1)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            provenance.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}
