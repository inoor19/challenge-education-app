# ساحة التنافس

مشروع متكامل لمنصة منافسات تعليمية داخل الصف.

---

## Project Structure

```
challenge-education-app/
├── backend/          # واجهة API ولوحة إدارة Filament
├── mobile/           # تطبيق Flutter لأندرويد و iOS والتابلت
├── docs/             # توثيق النظام
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

بيانات حساب المدير الافتراضي:
- Email: `admin@example.com`
- Password: `password`

بيانات حساب المعلم الافتراضي:
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

## التسلسل التعليمي

```
الصف الدراسي (Grade)
  └── المادة (Subject)
        └── الفصل (Chapter)
              └── الدرس (Lesson)
                    └── السؤال (Question)
```

---

## Features

- **مسار المعلم**: تسجيل الدخول → اختيار الصف → اختيار المادة → اختيار الفصول → اختيار الدروس → ساحة التنافس
- **ساحة التنافس**: إدارة الفرق، نقاط الحظ، شبكة الأسئلة المرقمة، ومؤقت 60 ثانية
- **التسجيل**: الأسئلة السهلة = قيمة النرد، والأسئلة الصعبة = قيمة النرد × 2، مع دعم التعديل اليدوي
- **لوحة الإدارة**: إدارة المحتوى التعليمي، استيراد Excel، وإدارة المعلمين
- **API**: واجهة REST مؤمنة عبر Laravel Sanctum

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
