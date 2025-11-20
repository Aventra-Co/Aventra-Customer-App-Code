class TripHistoryModel {
  final int tripBookingId;
  final int tripId;
  final String tripImage;
  final String boatNameEnglish;
  final String bookingDate;
  final int randomBookingId;
  final String totalAmount;
  final String bookingTime;

  TripHistoryModel({
    required this.tripBookingId,
    required this.tripId,
    required this.tripImage,
    required this.boatNameEnglish,
    required this.bookingDate,
    required this.randomBookingId,
    required this.totalAmount,
    required this.bookingTime,
  });

  factory TripHistoryModel.fromJson(Map<String, dynamic> json) {
    return TripHistoryModel(
      tripBookingId: json['trip_booking_id'],
      tripId: json['trip_id'],
      tripImage: json['trip_image'],
      boatNameEnglish: json['boat_name_english'],
      bookingDate: json['booking_date'],
      randomBookingId: json['random_booking_id'],
      totalAmount: json['total_amount'],
      bookingTime: json['booking_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_booking_id': tripBookingId,
      'trip_id': tripId,
      'trip_image': tripImage,
      'boat_name_english': boatNameEnglish,
      'booking_date': bookingDate,
      'random_booking_id': randomBookingId,
      'total_amount': totalAmount,
      'booking_time': bookingTime,
    };
  }
}
