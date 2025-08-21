// providers/booking_provider.dart
import 'package:flutter/foundation.dart';
import 'package:boardroom_booking/models/booking.dart';
import 'package:boardroom_booking/services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _userBookings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Booking> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch user's bookings with optional filters
  Future<void> fetchUserBookings({
    String? boardroomId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await BookingService.getBookings(
        boardroomId: boardroomId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );

      if (response['success'] == true) {
        final List<dynamic> bookingsData = response['data'] ?? [];
        _userBookings =
            bookingsData.map((json) => Booking.fromJson(json)).toList();

        // Sort bookings by date (newest first)
        _userBookings.sort((a, b) => b.date.compareTo(a.date));
      } else {
        _error = response['message'] ?? 'Failed to fetch bookings';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching bookings: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    _error = null;

    try {
      final response = await BookingService.cancelBooking(bookingId);

      if (response['success'] == true) {
        // Update the local booking status
        final index =
            _userBookings.indexWhere((booking) => booking.id == bookingId);
        if (index != -1) {
          _userBookings[index] =
              _userBookings[index].copyWith(status: 'cancelled');
          notifyListeners();
        }
        return true;
      } else {
        _error = response['message'] ?? 'Failed to cancel booking';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error cancelling booking: $e');
      }
      return false;
    }
  }

  // Update an existing booking
  Future<bool> updateBooking({
    required String bookingId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String purpose,
    required int attendees,
  }) async {
    _error = null;

    try {
      // Convert date and time strings to DateTime objects for API
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startTime.split(':')[0]),
        int.parse(startTime.split(':')[1]),
      );

      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endTime.split(':')[0]),
        int.parse(endTime.split(':')[1]),
      );

      final response = await BookingService.updateBooking(
        bookingId: bookingId,
        startTime: startDateTime,
        endTime: endDateTime,
        purpose: purpose,
      );

      if (response['success'] == true) {
        // Update the local booking
        final index =
            _userBookings.indexWhere((booking) => booking.id == bookingId);
        if (index != -1) {
          _userBookings[index] = _userBookings[index].copyWith(
            date: date,
            startTime: startTime,
            endTime: endTime,
            purpose: purpose,
            attendees: attendees,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update booking';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating booking: $e');
      }
      return false;
    }
  }

  // Create a new booking
  Future<bool> createBooking({
    required String boardroomId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String purpose,
    List<Map<String, String>>? externalAttendees,
    String? notes,
  }) async {
    _error = null;

    try {
      // Convert date and time strings to DateTime objects for API
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startTime.split(':')[0]),
        int.parse(startTime.split(':')[1]),
      );

      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endTime.split(':')[0]),
        int.parse(endTime.split(':')[1]),
      );

      final response = await BookingService.createBooking(
        boardroomId: boardroomId,
        startTime: startDateTime,
        endTime: endDateTime,
        purpose: purpose,
        externalAttendees: externalAttendees,
        notes: notes,
      );

      if (response['success'] == true) {
        // Add the new booking to the list if it was returned
        if (response['data'] != null) {
          final newBooking = Booking.fromJson(response['data']);
          _userBookings.insert(0, newBooking);
          notifyListeners();
        }
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create booking';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating booking: $e');
      }
      return false;
    }
  }

  // Get bookings for a specific boardroom (useful for checking availability)
  Future<List<Booking>> getBoardroomBookings(
    String boardroomId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await BookingService.getBookings(
        boardroomId: boardroomId,
        startDate: startDate,
        endDate: endDate,
      );

      if (response['success'] == true) {
        final List<dynamic> bookingsData = response['data'] ?? [];
        return bookingsData.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception(
            response['message'] ?? 'Failed to fetch boardroom bookings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching boardroom bookings: $e');
      }
      rethrow;
    }
  }

  // Clear all bookings (useful for logout)
  void clearBookings() {
    _userBookings.clear();
    _error = null;
    notifyListeners();
  }

  // Filter bookings locally (for quick filtering without API call)
  List<Booking> getFilteredBookings({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    List<Booking> filtered = List.from(_userBookings);

    if (status != null && status != 'all') {
      filtered = filtered.where((booking) => booking.status == status).toList();
    }

    if (fromDate != null) {
      filtered = filtered
          .where((booking) =>
              booking.date.isAfter(fromDate.subtract(const Duration(days: 1))))
          .toList();
    }

    if (toDate != null) {
      filtered = filtered
          .where((booking) =>
              booking.date.isBefore(toDate.add(const Duration(days: 1))))
          .toList();
    }

    return filtered;
  }

  // Get upcoming bookings (next 7 days)
  List<Booking> getUpcomingBookings() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _userBookings.where((booking) {
      return booking.date.isAfter(now.subtract(const Duration(days: 1))) &&
          booking.date.isBefore(nextWeek.add(const Duration(days: 1))) &&
          (booking.status == 'confirmed' || booking.status == 'pending');
    }).toList();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
