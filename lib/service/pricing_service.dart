class PricingService {
  bool isWeekday(DateTime day) =>
      day.weekday == DateTime.sunday || day.weekday <= DateTime.wednesday;

  double _dayPrice(
    DateTime day, {
    required double weekdayPrice,
    required double weekendPrice,
  }) {
    return isWeekday(day) ? weekdayPrice : weekendPrice;
  }

  double calculateRangeTotal({
    required DateTime checkIn,
    required DateTime checkOut,
    required double weekdayPrice,
    required double weekendPrice,
    required double fullWeekPrice,
  }) {
    final totalNights = checkOut.difference(checkIn).inDays;
    if (totalNights <= 0) {
      return 0;
    }

    final weeks = totalNights ~/ 7;
    final remainingDays = totalNights % 7;

    double total = 0;

    for (int week = 0; week < weeks; week++) {
      final weekStart = checkIn.add(Duration(days: week * 7));
      double calculatedWeekTotal = 0;
      for (int i = 0; i < 7; i++) {
        calculatedWeekTotal += _dayPrice(
          weekStart.add(Duration(days: i)),
          weekdayPrice: weekdayPrice,
          weekendPrice: weekendPrice,
        );
      }
      final weekPrice = fullWeekPrice > 0
          ? (calculatedWeekTotal < fullWeekPrice
              ? calculatedWeekTotal
              : fullWeekPrice)
          : calculatedWeekTotal;
      total += weekPrice;
    }

    final remainingStart = checkIn.add(Duration(days: weeks * 7));
    for (int i = 0; i < remainingDays; i++) {
      total += _dayPrice(
        remainingStart.add(Duration(days: i)),
        weekdayPrice: weekdayPrice,
        weekendPrice: weekendPrice,
      );
    }

    return total;
  }
}
