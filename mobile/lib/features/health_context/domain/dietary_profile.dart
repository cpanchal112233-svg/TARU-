import 'health_record_audit.dart';
import 'record_provenance.dart';

/// Core dietary pattern. Independent of allergy, religion, location, or name.
enum DietaryPattern {
  vegan,
  vegetarian,
  eggetarian,
  pescatarian,
  nonVegetarian,
  custom,
}

/// Product semantics for [DietaryPattern].
///
/// Vegetarian: no meat, no fish, no eggs.
/// Eggetarian: vegetarian foods plus eggs; no meat or fish.
/// Non-vegetarian: animal-food options may be used subject to explicit
/// restrictions.
/// Vegan: no animal-derived foods.
/// Pescatarian: fish allowed; no meat; eggs allowed unless restricted.
/// Custom: governed by explicit restriction lists, not inferred.
class DietarySemantics {
  const DietarySemantics._();

  static bool allowsMeat(DietaryPattern pattern) {
    switch (pattern) {
      case DietaryPattern.nonVegetarian:
      case DietaryPattern.custom:
        return true;
      case DietaryPattern.vegan:
      case DietaryPattern.vegetarian:
      case DietaryPattern.eggetarian:
      case DietaryPattern.pescatarian:
        return false;
    }
  }

  static bool allowsFish(DietaryPattern pattern) {
    switch (pattern) {
      case DietaryPattern.pescatarian:
      case DietaryPattern.nonVegetarian:
      case DietaryPattern.custom:
        return true;
      case DietaryPattern.vegan:
      case DietaryPattern.vegetarian:
      case DietaryPattern.eggetarian:
        return false;
    }
  }

  static bool allowsEggs(DietaryPattern pattern) {
    switch (pattern) {
      case DietaryPattern.eggetarian:
      case DietaryPattern.pescatarian:
      case DietaryPattern.nonVegetarian:
      case DietaryPattern.custom:
        return true;
      case DietaryPattern.vegan:
      case DietaryPattern.vegetarian:
        return false;
    }
  }

  static bool allowsAnimalDerivedFoods(DietaryPattern pattern) {
    return pattern != DietaryPattern.vegan;
  }

  static String label(DietaryPattern pattern) {
    switch (pattern) {
      case DietaryPattern.vegan:
        return 'Vegan';
      case DietaryPattern.vegetarian:
        return 'Vegetarian';
      case DietaryPattern.eggetarian:
        return 'Eggetarian';
      case DietaryPattern.pescatarian:
        return 'Pescatarian';
      case DietaryPattern.nonVegetarian:
        return 'Non-vegetarian';
      case DietaryPattern.custom:
        return 'Custom';
    }
  }

  static String description(DietaryPattern pattern) {
    switch (pattern) {
      case DietaryPattern.vegan:
        return 'No animal-derived foods.';
      case DietaryPattern.vegetarian:
        return 'No meat, no fish, and no eggs.';
      case DietaryPattern.eggetarian:
        return 'Vegetarian foods plus eggs. No meat or fish.';
      case DietaryPattern.pescatarian:
        return 'Fish allowed. No meat. Eggs allowed unless you list a restriction.';
      case DietaryPattern.nonVegetarian:
        return 'Animal-food options may be used, subject to any restrictions you list.';
      case DietaryPattern.custom:
        return 'Use your own restriction lists. TARU does not infer a pattern.';
    }
  }
}

/// Current dietary snapshot. Not a meal log and not an allergy record.
///
/// [recordedAt] / [updatedAt] are TARU record times for "as of" statements.
/// They are not a dietary history.
class DietaryProfile {
  const DietaryProfile({
    this.pattern,
    this.avoidedFoods = const <String>[],
    this.avoidedIngredients = const <String>[],
    this.dislikedFoods = const <String>[],
    this.culturalConstraints = const <String>[],
    this.notes = '',
    this.provenance = RecordProvenance.selfReported,
    this.recordedAt,
    this.updatedAt,
  });

  static const DietaryProfile empty = DietaryProfile();

  /// Null means not recorded — never treat as "no preference" or "healthy".
  final DietaryPattern? pattern;
  final List<String> avoidedFoods;
  final List<String> avoidedIngredients;
  final List<String> dislikedFoods;

  /// Optional user-entered constraints (for example "no beef", "no onion/garlic",
  /// "Halal preference"). Never inferred from religion or identity.
  final List<String> culturalConstraints;
  final String notes;
  final RecordProvenance provenance;
  final DateTime? recordedAt;
  final DateTime? updatedAt;

  bool get isRecorded =>
      pattern != null ||
      avoidedFoods.isNotEmpty ||
      avoidedIngredients.isNotEmpty ||
      dislikedFoods.isNotEmpty ||
      culturalConstraints.isNotEmpty ||
      notes.trim().isNotEmpty;

  DietaryProfile copyWith({
    DietaryPattern? pattern,
    List<String>? avoidedFoods,
    List<String>? avoidedIngredients,
    List<String>? dislikedFoods,
    List<String>? culturalConstraints,
    String? notes,
    RecordProvenance? provenance,
    DateTime? recordedAt,
    DateTime? updatedAt,
    bool clearPattern = false,
  }) {
    return DietaryProfile(
      pattern: clearPattern ? null : (pattern ?? this.pattern),
      avoidedFoods: avoidedFoods ?? this.avoidedFoods,
      avoidedIngredients: avoidedIngredients ?? this.avoidedIngredients,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      culturalConstraints: culturalConstraints ?? this.culturalConstraints,
      notes: notes ?? this.notes,
      provenance: provenance ?? this.provenance,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  DietaryProfile stamped({
    required DateTime now,
    DateTime? previousRecordedAt,
  }) {
    final HealthRecordAudit audit = stampAudit(
      now: now,
      existingRecordedAt: recordedAt ?? previousRecordedAt,
      provenance: provenance,
    );
    return DietaryProfile(
      pattern: pattern,
      avoidedFoods: avoidedFoods,
      avoidedIngredients: avoidedIngredients,
      dislikedFoods: dislikedFoods,
      culturalConstraints: culturalConstraints,
      notes: notes,
      provenance: audit.provenance,
      recordedAt: audit.recordedAt,
      updatedAt: audit.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (pattern != null) 'pattern': pattern!.name,
      'avoidedFoods': avoidedFoods,
      'avoidedIngredients': avoidedIngredients,
      'dislikedFoods': dislikedFoods,
      'culturalConstraints': culturalConstraints,
      'notes': notes,
      'provenance': provenance.name,
      if (recordedAt != null) 'recordedAt': HealthRecordAudit.iso(recordedAt!),
      if (updatedAt != null) 'updatedAt': HealthRecordAudit.iso(updatedAt!),
    };
  }

  static DietaryProfile fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return DietaryProfile.empty;
    DietaryPattern? pattern;
    final String? raw = data['pattern'] as String?;
    if (raw != null) {
      for (final DietaryPattern value in DietaryPattern.values) {
        if (value.name == raw) {
          pattern = value;
          break;
        }
      }
    }
    return DietaryProfile(
      pattern: pattern,
      avoidedFoods: _strings(data['avoidedFoods']),
      avoidedIngredients: _strings(data['avoidedIngredients']),
      dislikedFoods: _strings(data['dislikedFoods']),
      culturalConstraints: _strings(data['culturalConstraints']),
      notes: (data['notes'] as String?) ?? '',
      provenance: RecordProvenance.fromName(data['provenance'] as String?),
      recordedAt: HealthRecordAudit.parseTime(data['recordedAt']),
      updatedAt: HealthRecordAudit.parseTime(data['updatedAt']),
    );
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .whereType<String>()
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
  }
}
