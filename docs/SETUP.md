# AgriVision AI — Local Setup Guide

This guide provides step-by-step instructions for running the complete AgriVision AI stack on your local machine.

---

## Prerequisites
- **Python**: 3.10+
- **Node.js**: 18+ (optional, for frontend tools)
- **Flutter SDK**: 3.19+ (Stable channel)
- **PostgreSQL**: 14+
- **Git**

---

## Backend Setup (Django + PostgreSQL)

### 1. Clone & Navigate
```bash
git clone <repository-url>
cd agrivision_ai/backend
```

### 2. Virtual Environment
```bash
python -m venv venv
# Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# Linux/macOS:
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Database Setup
Create a PostgreSQL database named `agrivision_db` or adjust credentials in `.env`:

```env
DEBUG=True
SECRET_KEY=your-django-secret-key
DB_NAME=agrivision_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=127.0.0.1
DB_PORT=5432
```

### 5. Run Migrations & Seed Initial Data
```bash
python manage.py migrate
python manage.py seed_data
```

### 6. Create Superuser (Admin)
```bash
python manage.py createsuperuser
```

### 7. Run Development Server
```bash
python manage.py runserver 0.0.0.0:8000
```
API Root: `http://127.0.0.1:8000/api/`

---

## Frontend Setup (Flutter)

### 1. Navigate to Frontend Directory
```bash
cd ../frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure API Base URL
Edit `lib/core/config/app_config.dart` or set environment variables:
```dart
static const String apiBaseUrl = 'http://127.0.0.1:8000/api/'; // For Windows/Web/Desktop
// Use http://10.0.2.2:8000/api/ for Android Emulator
```

### 4. Run Flutter App
```bash
flutter run -d chrome # Or -d windows, -d android
```

---

## Running Unit Tests

### Backend Tests:
```bash
cd backend
python manage.py test
```
