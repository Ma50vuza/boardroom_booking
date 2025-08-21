class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:5000/api';
  static const String wsUrl = 'ws://localhost:5000';

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';

  // App Info
  static const String appName = 'Boardroom Booking';
  static const String appVersion = '1.0.0';

  // Colors
  static const int primaryColorHex = 0xFF6366F1;
  static const int secondaryColorHex = 0xFF8B5CF6;
  static const int successColorHex = 0xFF10B981;
  static const int warningColorHex = 0xFFF59E0B;
  static const int errorColorHex = 0xFFEF4444;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
}
