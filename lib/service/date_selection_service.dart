class DateRangeSelectionResult {
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int totalNights;
  final String? errorMessage;

  const DateRangeSelectionResult({
    required this.checkIn,
    required this.checkOut,
    required this.totalNights,
    this.errorMessage,
  });
}

class DateSelectionService {
  DateTime normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isUnavailable(DateTime day, Set<DateTime> unavailableDates) =>
      unavailableDates.any((d) => isSameDay(d, day));

  bool rangeIncludesUnavailable({
    required DateTime start,
    required DateTime end,
    required Set<DateTime> unavailableDates,
  }) {
    var cursor = start;
    while (cursor.isBefore(end)) {
      if (isUnavailable(cursor, unavailableDates)) {
        return true;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return false;
  }

  List<DateTime> buildSelectedDates({
    required DateTime start,
    required DateTime end,
  }) {
    final dates = <DateTime>[];
    var cursor = start;
    while (cursor.isBefore(end)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  DateRangeSelectionResult evaluateRange({
    required DateTime? start,
    required DateTime? end,
    required DateTime today,
    required Set<DateTime> unavailableDates,
    int maxNights = 30,
    int maxDays = 365,
  }) {
    if (start == null) {
      return const DateRangeSelectionResult(
        checkIn: null,
        checkOut: null,
        totalNights: 0,
      );
    }

    final checkIn = normalize(start);
    final checkOut = end == null ? null : normalize(end);

    if (checkOut == null) {
      return DateRangeSelectionResult(
        checkIn: checkIn,
        checkOut: null,
        totalNights: 0,
      );
    }

    if (checkOut.isBefore(checkIn)) {
      return DateRangeSelectionResult(
        checkIn: checkIn,
        checkOut: null,
        totalNights: 0,
        errorMessage: "Invalid date range. Please select again.",
      );
    }

    final totalNights = checkOut.difference(checkIn).inDays;
    if (totalNights < 1) {
      return DateRangeSelectionResult(
        checkIn: checkIn,
        checkOut: null,
        totalNights: 0,
        errorMessage: "Please select at least 1 night.",
      );
    }

    final lastAllowed = today.add(Duration(days: maxDays));
    if (checkIn.isBefore(today) || checkOut.isAfter(lastAllowed)) {
      return const DateRangeSelectionResult(
        checkIn: null,
        checkOut: null,
        totalNights: 0,
        errorMessage: "Selected dates are out of range. Please select again.",
      );
    }

    if (totalNights > maxNights) {
      return DateRangeSelectionResult(
        checkIn: null,
        checkOut: null,
        totalNights: 0,
        errorMessage:
            "Selected range exceeds $maxNights nights. Please select again.",
      );
    }

    if (rangeIncludesUnavailable(
        start: checkIn, end: checkOut, unavailableDates: unavailableDates)) {
      return DateRangeSelectionResult(
        checkIn: checkIn,
        checkOut: checkIn,
        totalNights: 0,
        errorMessage:
            "Selected range includes unavailable dates. Please select again.",
      );
    }

    return DateRangeSelectionResult(
      checkIn: checkIn,
      checkOut: checkOut,
      totalNights: totalNights,
    );
  }
}
