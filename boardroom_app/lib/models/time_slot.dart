import 'package:boardroom_booking/models/booking.dart'; // Import the Booking model

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final Booking? existingBooking;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.existingBooking,
  });

  Duration get duration => endTime.difference(startTime);

  String get timeRange =>
      '${startTime.toFormattedTime()} - ${endTime.toFormattedTime()}';

  bool get isInPast => endTime.isBefore(DateTime.now());
}

extension on DateTime {
  String toFormattedTime() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
