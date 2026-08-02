import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'health_units.dart';

enum BiologicalSex {
  male('Male'),
  female('Female'),
  intersex('Intersex'),
  preferNotToSay('Prefer not to say');

  const BiologicalSex(this.label);

  final String label;
}

enum BloodGroup {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-'),
  unknown('I don\'t know');

  const BloodGroup(this.label);

  final String label;
}

/// Affects which medicines are safe to suggest, so it is asked explicitly
/// rather than inferred.
enum PregnancyStatus {
  notPregnant('Not pregnant'),
  pregnant('Pregnant'),
  breastfeeding('Breastfeeding'),
  tryingToConceive('Trying to conceive'),
  preferNotToSay('Prefer not to say');

  const PregnancyStatus(this.label);

  final String label;
}

enum BmiCategory {
  underweight('Underweight'),
  healthy('Healthy weight'),
  overweight('Overweight'),
  obese('Obese');

  const BmiCategory(this.label);

  final String label;
}

/// The clinical basics every later feature reads from.
///
/// Every field is optional: a partly filled profile is still useful, and
/// forcing people through a long medical form up front only makes them quit.
@immutable
class HealthProfile {
  const HealthProfile({
    this.dateOfBirth,
    this.biologicalSex,
    this.heightCm,
    this.weightKg,
    this.bloodGroup,
    this.pregnancyStatus,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    this.preferredUnits = UnitSystem.metric,
    this.updatedAt,
  });

  static const HealthProfile empty = HealthProfile();

  /// Stored rather than age so the record stays correct as years pass.
  final DateTime? dateOfBirth;
  final BiologicalSex? biologicalSex;
  final double? heightCm;
  final double? weightKg;
  final BloodGroup? bloodGroup;
  final PregnancyStatus? pregnancyStatus;
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;
  final UnitSystem preferredUnits;
  final DateTime? updatedAt;

  int? get ageInYears {
    final DateTime? birthDate = dateOfBirth;

    if (birthDate == null) return null;

    final DateTime now = DateTime.now();

    int age = now.year - birthDate.year;

    final bool birthdayStillToCome =
        now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);

    if (birthdayStillToCome) age--;

    return age < 0 ? null : age;
  }

  double? get bmi {
    final double? height = heightCm;
    final double? weight = weightKg;

    if (height == null || weight == null || height <= 0) return null;

    final double heightInMetres = height / 100;

    return weight / (heightInMetres * heightInMetres);
  }

  BmiCategory? get bmiCategory {
    final double? value = bmi;

    if (value == null) return null;

    if (value < 18.5) return BmiCategory.underweight;
    if (value < 25) return BmiCategory.healthy;
    if (value < 30) return BmiCategory.overweight;

    return BmiCategory.obese;
  }

  /// BMI is a crude screen that does not hold up during pregnancy or while
  /// still growing, so the UI can warn instead of stating it as fact.
  bool get bmiNeedsCaveat {
    final int? age = ageInYears;

    final bool expectingOrFeeding =
        pregnancyStatus == PregnancyStatus.pregnant ||
        pregnancyStatus == PregnancyStatus.breastfeeding;

    return expectingOrFeeding || (age != null && age < 20);
  }

  /// Whether it makes clinical sense to ask about pregnancy at all.
  bool get pregnancyQuestionApplies =>
      biologicalSex == BiologicalSex.female ||
      biologicalSex == BiologicalSex.intersex;

  bool get hasEmergencyContact {
    final String? name = emergencyContactName;
    final String? phone = emergencyContactPhone;

    return name != null &&
        name.trim().isNotEmpty &&
        phone != null &&
        phone.trim().isNotEmpty;
  }

  List<({String label, bool isComplete})> get completionItems => [
    (label: 'Date of birth', isComplete: dateOfBirth != null),
    (label: 'Biological sex', isComplete: biologicalSex != null),
    (label: 'Height', isComplete: heightCm != null),
    (label: 'Weight', isComplete: weightKg != null),
    (label: 'Blood group', isComplete: bloodGroup != null),
    if (pregnancyQuestionApplies)
      (label: 'Pregnancy status', isComplete: pregnancyStatus != null),
    (label: 'Emergency contact', isComplete: hasEmergencyContact),
  ];

  /// Fraction of the basics that are filled in, from 0.0 to 1.0.
  double get completion {
    final List<({String label, bool isComplete})> items = completionItems;

    final int completed = items.where((item) => item.isComplete).length;

    return completed / items.length;
  }

  List<String> get missingItems => completionItems
      .where((item) => !item.isComplete)
      .map((item) => item.label)
      .toList();

  bool get isComplete => missingItems.isEmpty;

  /// Compares only the answers the user gave, ignoring server-managed metadata
  /// such as [updatedAt]. Used to tell whether a form has unsaved edits.
  bool hasSameAnswersAs(HealthProfile other) {
    return dateOfBirth == other.dateOfBirth &&
        biologicalSex == other.biologicalSex &&
        heightCm == other.heightCm &&
        weightKg == other.weightKg &&
        bloodGroup == other.bloodGroup &&
        pregnancyStatus == other.pregnancyStatus &&
        preferredUnits == other.preferredUnits &&
        _trimToNull(emergencyContactName) ==
            _trimToNull(other.emergencyContactName) &&
        _trimToNull(emergencyContactRelation) ==
            _trimToNull(other.emergencyContactRelation) &&
        _trimToNull(emergencyContactPhone) ==
            _trimToNull(other.emergencyContactPhone);
  }

  /// Reads defensively: a malformed field should cost that one value, never
  /// crash the screen and lock someone out of their own health record.
  factory HealthProfile.fromMap(Map<String, dynamic> map) {
    return HealthProfile(
      dateOfBirth: _readDate(map['dateOfBirth']),
      biologicalSex: _readEnum(map['biologicalSex'], BiologicalSex.values),
      heightCm: _readDouble(map['heightCm']),
      weightKg: _readDouble(map['weightKg']),
      bloodGroup: _readEnum(map['bloodGroup'], BloodGroup.values),
      pregnancyStatus: _readEnum(
        map['pregnancyStatus'],
        PregnancyStatus.values,
      ),
      emergencyContactName: _readString(map['emergencyContactName']),
      emergencyContactRelation: _readString(map['emergencyContactRelation']),
      emergencyContactPhone: _readString(map['emergencyContactPhone']),
      preferredUnits:
          _readEnum(map['preferredUnits'], UnitSystem.values) ??
          UnitSystem.metric,
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dateOfBirth': dateOfBirth == null
          ? null
          : Timestamp.fromDate(dateOfBirth!),
      'biologicalSex': biologicalSex?.name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bloodGroup': bloodGroup?.name,
      'pregnancyStatus': pregnancyQuestionApplies
          ? pregnancyStatus?.name
          : null,
      'emergencyContactName': _trimToNull(emergencyContactName),
      'emergencyContactRelation': _trimToNull(emergencyContactRelation),
      'emergencyContactPhone': _trimToNull(emergencyContactPhone),
      'preferredUnits': preferredUnits.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String? _trimToNull(String? value) {
    final String? trimmed = value?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;

    return _trimToNull(value);
  }

  static T? _readEnum<T extends Enum>(Object? value, List<T> values) {
    if (value is! String) return null;

    for (final T candidate in values) {
      if (candidate.name == value) return candidate;
    }

    return null;
  }
}
