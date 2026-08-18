/// Firestore paths for Health Context. Underlying domain docs remain
/// authoritative — this is not a persisted aggregate.
///
/// Destructive health purge is owned by Functions
/// (`functions/src/health_collection_roots.json`). Dart does not decide
/// which server collections to delete.
class HealthContextPaths {
  const HealthContextPaths._();

  static const String dietaryProfileDoc = 'dietaryProfile';
  static const String lifestyleDoc = 'lifestyle';

  static const String supplements = 'supplements';
  static const String familyHistory = 'familyHistory';
  static const String procedures = 'procedures';
  static const String immunizations = 'immunizations';
  static const String healthGoals = 'healthGoals';
  static const String careTeam = 'careTeam';

  /// Health Context collection names (export/repos). Not the purge allowlist.
  static const List<String> collectionNames = <String>[
    supplements,
    familyHistory,
    procedures,
    immunizations,
    healthGoals,
    careTeam,
  ];
}
