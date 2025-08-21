# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application for boardroom booking management. The app allows users to register, login, view available boardrooms, and manage bookings through a REST API backend.

## Architecture

### State Management
- Uses **Provider** pattern for state management
- Main providers: `AuthProvider`, `BoardroomProvider`, `BookingProvider`
- All providers follow the ChangeNotifier pattern for reactive UI updates

### API Communication
- Centralized API service in `lib/services/api_service.dart`
- Uses JWT tokens stored in Flutter Secure Storage
- Backend URL: `https://boardroom-app.onrender.com/api`
- Handles both web and mobile platforms with appropriate CORS headers

### Project Structure
```
lib/
├── main.dart                 # App entry point with MultiProvider setup
├── models/                   # Data models (User, Boardroom, Booking, etc.)
├── providers/                # State management providers
├── screens/                  # UI screens organized by feature
│   ├── auth/                 # Login/Register screens
│   ├── bookings/             # Booking management screens
│   ├── home/                 # Dashboard and main screen
│   └── profile/              # User profile screen
├── services/                 # API and business logic services
├── utils/                    # Constants, extensions, theme, validators
└── widgets/                  # Reusable UI components
```

### Key Components
- **MultiProvider Setup**: All providers initialized in `main.dart`
- **Secure Storage**: JWT tokens managed via `flutter_secure_storage`
- **Error Handling**: Comprehensive error handling in API service with platform-specific messages
- **Theme**: Custom Material Design theme with primary color `#6366F1`

## Development Commands

### Basic Flutter Commands
```bash
# Navigate to the app directory first
cd boardroom_app

# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific platform
flutter run -d android    # Android device/emulator
flutter run -d chrome     # Web browser
flutter run -d linux      # Linux desktop

# Build for release
flutter build apk         # Android APK
flutter build web         # Web build
flutter build linux       # Linux desktop

# Run tests
flutter test

# Analyze code (lint)
flutter analyze

# Format code
flutter format .
```

### Platform-Specific Notes
- **Web Development**: CORS issues may occur in development. Test on mobile devices for full functionality
- **API Configuration**: Backend is configured for production at `boardroom-app.onrender.com`
- **Local Development**: Update `ApiService.baseUrl` for local backend development

## Testing

- Basic widget test exists in `test/widget_test.dart` (needs updating for actual app functionality)
- Run tests with: `flutter test`
- The existing test is a template and should be replaced with actual app tests

## Code Style

- Uses `analysis_options.yaml` with Flutter lints enabled
- Follow Flutter/Dart conventions
- Run `flutter analyze` before committing changes
- Format code with `flutter format .`

## Key Features

1. **Authentication**: JWT-based auth with secure token storage
2. **Boardroom Management**: View available boardrooms with details
3. **Booking System**: Create, view, and cancel bookings
4. **Multi-platform**: Supports Android, iOS, web, and desktop
5. **Error Handling**: Comprehensive error handling with user-friendly messages

## Dependencies

### Main Dependencies
- `provider: ^6.0.5` - State management
- `http: ^1.1.0` - HTTP requests
- `flutter_secure_storage: ^9.0.0` - Secure token storage
- `intl: ^0.18.1` - Internationalization/date formatting

### Dev Dependencies  
- `flutter_lints: ^3.0.0` - Linting rules
- `flutter_test` - Testing framework

## Working Directory
Always run Flutter commands from the `boardroom_app/` directory, not the root project directory.