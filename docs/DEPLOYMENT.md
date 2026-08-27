# AgriVision AI — Production Deployment Guide

## 1. Environment Preparation
- **Server OS**: Ubuntu 22.04 LTS
- **Database**: PostgreSQL 14+
- **Reverse Proxy**: Nginx
- **WSGI Application Server**: Gunicorn

---

## 2. Backend Deployment

### Environment Configuration
Create `/etc/agrivision/.env`:
```env
DEBUG=False
SECRET_KEY=your-production-secret-key-32-chars-long
ALLOWED_HOSTS=api.agrivision.ai,127.0.0.1
DB_NAME=agrivision_prod
DB_USER=agrivision_user
DB_PASSWORD=SecurePassword123!
DB_HOST=localhost
DB_PORT=5432
```

### Systemd Service
Create `/etc/systemd/system/agrivision.service`:
```ini
[Unit]
Description=AgriVision AI Django Backend
After=network.target postgresql.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/agrivision_ai/backend
ExecStart=/var/www/agrivision_ai/backend/venv/bin/gunicorn \
          --workers 4 \
          --bind 127.0.0.1:8000 \
          config.wsgi:application

[Install]
WantedBy=multi-user.target
```

---

## 3. Nginx Configuration

Create `/etc/nginx/sites-available/agrivision`:
```nginx
server {
    listen 80;
    server_name api.agrivision.ai;

    client_max_body_size 15M;

    location /static/ {
        alias /var/www/agrivision_ai/backend/staticfiles/;
    }

    location /media/ {
        alias /var/www/agrivision_ai/backend/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site and restart Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/agrivision /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

---

## 4. Frontend Release Build

### Web Build
```bash
cd frontend
flutter build web --release
```

### Android APK Build
```bash
flutter build apk --release --split-per-abi
```
Outputs: `build/app/outputs/flutter-apk/app-release.apk`
