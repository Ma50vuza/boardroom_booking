# Launcher Icon Setup Instructions

I've configured your Flutter app to use a custom launcher icon, but I need you to manually place the icon image file.

## What I've Done:

1. ✅ Added `flutter_launcher_icons: ^0.13.1` to pubspec.yaml
2. ✅ Created assets/icons/ directory
3. ✅ Configured flutter_launcher_icons in pubspec.yaml
4. ✅ Set up icon generation for all platforms (Android, iOS, Web, Windows, macOS, Linux)

## What You Need To Do:

1. Save your boardroom meeting icon image as: `assets/icons/launcher_icon.png`
   - The image should be at least 1024x1024 pixels
   - PNG format
   - Square aspect ratio

2. Run the icon generator:
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

3. Clean and rebuild your app:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

## Current Configuration:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
  windows:
    generate: true
  macos:
    generate: true
  linux:
    generate: true
  image_path: "assets/icons/launcher_icon.png"
  min_sdk_android: 21
```

This will replace the default Flutter icon with your custom boardroom booking icon across all platforms.