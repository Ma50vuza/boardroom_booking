import 'package:flutter/foundation.dart';
import 'package:boardroom_booking/models/booking.dart';

class BookingProviderState with ChangeNotifier {
  // Private fields
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedBoardroomId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedStatus;

  // Public getters (what other parts of your app can access)
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedBoardroomId => _selectedBoardroomId;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  String? get selectedStatus => _selectedStatus;

  // Filtered bookings
  List<Booking> get filteredBookings {
    return _bookings.where((booking) {
      bool matchesBoardroom = _selectedBoardroomId == null ||
          booking.boardroomId == _selectedBoardroomId;

      bool matchesDateRange = true;
      if (_selectedStartDate != null || _selectedEndDate != null) {
        if (_selectedStartDate != null) {
          matchesDateRange = matchesDateRange &&
              booking.date.isAfter(
                  _selectedStartDate!.subtract(const Duration(days: 1)));
        }

        if (_selectedEndDate != null) {
          matchesDateRange = matchesDateRange &&
              booking.date
                  .isBefore(_selectedEndDate!.add(const Duration(days: 1)));
        }
      }

      bool matchesStatus = _selectedStatus == null ||
          booking.status.toLowerCase() == _selectedStatus!.toLowerCase();

      return matchesBoardroom && matchesDateRange && matchesStatus;
    }).toList();
  }

  // Today's bookings
  List<Booking> get todaysBookings {
    final today = DateTime.now();
    return _bookings.where((booking) {
      return booking.date.year == today.year &&
          booking.date.month == today.month &&
          booking.date.day == today.day;
    }).toList();
  }

  // Upcoming bookings (next 7 days)
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _bookings.where((booking) {
      return booking.date.isAfter(now.subtract(const Duration(days: 1))) &&
          booking.date.isBefore(nextWeek.add(const Duration(days: 1))) &&
          (booking.status == 'confirmed' || booking.status == 'pending');
    }).toList();
  }

  // Methods to update the state
  void setSelectedBoardroomId(String? boardroomId) {
    _selectedBoardroomId = boardroomId;
    notifyListeners();
  }

  void setSelectedStartDate(DateTime? startDate) {
    _selectedStartDate = startDate;
    notifyListeners();
  }

  void setSelectedEndDate(DateTime? endDate) {
    _selectedEndDate = endDate;
    notifyListeners();
  }

  void setSelectedStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setBookings(List<Booking> bookings) {
    _bookings = bookings;
    notifyListeners();
  }

  void addBooking(Booking booking) {
    _bookings.add(booking);
    // Sort bookings by date (newest first)
    _bookings.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void updateBooking(Booking updatedBooking) {
    final index =
        _bookings.indexWhere((booking) => booking.id == updatedBooking.id);
    if (index != -1) {
      _bookings[index] = updatedBooking;
      notifyListeners();
    }
  }

  void removeBooking(String bookingId) {
    _bookings.removeWhere((booking) => booking.id == bookingId);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearFilters() {
    _selectedBoardroomId = null;
    _selectedStartDate = null;
    _selectedEndDate = null;
    _selectedStatus = null;
    notifyListeners();
  }

  void clearBookings() {
    _bookings.clear();
    clearFilters();
    clearError();
    notifyListeners();
  }

  // Helper methods for filtering
  List<Booking> getBookingsByStatus(String status) {
    return _bookings
        .where(
            (booking) => booking.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  List<Booking> getBookingsByBoardroom(String boardroomId) {
    return _bookings
        .where((booking) => booking.boardroomId == boardroomId)
        .toList();
  }

  List<Booking> getBookingsByDateRange(DateTime startDate, DateTime endDate) {
    return _bookings.where((booking) {
      return booking.date
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          booking.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Check if a specific time slot is available
  bool isTimeSlotAvailable(
      String boardroomId, DateTime date, String startTime, String endTime) {
    return !_bookings.any((booking) {
      if (booking.boardroomId != boardroomId ||
          booking.date != date ||
          booking.status == 'cancelled') {
        return false;
      }

      // Check for time overlap
      return _timesOverlap(
          booking.startTime, booking.endTime, startTime, endTime);
    });
  }

  // Helper method to check if two time ranges overlap
  bool _timesOverlap(String existingStart, String existingEnd, String newStart,
      String newEnd) {
    try {
      final existingStartTime = _parseTime(existingStart);
      final existingEndTime = _parseTime(existingEnd);
      final newStartTime = _parseTime(newStart);
      final newEndTime = _parseTime(newEnd);

      if (existingStartTime == null ||
          existingEndTime == null ||
          newStartTime == null ||
          newEndTime == null) {
        return false;
      }

      return newStartTime.isBefore(existingEndTime) &&
          newEndTime.isAfter(existingStartTime);
    } catch (e) {
      return false;
    }
  }

  // Helper method to parse time string (HH:mm) to DateTime for comparison
  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2000, 1, 1, hour, minute);
      }
    } catch (e) {
      // Handle parsing error
    }
    return null;
  }
}
