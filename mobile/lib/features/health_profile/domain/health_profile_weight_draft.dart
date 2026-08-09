// Draft-weight sync rules for the Health Profile editor.
//
// Phase 8 can update `profile.weightKg` from Weight History while
// HealthProfileScreen remains mounted underneath. These helpers decide
// whether the local draft should follow that live value or keep an
// intentional in-progress edit.

bool sameWeightKg(double? a, double? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return (a - b).abs() <= 0.0001;
}

/// Returns the draft weight the form should hold after a live profile refresh.
///
/// When [weightDirty] is false, the draft follows [liveWeightKg].
/// When [weightDirty] is true, the intentional local edit is preserved.
double? resolveHealthProfileDraftWeightKg({
  required double? draftWeightKg,
  required double? liveWeightKg,
  required bool weightDirty,
}) {
  if (weightDirty) return draftWeightKg;
  return liveWeightKg;
}
