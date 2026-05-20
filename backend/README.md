# Backend — Laravel API + Filament Admin

## Requirements

- PHP 8.2+
- Composer 2.x
- MySQL 8.0+ or SQLite (local dev)

## Setup

```bash
# 1. Install dependencies
composer install

# 2. Environment
cp .env.example .env
php artisan key:generate

# 3. Database (MySQL)
# Edit .env: DB_DATABASE, DB_USERNAME, DB_PASSWORD
php artisan migrate
php artisan db:seed

# --- OR for SQLite (no MySQL needed) ---
# Edit .env:
#   DB_CONNECTION=sqlite
#   DB_DATABASE=/absolute/path/to/database.sqlite
touch database/database.sqlite
php artisan migrate
php artisan db:seed

# 4. Storage link
php artisan storage:link

# 5. Serve
php artisan serve
```

## Admin Panel

URL: `http://localhost:8000/admin`

| User | Email | Password |
|------|-------|----------|
| Admin | admin@example.com | password |
| Teacher | teacher@example.com | password |

## API Base URL

`http://localhost:8000/api`

All API endpoints (except `/api/login`) require `Authorization: Bearer {token}` header.

## Key Packages

| Package | Purpose |
|---------|---------|
| `filament/filament` ^3.2 | Admin dashboard |
| `laravel/sanctum` ^4.0 | API token auth |
| `maatwebsite/excel` ^3.1 | Excel import |

## Architecture

```
app/
├── Http/
│   ├── Controllers/Api/   # API controllers (thin, delegates to services)
│   ├── Requests/Api/      # Form request validation
│   └── Resources/         # API resource transformers
├── Models/                # Eloquent models with relationships
├── Services/              # Business logic (ScoringService, ChallengeService, ExcelImportService)
├── Policies/              # Authorization policies
├── Imports/               # Maatwebsite Excel import classes
└── Filament/
    ├── Resources/         # Admin CRUD resources
    └── Pages/             # Custom admin pages (Excel import)
```
