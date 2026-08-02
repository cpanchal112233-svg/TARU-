import 'package:flutter/material.dart';

import '../../domain/medicine_checker.dart';
import '../../domain/medicine_warning.dart';

/// Colour and icon per severity, in one place so the medications list, the
/// editor and the safety screen cannot disagree about what "serious" looks
/// like.
class MedicineWarningStyle {
  const MedicineWarningStyle({
    required this.colour,
    required this.icon,
    required this.tint,
  });

  final Color colour;
  final IconData icon;
  final Color tint;

  static MedicineWarningStyle of(MedicineWarningSeverity severity) {
    return switch (severity) {
      MedicineWarningSeverity.serious => const MedicineWarningStyle(
        colour: Color(0xffB3261E),
        icon: Icons.warning_amber_rounded,
        tint: Color(0xffFDECEA),
      ),
      MedicineWarningSeverity.caution => const MedicineWarningStyle(
        colour: Color(0xffC2410C),
        icon: Icons.info_outline,
        tint: Color(0xffFEF3E7),
      ),
      MedicineWarningSeverity.timing => const MedicineWarningStyle(
        colour: Color(0xff1D4ED8),
        icon: Icons.schedule_outlined,
        tint: Color(0xffEAF1FE),
      ),
    };
  }
}

/// One warning, collapsed to a headline until someone wants the reasoning.
///
/// The medicine names and the action are always visible; the explanation is
/// behind a tap. Someone scanning for "is this a problem" gets an answer
/// without reading three paragraphs, and someone who wants the why can have it.
class MedicineWarningTile extends StatelessWidget {
  const MedicineWarningTile({
    super.key,
    required this.warning,
    this.initiallyExpanded = false,
  });

  final MedicineWarning warning;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final MedicineWarningStyle style = MedicineWarningStyle.of(
      warning.severity,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.colour.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent, splashColor: style.tint),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          backgroundColor: style.tint.withValues(alpha: 0.45),
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
          childrenPadding: const EdgeInsets.fromLTRB(48, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(style.icon, color: style.colour),
          title: Text(
            warning.title,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: style.colour,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              warning.medicineNames,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
          children: [
            Text(
              warning.detail,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: style.colour,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning.action,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: style.colour,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The warnings for a list of medicines, with a one-line summary above them.
class MedicineWarningsPanel extends StatelessWidget {
  const MedicineWarningsPanel({
    super.key,
    required this.warnings,
    this.emptyMessage,
  });

  final List<MedicineWarning> warnings;

  /// Shown instead of the list when nothing fired. Null hides the panel
  /// entirely, which is what the editor wants.
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      final String? message = emptyMessage;

      if (message == null) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffECFDF3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xff15803D).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              color: Color(0xff15803D),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xff14532D),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicineWarningSummaryLine(warnings: warnings),
        const SizedBox(height: 10),
        for (final MedicineWarning warning in warnings)
          MedicineWarningTile(
            warning: warning,
            initiallyExpanded:
                warnings.length == 1 ||
                warning.severity == MedicineWarningSeverity.serious,
          ),
      ],
    );
  }
}

/// "1 to speak to a doctor about, 2 worth checking" — the shape of the list
/// before you read it.
class MedicineWarningSummaryLine extends StatelessWidget {
  const MedicineWarningSummaryLine({super.key, required this.warnings});

  final List<MedicineWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[
      for (final MedicineWarningSeverity severity
          in MedicineWarningSeverity.values.reversed)
        if (warnings.countOf(severity) > 0)
          '${warnings.countOf(severity)} ${severity.countPhrase}',
    ];

    return Text(
      parts.join('  •  '),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}

/// The line that keeps TARU honest about what these checks are.
class MedicineSafetyDisclaimer extends StatelessWidget {
  const MedicineSafetyDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'These checks cover common, well known interactions — they are not '
            'the whole of pharmacology, and a missing warning does not mean a '
            'combination is safe. Never stop a prescribed medicine because of '
            'this screen; take it to your doctor or pharmacist instead.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
