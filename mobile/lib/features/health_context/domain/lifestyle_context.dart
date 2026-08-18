import 'health_record_audit.dart';
import 'record_provenance.dart';

enum TypicalActivityLevel { sedentary, light, moderate, vigorous }

enum SubstanceUsePattern { never, former, current }

/// Generally-true lifestyle context. Separate from Routine daily logs.
///
/// Missing fields mean not recorded — never "healthy" or "none".
/// [recordedAt] / [updatedAt] are TARU record times, not a lifestyle history.
class LifestyleContext {
  const LifestyleContext({
    this.usualSleepHours,
    this.usualSleepWindow = '',
    this.activityLevel,
    this.occupationActivity = '',
    this.tobaccoUse,
    this.alcoholUse,
    this.caffeineUse,
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  static const LifestyleContext empty = LifestyleContext();

  final double? usualSleepHours;
  final String usualSleepWindow;
  final TypicalActivityLevel? activityLevel;
  final String occupationActivity;
  final SubstanceUsePattern? tobaccoUse;
  final SubstanceUsePattern? alcoholUse;
  final SubstanceUsePattern? caffeineUse;
  final String notes;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  bool get isRecorded =>
      usualSleepHours != null ||
      usualSleepWindow.trim().isNotEmpty ||
      activityLevel != null ||
      occupationActivity.trim().isNotEmpty ||
      tobaccoUse != null ||
      alcoholUse != null ||
      caffeineUse != null ||
      notes.trim().isNotEmpty;

  LifestyleContext copyWith({
    double? usualSleepHours,
    String? usualSleepWindow,
    TypicalActivityLevel? activityLevel,
    String? occupationActivity,
    SubstanceUsePattern? tobaccoUse,
    SubstanceUsePattern? alcoholUse,
    SubstanceUsePattern? caffeineUse,
    String? notes,
    RecordProvenance? provenance,
    DateTime? recordedAt,
    DateTime? updatedAt,
    bool clearTobacco = false,
    bool clearAlcohol = false,
    bool clearCaffeine = false,
  }) {
    return LifestyleContext(
      usualSleepHours: usualSleepHours ?? this.usualSleepHours,
      usualSleepWindow: usualSleepWindow ?? this.usualSleepWindow,
      activityLevel: activityLevel ?? this.activityLevel,
      occupationActivity: occupationActivity ?? this.occupationActivity,
      tobaccoUse: clearTobacco ? null : (tobaccoUse ?? this.tobaccoUse),
      alcoholUse: clearAlcohol ? null : (alcoholUse ?? this.alcoholUse),
      caffeineUse: clearCaffeine ? null : (caffeineUse ?? this.caffeineUse),
      notes: notes ?? this.notes,
      provenance: provenance ?? this.provenance,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  LifestyleContext stamped({
    required DateTime now,
    DateTime? previousRecordedAt,
  }) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt ?? previousRecordedAt,
      provenance: provenance,
    );
    return LifestyleContext(
      usualSleepHours: usualSleepHours,
      usualSleepWindow: usualSleepWindow,
      activityLevel: activityLevel,
      occupationActivity: occupationActivity,
      tobaccoUse: tobaccoUse,
      alcoholUse: alcoholUse,
      caffeineUse: caffeineUse,
      notes: notes,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (usualSleepHours != null) 'usualSleepHours': usualSleepHours,
      'usualSleepWindow': usualSleepWindow,
      if (activityLevel != null) 'activityLevel': activityLevel!.name,
      'occupationActivity': occupationActivity,
      if (tobaccoUse != null) 'tobaccoUse': tobaccoUse!.name,
      if (alcoholUse != null) 'alcoholUse': alcoholUse!.name,
      if (caffeineUse != null) 'caffeineUse': caffeineUse!.name,
      'notes': notes,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static LifestyleContext fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return LifestyleContext.empty;
    return LifestyleContext(
      usualSleepHours: (data['usualSleepHours'] as num?)?.toDouble(),
      usualSleepWindow: (data['usualSleepWindow'] as String?) ?? '',
      activityLevel: _enum<TypicalActivityLevel>(
        data['activityLevel'] as String?,
        TypicalActivityLevel.values,
      ),
      occupationActivity: (data['occupationActivity'] as String?) ?? '',
      tobaccoUse: _enum<SubstanceUsePattern>(
        data['tobaccoUse'] as String?,
        SubstanceUsePattern.values,
      ),
      alcoholUse: _enum<SubstanceUsePattern>(
        data['alcoholUse'] as String?,
        SubstanceUsePattern.values,
      ),
      caffeineUse: _enum<SubstanceUsePattern>(
        data['caffeineUse'] as String?,
        SubstanceUsePattern.values,
      ),
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
  }

  static T? _enum<T extends Enum>(String? raw, List<T> values) {
    if (raw == null) return null;
    for (final T value in values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

String activityLevelLabel(TypicalActivityLevel level) {
  switch (level) {
    case TypicalActivityLevel.sedentary:
      return 'Mostly sitting';
    case TypicalActivityLevel.light:
      return 'Light activity';
    case TypicalActivityLevel.moderate:
      return 'Moderate activity';
    case TypicalActivityLevel.vigorous:
      return 'Vigorous activity';
  }
}

String substanceUseLabel(SubstanceUsePattern pattern) {
  switch (pattern) {
    case SubstanceUsePattern.never:
      return 'Never';
    case SubstanceUsePattern.former:
      return 'Former';
    case SubstanceUsePattern.current:
      return 'Current';
  }
}
