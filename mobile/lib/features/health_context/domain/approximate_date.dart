/// User-stated date with explicit precision.
///
/// Unknown is a first-class answer. Do not invent a calendar date.
/// Year 2019 is not 1 January 2019. June 2019 is not 1 June 2019.
enum DatePrecision { exact, monthYear, year, unknown }

class ApproximateDate {
  /// Draft-friendly constructor. [isValid] is false until the combination
  /// matches [precision]. Persistence must use [persisted] / [tryCreate].
  const ApproximateDate({
    required this.precision,
    this.year,
    this.month,
    this.day,
  });

  static const ApproximateDate unknown = ApproximateDate(
    precision: DatePrecision.unknown,
  );

  final DatePrecision precision;
  final int? year;
  final int? month;
  final int? day;

  bool get isUnknown => precision == DatePrecision.unknown;

  /// True only when stored parts exactly match [precision] and the calendar.
  bool get isValid {
    switch (precision) {
      case DatePrecision.unknown:
        return year == null && month == null && day == null;
      case DatePrecision.year:
        return year != null &&
            month == null &&
            day == null &&
            _yearInRange(year!);
      case DatePrecision.monthYear:
        return year != null &&
            month != null &&
            day == null &&
            _yearInRange(year!) &&
            month! >= 1 &&
            month! <= 12;
      case DatePrecision.exact:
        return year != null &&
            month != null &&
            day != null &&
            _isValidCalendarDate(year!, month!, day!);
    }
  }

  /// Persistable value. Invalid stored data becomes [unknown] — never a
  /// different clinical date such as 1 January.
  ApproximateDate get persisted => isValid ? this : ApproximateDate.unknown;

  static ApproximateDate? tryCreate({
    required DatePrecision precision,
    int? year,
    int? month,
    int? day,
  }) {
    final ApproximateDate candidate = ApproximateDate(
      precision: precision,
      year: year,
      month: month,
      day: day,
    );
    return candidate.isValid ? candidate : null;
  }

  String get displayLabel {
    if (!isValid) {
      return 'Incomplete date — choose unknown or finish the fields';
    }
    switch (precision) {
      case DatePrecision.unknown:
        return 'Date not recorded';
      case DatePrecision.year:
        return '$year';
      case DatePrecision.monthYear:
        return '${_monthName(month!)} $year';
      case DatePrecision.exact:
        return '${_monthName(month!)} $day, $year';
    }
  }

  /// Ordering key only. Not an exact clinical event time.
  /// Year precision sorts as that year; it is not 1 January as fact.
  DateTime? get sortAnchor {
    if (!isValid) return null;
    switch (precision) {
      case DatePrecision.unknown:
        return null;
      case DatePrecision.year:
        return DateTime.utc(year!, 1, 1);
      case DatePrecision.monthYear:
        return DateTime.utc(year!, month!, 1);
      case DatePrecision.exact:
        return DateTime.utc(year!, month!, day!);
    }
  }

  /// True when [other] is known to fall strictly after this date given
  /// each value's precision. Unknown or incomparable → false (do not infer).
  bool isKnownBefore(ApproximateDate other) {
    final DateTime? a = sortAnchor;
    final DateTime? b = other.sortAnchor;
    if (a == null || b == null) return false;
    return a.isBefore(b);
  }

  Map<String, dynamic> toMap() {
    final ApproximateDate stored = persisted;
    return <String, dynamic>{
      'precision': stored.precision.name,
      if (stored.year != null) 'year': stored.year,
      if (stored.month != null) 'month': stored.month,
      if (stored.day != null) 'day': stored.day,
    };
  }

  static ApproximateDate fromMap(Object? raw) {
    if (raw is! Map) return ApproximateDate.unknown;
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    final DatePrecision precision = DatePrecision.values.firstWhere(
      (DatePrecision value) => value.name == map['precision'],
      orElse: () => DatePrecision.unknown,
    );
    final ApproximateDate candidate = ApproximateDate(
      precision: precision,
      year: (map['year'] as num?)?.toInt(),
      month: (map['month'] as num?)?.toInt(),
      day: (map['day'] as num?)?.toInt(),
    );
    return candidate.persisted;
  }

  static bool _yearInRange(int year) => year >= 1800 && year <= 2200;

  static bool _isValidCalendarDate(int year, int month, int day) {
    if (!_yearInRange(year) || month < 1 || month > 12 || day < 1 || day > 31) {
      return false;
    }
    final DateTime dt = DateTime.utc(year, month, day);
    return dt.year == year && dt.month == month && dt.day == day;
  }

  static String _monthName(int month) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return 'Month $month';
    return names[month - 1];
  }
}
