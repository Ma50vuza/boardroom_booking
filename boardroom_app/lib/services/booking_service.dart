import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:boardroom_booking/services/api_service.dart';

class BookingService {
  static String baseUrl = ApiService.baseUrl;
  static Future<String?> getToken() => ApiService.getToken();
  static Map<String, String> _getAuthHeaders(String token) =>
      ApiService.getAuthHeaders(token);
  static Future<Map<String, dynamic>> _handleRequest(
          Future<http.Response> Function() request) =>
      ApiService.handleRequest(request);

  static Future<Map<String, dynamic>> getBookings({
    String? boardroomId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    print('Attempting to get bookings with URL: $baseUrl/bookings/my-bookings');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    // Build query parameters
    List<String> queryParams = [];
    if (boardroomId != null) queryParams.add('boardroom=$boardroomId');
    if (startDate != null) {
      queryParams.add('startDate=${startDate.toIso8601String().split('T')[0]}');
    }
    if (endDate != null) {
      queryParams.add('endDate=${endDate.toIso8601String().split('T')[0]}');
    }
    if (status != null) queryParams.add('status=$status');

    String queryString =
        queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    return await _handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/bookings/my-bookings$queryString'),
        headers: _getAuthHeaders(token),
      );
    });
  }

  static Future<Map<String, dynamic>> createBooking({
    required String boardroomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
    List<String>? attendees,
    List<Map<String, String>>? externalAttendees,
    String? notes,
  }) async {
    print('Attempting to create booking with URL: $baseUrl/bookings');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    return await _handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: _getAuthHeaders(token),
        body: json.encode({
          'boardroom': boardroomId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'purpose': purpose,
          'attendees': attendees ?? [],
          'externalAttendees': externalAttendees ?? [],
          'notes': notes,
        }),
      );
    });
  }

  static Future<Map<String, dynamic>> updateBooking({
    required String bookingId,
    DateTime? startTime,
    DateTime? endTime,
    String? purpose,
    List<String>? attendees,
    List<Map<String, String>>? externalAttendees,
    String? notes,
  }) async {
    print(
        'Attempting to update booking with URL: $baseUrl/bookings/$bookingId');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    Map<String, dynamic> updateData = {};
    if (startTime != null) {
      updateData['startTime'] = startTime.toIso8601String();
    }
    if (endTime != null) updateData['endTime'] = endTime.toIso8601String();
    if (purpose != null) updateData['purpose'] = purpose;
    if (attendees != null) updateData['attendees'] = attendees;
    if (externalAttendees != null) {
      updateData['externalAttendees'] = externalAttendees;
    }
    if (notes != null) updateData['notes'] = notes;

    return await _handleRequest(() async {
      return await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: _getAuthHeaders(token),
        body: json.encode(updateData),
      );
    });
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    print(
        'Attempting to cancel booking with URL: $baseUrl/bookings/$bookingId');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    return await _handleRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: _getAuthHeaders(token),
      );
    });
  }

  static Future<Map<String, dynamic>> checkAvailability({
    required String boardroomId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    print(
        'Attempting to check availability with URL: $baseUrl/bookings/availability/$boardroomId');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    final queryParams = [
      'startTime=${startTime.toIso8601String()}',
      'endTime=${endTime.toIso8601String()}',
    ];

    return await _handleRequest(() async {
      return await http.get(
        Uri.parse(
            '$baseUrl/bookings/availability/$boardroomId?${queryParams.join('&')}'),
        headers: _getAuthHeaders(token),
      );
    });
  }
}
