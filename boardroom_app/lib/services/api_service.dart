import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Add this import for TimeoutException
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Use different URLs for web vs mobile
  static String get baseUrl {
    if (kIsWeb) {
      // For web development, you might want to use a proxy or different URL
      return 'https://boardroom-app.onrender.com/api';
    } else {
      // For mobile
      return 'https://boardroom-app.onrender.com/api';
    }
  }

  static const String _tokenKey = 'jwt_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Increased timeout for production server
  static const Duration _timeout = Duration(seconds: 30);

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('Error reading token: $e');
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      print('Error deleting token: $e');
    }
  }

  static Map<String, String> getHeaders({bool includeAuth = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'BoardroomApp/1.0',
    };

    // Add web-specific headers
    if (kIsWeb) {
      headers['Access-Control-Allow-Origin'] = '*';
      headers['Access-Control-Allow-Methods'] =
          'GET, POST, PUT, DELETE, OPTIONS';
      headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
    }

    return headers;
  }

  static Map<String, String> getAuthHeaders(String token) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'User-Agent': 'BoardroomApp/1.0',
    };

    // Add web-specific headers
    if (kIsWeb) {
      headers['Access-Control-Allow-Origin'] = '*';
      headers['Access-Control-Allow-Methods'] =
          'GET, POST, PUT, DELETE, OPTIONS';
      headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      print('Making API request to: $baseUrl');
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');

      final response = await request().timeout(_timeout);

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }

      final data = json.decode(response.body);
      print('Response data: $data');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ??
              'Request failed with status ${response.statusCode}'
        };
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      return {
        'success': false,
        'message': kIsWeb
            ? 'Connection failed. This might be a CORS issue in web development. Try testing on mobile instead.'
            : 'No internet connection. Please check your network and try again.'
      };
    } on HttpException catch (e) {
      print('HttpException: $e');
      return {
        'success': false,
        'message': 'Server connection failed. Please try again later.'
      };
    } on FormatException catch (e) {
      print('FormatException: $e');
      return {
        'success': false,
        'message': 'Invalid response format from server'
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout. The server is taking too long to respond.'
      };
    } catch (e) {
      // Provide web-specific error message
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        return {
          'success': false,
          'message': 'CORS Error: Cannot connect to server from web browser. '
              'This is normal in development. Try:\n'
              '1. Test on mobile device instead\n'
              '2. Update backend CORS settings\n'
              '3. Use flutter run -d android/ios'
        };
      }

      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    print('Attempting to register with URL: $baseUrl/auth/register');

    return await handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: getHeaders(includeAuth: false),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
    }).then((result) async {
      if (result['success'] && result['data']['token'] != null) {
        await saveToken(result['data']['token']);
      }
      return result;
    });
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('Attempting to login with URL: $baseUrl/auth/login');

    return await handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
    }).then((result) async {
      if (result['success'] && result['data']['token'] != null) {
        await saveToken(result['data']['token']);
      }
      return result;
    });
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    print('Attempting to get user profile with URL: $baseUrl/auth/profile');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    return await handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: getAuthHeaders(token),
      );
    });
  }

  static Future<Map<String, dynamic>> getBoardrooms() async {
    print('Attempting to get boardrooms with URL: $baseUrl/boardrooms');

    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    return await handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/boardrooms'),
        headers: getAuthHeaders(token),
      );
    });
  }

  // NEW METHOD: Get bookings with filters
  static Future<Map<String, dynamic>> getBookings({
    String? boardroomId,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    // Add debug prints
    print('DEBUG: Token length: ${token.length}');

    // Build query parameters
    List<String> queryParams = [];
    if (boardroomId != null) {
      queryParams.add('boardroom=${Uri.encodeComponent(boardroomId)}');
    }
    if (startDate != null) {
      queryParams.add('startDate=$startDate');
    }
    if (endDate != null) {
      queryParams.add('endDate=$endDate');
    }
    if (status != null) {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }

    String url = '$baseUrl/bookings/my-bookings';
    if (queryParams.isNotEmpty) {
      url = '$url?${queryParams.join('&')}';
    }

    // Add debug print
    print('DEBUG: Making request to: $url');

    return await handleRequest(() async {
      return await http.get(
        Uri.parse(url),
        headers: getAuthHeaders(token),
      );
    });
  }

  // NEW METHOD: Cancel a booking
  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    print(
        'Attempting to cancel booking with URL: $baseUrl/bookings/$bookingId');

    return await handleRequest(() async {
      return await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: getAuthHeaders(token),
      );
    });
  }

  static Future<Map<String, dynamic>> healthCheck() async {
    print('Attempting health check with URL: $baseUrl/health');

    return await handleRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/health'),
        headers: getHeaders(includeAuth: false),
      );
    });
  }

  static Future<bool> testConnectivity() async {
    try {
      final result = await healthCheck();
      return result['success'] == true;
    } catch (e) {
      print('Connectivity test failed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createBooking({
    required String boardroomId,
    required DateTime startTime,
    required DateTime endTime,
    required String purpose,
    List<Map<String, String>>? externalAttendees,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'No authentication token found'};
    }

    return await handleRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: getAuthHeaders(token),
        body: json.encode({
          'boardroom': boardroomId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'purpose': purpose,
          'externalAttendees': externalAttendees ?? [],
          'notes': notes,
        }),
      );
    });
  }
}
