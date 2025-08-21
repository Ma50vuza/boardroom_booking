// models/booking.dart
class Booking {
  final String id;
  final String userId;
  final String boardroomId;
  final String boardroomName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String purpose;
  final int attendees;
  final List<Map<String, String>> externalAttendees;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.boardroomId,
    required this.boardroomName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.purpose,
    this.attendees = 0,
    this.externalAttendees = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // Create Booking from JSON - FIXED VERSION
  factory Booking.fromJson(Map<String, dynamic> json) {
    String boardroomName = '';
    String boardroomId = '';

    // Handle boardroom data properly
    if (json['boardroom'] != null) {
      if (json['boardroom'] is Map<String, dynamic>) {
        // If boardroom is an object, extract the name
        final boardroomData = json['boardroom'] as Map<String, dynamic>;
        boardroomName = boardroomData['name']?.toString() ?? '';
        boardroomId = boardroomData['_id']?.toString() ?? '';
      } else {
        // If boardroom is just a string (ID), use it as ID
        boardroomId = json['boardroom'].toString();
        boardroomName = json['boardroom_name']?.toString() ?? '';
      }
    } else {
      // Fallback to separate fields
      boardroomId = json['boardroom_id']?.toString() ?? '';
      boardroomName = json['boardroom_name']?.toString() ?? '';
    }

    return Booking(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? json['user_id']?.toString() ?? '',
      boardroomId: boardroomId,
      boardroomName: boardroomName,
      date: DateTime.parse(
          json['date']?.toString() ?? DateTime.now().toIso8601String()),
      startTime:
          json['startTime']?.toString() ?? json['start_time']?.toString() ?? '',
      endTime:
          json['endTime']?.toString() ?? json['end_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      purpose: json['purpose']?.toString() ?? '',
      attendees: int.tryParse(json['attendees']?.toString() ?? '0') ?? 0,
      externalAttendees: json['externalAttendees'] != null 
          ? List<Map<String, String>>.from(
              (json['externalAttendees'] as List<dynamic>? ?? []).map(
                (attendee) => Map<String, String>.from(attendee as Map<String, dynamic>? ?? {}),
              ),
            )
          : [],
      createdAt: DateTime.parse(json['createdAt']?.toString() ??
          json['created_at']?.toString() ??
          DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.parse((json['updatedAt'] ?? json['updated_at']).toString())
          : null,
    );
  }

  // Convert Booking to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'boardroom_id': boardroomId,
      'boardroom_name': boardroomName,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'purpose': purpose,
      'attendees': attendees,
      'externalAttendees': externalAttendees,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Copy with method for immutability
  Booking copyWith({
    String? id,
    String? userId,
    String? boardroomId,
    String? boardroomName,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? status,
    String? purpose,
    int? attendees,
    List<Map<String, String>>? externalAttendees,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      boardroomId: boardroomId ?? this.boardroomId,
      boardroomName: boardroomName ?? this.boardroomName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      attendees: attendees ?? this.attendees,
      externalAttendees: externalAttendees ?? this.externalAttendees,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Formatted date string
  String get formattedDate {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(date.year, date.month, date.day);

    if (bookingDate == today) {
      return 'Today';
    } else if (bookingDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (bookingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day} ${months[date.month]}, ${date.year}';
    }
  }

  // Formatted duration
  String get formattedDuration {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start != null && end != null) {
      final duration = end.difference(start);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}m';
      }
    }

    return 'Unknown';
  }

  // Formatted booked at time
  String get formattedBookedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if booking is in the past
  bool get isPast {
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      _parseTime(endTime)?.hour ?? 23,
      _parseTime(endTime)?.minute ?? 59,
    );
    return bookingDateTime.isBefore(now);
  }

  // Check if booking is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if booking is upcoming (future)
  bool get isUpcoming {
    final now = DateTime.now();
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      _parseTime(startTime)?.hour ?? 0,
      _parseTime(startTime)?.minute ?? 0,
    );
    return bookingDateTime.isAfter(now);
  }

  // Check if booking can be cancelled
  bool get canBeCancelled {
    return (status == 'confirmed' || status == 'pending') && !isPast;
  }

  // Status color helper
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Helper method to parse time string (HH:mm) to DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2000, 1, 1, hour,
            minute); // Using a fixed date for time calculation
      }
    } catch (e) {
      // Handle parsing error
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking(id: $id, boardroomName: $boardroomName, date: $date, startTime: $startTime, endTime: $endTime, status: $status)';
  }
}
