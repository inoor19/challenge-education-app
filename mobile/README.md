# Mobile App — Flutter

## Requirements

- Flutter 3.19+
- Dart 3.x
- Android SDK / Xcode (for iOS)

## Setup

```bash
# Install dependencies
flutter pub get

# Backend URL (default: https://competitionarena.me/api)
# Edit: lib/core/config/app_config.dart
# Or override at build time:
# flutter run --dart-define=API_BASE_URL=https://competitionarena.me/api

# Run on connected device/emulator
flutter run

# Run with specific device
flutter devices
flutter run -d <device_id>

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build iOS (macOS only)
flutter build ios --release
```

## Demo Mode

Set `demoMode: true` in `lib/core/config/app_config.dart` to use mock data without a backend.

## App Structure

```
lib/
├── main.dart                          # App entry point, RTL setup
├── core/
│   ├── config/app_config.dart         # API URL, app constants
│   ├── api/api_client.dart            # Dio HTTP client
│   ├── models/api_models.dart         # Domain models
│   ├── providers/api_provider.dart    # ApiClient Riverpod provider
│   └── theme/app_theme.dart           # Material 3 theme, colors, fonts
├── features/
│   ├── auth/
│   │   ├── providers/auth_provider.dart
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       └── login_screen.dart
│   ├── setup/
│   │   ├── providers/setup_provider.dart
│   │   └── screens/
│   │       ├── select_grade_screen.dart
│   │       ├── select_subject_screen.dart
│   │       ├── select_chapters_screen.dart
│   │       ├── select_lessons_screen.dart
│   │       └── setup_groups_screen.dart
│   └── challenge/
│       ├── providers/challenge_provider.dart
│       ├── screens/challenge_arena_screen.dart
│       └── widgets/
│           ├── groups_scoreboard.dart
│           ├── dice_widget.dart
│           ├── timer_widget.dart
│           ├── question_grid.dart
│           └── question_dialog.dart
```

## Features

- Arabic RTL layout throughout
- Material 3 design system
- Tablet-responsive layouts (phone vs tablet detected by screen width)
- Riverpod state management
- Dio HTTP client with token interceptor
- Secure token storage (flutter_secure_storage)
- Animated dice rolling
- Countdown timer with pause/restart
- Numbered question grid with visual used/correct/wrong states
- Group scoreboard with long-press to add/subtract points
- Celebration effects after correct answers
- Auto-login on app start
