import '../../measurements/domain/blood_pressure_measurement.dart';
import '../../measurements/domain/weight_measurement.dart';
import '../../reports/domain/medical_report.dart';
import '../../routine/domain/dose_schedule.dart';
import '../../routine/domain/habit.dart';
import 'evidence_brief.dart';
import 'evidence_brief_period.dart';
import 'evidence_brief_provenance.dart';
import 'evidence_brief_sections.dart';

/// Builds shareable plain text for Evidence Brief V1.
///
/// Single canonical formatter for on-screen preview and the share sheet.
/// Client-side only — never uploads, emails, or logs PHI.
String formatEvidenceBriefText(
  EvidenceBrief brief, {
  EvidenceBriefShareSelection? selection,
  DateTime? createdAt,
}) {
  final EvidenceBriefShareSelection selected =
      selection ?? EvidenceBriefShareSelection.defaultsFor(brief);
  final DateTime created = createdAt ?? brief.createdAt ?? DateTime.now();

  final StringBuffer buffer = StringBuffer()
    ..writeln('TARU Evidence Brief')
    ..writeln()
    ..writeln('Period: ${brief.period.label}')
    ..writeln('Created: ${_formatDay(created)}')
    ..writeln()
    ..writeln('Sources in this brief')
    ..writeln(_sourcesLines(brief, selected))
    ..writeln()
    ..writeln(
      'Contains information recorded in TARU. '
      'Not a certified medical record.',
    )
    ..writeln();

  if (selected.currentContext) {
    _writeContext(buffer, brief.context);
  }
  if (selected.measurements) {
    _writeMeasurements(buffer, brief.measurements, brief.period);
  }
  if (selected.reports) {
    _writeReports(buffer, brief.reports);
  }
  if (selected.medicineRoutine || selected.lifestyleRoutine) {
    _writeRoutine(
      buffer,
      brief.routine,
      includeMedicine: selected.medicineRoutine,
      includeLifestyle: selected.lifestyleRoutine,
    );
  }
  if (selected.notes) {
    _writeNotes(buffer, brief.notes);
  }

  return buffer.toString().trimRight();
}

String _sourcesLines(
  EvidenceBrief brief,
  EvidenceBriefShareSelection selected,
) {
  final List<String> lines = <String>[];
  if (selected.currentContext &&
      brief.contextLoad.isShareable &&
      (brief.context.hasAnyAnswer || !brief.context.isEmpty)) {
    lines.add('- Current self-reported context');
  }
  if (selected.measurements && brief.measurementsLoad.isShareable) {
    final int weights = brief.measurements.weights.length;
    final int bps = brief.measurements.bloodPressures.length;
    if (weights > 0) {
      lines.add('- $weights weight ${weights == 1 ? 'reading' : 'readings'}');
    }
    if (bps > 0) {
      lines.add('- $bps blood-pressure ${bps == 1 ? 'reading' : 'readings'}');
    }
  }
  if (selected.reports &&
      brief.reportsLoad.isShareable &&
      brief.reports.reports.isNotEmpty) {
    final int n = brief.reports.reports.length;
    lines.add('- $n report ${n == 1 ? 'record' : 'records'}');
  }
  if (selected.medicineRoutine &&
      brief.medicineLoad.isShareable &&
      brief.routine.medicineDaysWithRecords > 0) {
    final int n = brief.routine.medicineDaysWithRecords;
    lines.add('- Medicine logs on $n ${n == 1 ? 'day' : 'days'}');
  }
  if (selected.lifestyleRoutine &&
      brief.lifestyleLoad.isShareable &&
      brief.routine.lifestyleDaysWithRecords > 0) {
    final int n = brief.routine.lifestyleDaysWithRecords;
    lines.add('- Lifestyle logs on $n ${n == 1 ? 'day' : 'days'}');
  }
  if (selected.notes && brief.notes.trim().isNotEmpty) {
    lines.add('- Personal notes/questions');
  }
  if (lines.isEmpty) {
    return '- No sections with recorded information selected';
  }
  return lines.join('\n');
}

void _writeContext(StringBuffer buffer, EvidenceBriefContextSection section) {
  buffer
    ..writeln('CURRENT SELF-REPORTED CONTEXT')
    ..writeln(
      'Source: ${EvidenceProvenance.selfReported.label} — '
      'current as of ${_formatDay(section.asOf)}',
    )
    ..writeln()
    ..writeln(section.asOfLabel)
    ..writeln();

  buffer.writeln('Conditions');
  if (!section.conditionsAnswered) {
    buffer.writeln('- Not recorded');
  } else if (section.noKnownConditions) {
    buffer.writeln('- None reported');
  } else if (section.conditions.isEmpty) {
    buffer.writeln('- None listed');
  } else {
    for (final EvidenceBriefContextItem item in section.conditions) {
      buffer.writeln(_bullet(item.label, item.detail));
    }
  }
  buffer.writeln();

  buffer.writeln('Allergies');
  if (!section.allergiesAnswered) {
    buffer.writeln('- Not recorded');
  } else if (section.noKnownAllergies) {
    buffer.writeln('- No known allergies');
  } else if (section.allergies.isEmpty) {
    buffer.writeln('- None listed');
  } else {
    for (final EvidenceBriefContextItem item in section.allergies) {
      buffer.writeln(_bullet(item.label, item.detail));
    }
  }
  buffer.writeln();

  buffer.writeln('Current medicines');
  if (!section.medicinesAnswered) {
    buffer.writeln('- Not recorded');
  } else if (section.takesNoMedication) {
    buffer.writeln('- None');
  } else if (section.medicines.isEmpty) {
    buffer.writeln('- None listed');
  } else {
    for (final EvidenceBriefContextItem item in section.medicines) {
      buffer.writeln(_bullet(item.label, item.detail));
    }
  }
  buffer.writeln();
}

void _writeMeasurements(
  StringBuffer buffer,
  EvidenceBriefMeasurementsSection section,
  EvidenceBriefPeriod period,
) {
  buffer
    ..writeln('MEASUREMENTS')
    ..writeln('Source: ${EvidenceProvenance.manualMeasurement.label}')
    ..writeln('Period: ${period.label}')
    ..writeln();

  if (section.isEmpty) {
    buffer
      ..writeln('- No weight or blood pressure recorded in this period')
      ..writeln();
    return;
  }

  if (section.weights.isNotEmpty) {
    buffer.writeln('Weight (${section.weights.length})');
    for (final WeightMeasurement m in section.weights) {
      buffer.writeln(
        '- ${_formatDay(m.recordedAt)}: '
        '${m.valueKg.toStringAsFixed(1)} kg '
        '(${EvidenceProvenance.manualMeasurement.label})',
      );
    }
    buffer.writeln();
  }

  if (section.bloodPressures.isNotEmpty) {
    buffer.writeln('Blood pressure (${section.bloodPressures.length})');
    for (final BloodPressureMeasurement m in section.bloodPressures) {
      buffer.writeln(
        '- ${_formatDay(m.recordedAt)}: '
        '${m.systolicMmHg}/${m.diastolicMmHg} mmHg '
        '(${EvidenceProvenance.manualMeasurement.label})',
      );
    }
    buffer.writeln();
  }
}

void _writeReports(StringBuffer buffer, EvidenceBriefReportsSection section) {
  buffer
    ..writeln('REPORTS')
    ..writeln('Source: ${EvidenceProvenance.reportRecord.label}')
    ..writeln();

  if (section.isEmpty) {
    buffer
      ..writeln('- No reports in this period')
      ..writeln();
    return;
  }

  for (final EvidenceBriefReportItem item in section.reports) {
    final MedicalReport report = item.report;
    buffer.writeln(
      '- ${report.title} · ${report.category.label} · '
      '${item.dateBasisLabel} '
      '(${EvidenceProvenance.reportRecord.label})',
    );
  }
  buffer.writeln();
}

void _writeRoutine(
  StringBuffer buffer,
  EvidenceBriefRoutineSection section, {
  required bool includeMedicine,
  required bool includeLifestyle,
}) {
  if (includeMedicine) {
    buffer
      ..writeln('MEDICINE ROUTINE')
      ..writeln('Source: ${EvidenceProvenance.routineLog.label}')
      ..writeln();

    if (section.noMedicinesConfigured) {
      buffer.writeln('None configured');
    } else if (section.medicine == null || !section.medicine!.hasData) {
      buffer.writeln('No dose logs in this period');
    } else {
      final AdherenceSummary m = section.medicine!;
      buffer.writeln(
        '${m.taken} of about ${m.expected} expected doses logged as taken '
        '(from ${m.daysCovered} '
        '${m.daysCovered == 1 ? 'day' : 'days'} of tracking)',
      );
    }
    buffer.writeln();
  }

  if (includeLifestyle) {
    buffer
      ..writeln('LIFESTYLE ROUTINE')
      ..writeln('Source: ${EvidenceProvenance.routineLog.label}')
      ..writeln();

    if (section.noActiveHabits) {
      buffer.writeln('No enabled habits');
    } else if (section.lifestyle == null || !section.lifestyle!.hasData) {
      buffer.writeln('No habit logs in this period');
    } else {
      final HabitAdherenceSummary l = section.lifestyle!;
      buffer.writeln(
        '${l.done} of ${l.possible} enabled habit ticks logged as done '
        'across ${l.daysCovered} '
        '${l.daysCovered == 1 ? 'day' : 'days'} with a record',
      );
      for (final HabitPillarWeekStat pillar in l.byPillar) {
        buffer.writeln(
          '  · ${pillar.pillar.label}: ${pillar.done}/${pillar.possible}',
        );
      }
    }
    buffer.writeln();
  }

  if (includeMedicine || includeLifestyle) {
    for (final String caveat in section.caveats) {
      buffer.writeln('Note: $caveat');
    }
    buffer.writeln();
  }
}

void _writeNotes(StringBuffer buffer, String notes) {
  final String trimmed = notes.trim();
  if (trimmed.isEmpty) return;
  buffer
    ..writeln('NOTES / QUESTIONS')
    ..writeln('User-written')
    ..writeln()
    ..writeln(trimmed)
    ..writeln();
}

String _bullet(String label, String? detail) {
  if (detail == null || detail.trim().isEmpty) {
    return '- $label (${EvidenceProvenance.selfReported.label})';
  }
  return '- $label — $detail (${EvidenceProvenance.selfReported.label})';
}

String _formatDay(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
