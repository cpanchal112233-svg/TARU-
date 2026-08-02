/// Conversions between the units people enter and the metric values TARU stores.
///
/// Height and weight are always persisted in cm and kg. Anything else would
/// leave the database holding mixed units, which no later calculation could
/// safely interpret.
class HealthUnits {
  const HealthUnits._();

  static const double kilogramsPerPound = 0.45359237;
  static const double centimetresPerInch = 2.54;
  static const int inchesPerFoot = 12;

  static double poundsToKilograms(double pounds) => pounds * kilogramsPerPound;

  static double kilogramsToPounds(double kilograms) =>
      kilograms / kilogramsPerPound;

  static double feetAndInchesToCentimetres(int feet, double inches) =>
      (feet * inchesPerFoot + inches) * centimetresPerInch;

  /// Splits a height in centimetres into whole feet and remaining inches.
  static ({int feet, int inches}) centimetresToFeetAndInches(
    double centimetres,
  ) {
    final int totalInches = (centimetres / centimetresPerInch).round();

    return (
      feet: totalInches ~/ inchesPerFoot,
      inches: totalInches % inchesPerFoot,
    );
  }
}

enum UnitSystem {
  metric('Metric', 'cm', 'kg'),
  imperial('Imperial', 'ft/in', 'lb');

  const UnitSystem(this.label, this.heightUnit, this.weightUnit);

  final String label;
  final String heightUnit;
  final String weightUnit;
}
