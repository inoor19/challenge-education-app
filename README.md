# ساحة التحدي التعليمي — Educational Challenge Arena

A complete monorepo for a classroom educational competition platform.

---

## Project Structure

```
challenge-education-app/
├── backend/          # Laravel API + Filament Admin Dashboard
├── mobile/           # Flutter application (Android, iOS, Tablet)
├── docs/             # System documentation
└── README.md
```

---

## Quick Start

### Prerequisites

| Tool | Minimum Version |
|------|----------------|
| PHP  | 8.2 |
| Composer | 2.x |
| MySQL | 8.0 (or SQLite for dev) |
| Node.js | 18.x |
| Flutter | 3.19+ |
| Dart | 3.x |

---

### Backend Setup

```bash
cd backend

# Install PHP dependencies
composer install

# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure your database in .env
# DB_CONNECTION=mysql  (or sqlite)
# DB_DATABASE=challenge_edu
# DB_USERNAME=root
# DB_PASSWORD=

# Run migrations
php artisan migrate

# Seed sample data
php artisan db:seed

# Create storage symlink
php artisan storage:link

# Start development server
php artisan serve
```

Access the admin panel at: `http://localhost:8000/admin`

Admin credentials (seeded):
- Email: `admin@example.com`
- Password: `password`

Teacher credentials (seeded):
- Email: `teacher@example.com`
- Password: `password`

---

### Mobile App Setup

```bash
cd mobile

# Install Flutter dependencies
flutter pub get

# Configure API base URL
# Edit: lib/core/config/app_config.dart
# Set apiBaseUrl to your backend URL

# Run on device or emulator
flutter run

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

---

## Educational Hierarchy

```
الصف الدراسي (Grade)
  └── المادة (Subject)
        └── الفصل (Chapter)
              └── الدرس (Lesson)
                    └── السؤال (Question)
```

---

## Features

- **Teacher Flow**: Login → Select Grade → Select Subject → Select Chapter(s) → Select Lesson(s) → Challenge Arena
- **Challenge Arena**: Group management, dice rolling (نقاط الحظ), numbered question grid, 60-second timer
- **Scoring**: Easy questions = dice value, Hard questions = dice × 2; manual add/subtract supported
- **Admin Panel**: Full CRUD for all educational content, Excel import, teacher management
- **API**: RESTful API secured with Laravel Sanctum

---

## Documentation

- [System Overview](docs/system-overview.md)
- [Database Schema](docs/database-schema.md)
- [API Specification](docs/api-spec.md)
- [Excel Template Spec](docs/excel-template-spec.md)
- [Acceptance Criteria](docs/acceptance-criteria.md)

---

## License

Private — All rights reserved.
