#  AI-Powered Crop Disease Detection System

A full‑stack web and mobile application that uses deep learning to identify crop diseases from leaf images and provides treatment recommendations, medicine suggestions, and Nepal‑specific cultivation advice.

---

##  Overview

Crop diseases cause 20–40% annual yield losses globally. Delayed or incorrect diagnosis in rural areas is the primary reason. This system empowers farmers to instantly identify diseases by uploading a leaf image via a **web browser** or **React Native mobile app**. It returns:

- Disease name & confidence
- Organic and chemical treatments
- Recommended medicines (with dosage & application method)
- Prevention tips & severity level
- **Nepal‑specific cultivation regions** (e.g., suitable areas for each crop)

The backend is built with **Flask** (Python) and exposes a RESTful API secured by **JWT**. The database (MySQL) stores 38 disease classes (across 14 crops), medicines, disease‑medicine mappings, user accounts, scan history, and admin logs.

---

##  Features

### For Farmers (Users)
- Register / Login with JWT
- Browse **crop‑wise disease library** (14 crops → 38 diseases) – view sample images, symptoms, treatments, medicines, cultivation areas
- Upload leaf image (camera / gallery) for instant prediction
- View scan history and favourite diseases
- Reset password via OTP email

### For Administrators
- Admin dashboard with system statistics (users, scans, diseases)
- View, search, activate/deactivate users
- Change user roles (user ↔ admin)
- View admin action logs

### Technical Highlights
- **ML model**: MobileNetV2 (transfer learning) trained on PlantVillage dataset – 90‑95% accuracy
- **Fallback model**: EfficientNetB0 (if MobileNetV2 fails to meet accuracy target)
- **Database**: 9 tables (users, diseases, medicines, mappings, scan_history, admin_logs, favorites, system_settings, password_resets)
- **Rich disease data**: organic/chemical treatments, medicine mapping (25+ medicines), **Nepal cultivation regions**, sample image URLs
- **Mobile app**: React Native with offline disease library and camera/gallery support
- **Web frontend**: Responsive HTML/CSS/JS with admin panel

---
### Dataset & Nepal‑Specific Cultivation Regions

The core disease classification model is trained on the PlantVillage dataset, which contains 54,303 labeled images of healthy and diseased leaves spanning 38 disease classes across 14 crop species (apple, blueberry, cherry, corn, grape, orange, peach, pepper, potato, raspberry, soybean, squash, strawberry, tomato). To make the system practically relevant for Nepal, we have extended the dataset with field‑adapted information: for every crop and disease, we added a cultivation_regions column that provides region‑specific advice on suitable growing areas within Nepal (e.g., “Terai: Jhapa, Morang, Sunsari; Mid‑hills: Kaski, Lalitpur; High hills: Jumla, Mustang”). This enhancement was based on Nepal’s agro‑ecological zones and expert agricultural knowledge. The complete dataset, including all 38 diseases with their symptoms, treatments, and Nepal‑specific cultivation regions, is available in the database/init.sql script. A detailed PDF document explaining the rationale, sources, and regional mapping is also uploaded to the GitHub repository (docs/datasetdiscription.pdf). This additional layer transforms the generic PlantVillage dataset into a context‑aware agricultural tool for Nepalese farmers.
##  Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Python 3.11, Flask, Flask‑SQLAlchemy, Flask‑JWT‑Extended, bcrypt |
| Database | MySQL 8.0, PyMySQL |
| ML Framework | TensorFlow 2.13, Keras, MobileNetV2 |
| Web Frontend | HTML5, CSS3, Vanilla JavaScript |
| Mobile App | React Native (Expo), Expo Image Picker, AsyncStorage |
| Deployment | Local (setup scripts provided) |

---

## Database Quick Start

The complete database schema with all initial data is provided in [`database/init.sql`](database/init.sql). It includes:

- 38 diseases (Apple, Blueberry, Cherry, Corn, Grape, Orange, Peach, Pepper, Potato, Raspberry, Soybean, Squash, Strawberry, Tomato)
- 25+ medicines (organic & chemical)
- Disease‑medicine mappings (56+ rows)
- Nepal‑specific cultivation regions for each disease
- Sample image URLs (placeholders – you need to place actual images in `backend/static/samples/`)
- Admin and test user accounts

To create the database:

```bash
mysql -u root -p < database/init.sql
```
---

### Web Frontend Authentication System
---

**Module:** Frontend Authentication Flow
**Date:** 29 May 2026

This document explains the complete frontend authentication workflow used in the Crop Disease Detection System.
The authentication process is implemented using three separate frontend pages:

1. `register.html` — User Registration Page
2. `verify-page.html` — Email OTP Verification Page
3. `login.html` — User Login Page

---

# Shared UI Components

All authentication pages contain common interface elements for consistency.

## Common Elements

* Dynamic page titles
* Current date display
* Responsive authentication layout
* Form validation messages
* Authentication branding section

## Example Titles

* Create Account
* Verify Email
* Welcome Back

## Date Format

```text
DD MMM YYYY
```

---

# 1. register.html — User Registration

## Overview

The registration page allows new users to create an account and begin the email verification process.

---

## Registration Form Fields

| Field              | Required |
| ------------------ | -------- |
| Full Name          | Yes      |
| Email Address      | Yes      |
| Phone Number       | Optional |
| District / Address | Optional |
| Password           | Yes      |
| Confirm Password   | Yes      |

---

## Registration Features

* Real-time password strength checking
* Password confirmation validation
* Required field validation
* Email verification initiation
* Responsive form design

---

## Registration Process

### Step 1 — User Enters Details

The user fills in the registration form with valid information.

---

### Step 2 — Frontend Sends API Request

```http
POST /api/auth/register
```

---

### Step 3 — Backend Registration Logic

The backend performs the following actions:

* Creates a new inactive user account
* Sets account status:

```text
is_active = false
email_verified = false
```

* Generates a 6-digit OTP code
* Sends verification OTP to the registered email address

---

### Step 4 — Redirect to Verification Page

After successful registration, the frontend redirects the user to:

```bash
verify-page.html?email=<email>
```

---

## Registration API Response

```json
{
  "requires_verification": true,
  "email": "user@example.com"
}
```

---

# 2. verify-page.html — Email Verification

## Overview

This page verifies the OTP sent to the user's email address and activates the account.

---

## Verification Inputs

* 6-digit OTP code
* Email address from URL query parameter

---

## Verification Features

* OTP auto-focus input fields
* OTP validation
* Resend verification code option
* 60-second resend cooldown timer
* Masked email display for privacy

---

## Verification Workflow

### Step 1 — Read Email from URL

Example:

```bash
?email=user@example.com
```

---

### Step 2 — User Enters OTP

The user enters the 6-digit verification code received via email.

---

### Step 3 — Send Verification Request

```http
POST /api/auth/verify-email
```

Request body:

```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

---

### Step 4 — Backend Activates Account

Backend updates account status:

```text
is_active = true
email_verified = true
```

---

### Step 5 — Redirect to Login Page

After successful verification:

```bash
login.html
```

The user receives a success confirmation message.

---

# Resend Verification Code

Users can request another OTP using:

```http
POST /api/auth/resend-verification
```

## Cooldown Protection

* 60-second cooldown timer
* Prevents OTP spam requests

---

# 3. login.html — User Login

## Overview

The login page allows verified users to securely access the system.

---

## Login Fields

| Field         | Required |
| ------------- | -------- |
| Email Address | Yes      |
| Password      | Yes      |

---

## Login Features

* JWT-based authentication
* Role-based dashboard redirection
* Email verification checking
* Forgot password support
* Secure token storage

---

## Login Workflow

### Step 1 — User Enters Credentials

The user submits email and password.

---

### Step 2 — Frontend Sends Login Request

```http
POST /api/auth/login
```

---

### Step 3 — Backend Validation

Backend validates:

* Email and password correctness
* Email verification status

```text
email_verified == true
```

---

# Handling Unverified Users

If the email is not verified:

* Backend automatically sends a new OTP
* Backend response:

```json
{
  "requires_verification": true
}
```

Frontend redirects user to:

```bash
verify-page.html
```

---

# Successful Login Response

Backend returns authentication tokens:

```json
{
  "access_token": "...",
  "refresh_token": "..."
}
```

Frontend stores tokens using:

```javascript
localStorage
```

---

# Dashboard Redirection

After successful login:

| User Role   | Redirect Page          |
| ----------- | ---------------------- |
| Normal User | `user-dashboard.html`  |
| Admin User  | `admin-dashboard.html` |

---

# Forgot Password Support

The login page includes password recovery functionality:

```bash
forgot-password.html
```

---

# Backend Authentication API Endpoints

| Endpoint                        | Method | Description             |
| ------------------------------- | ------ | ----------------------- |
| `/api/auth/register`            | POST   | Register new user       |
| `/api/auth/verify-email`        | POST   | Verify email OTP        |
| `/api/auth/resend-verification` | POST   | Resend verification OTP |
| `/api/auth/login`               | POST   | Authenticate user       |

---

# Integration Configuration

## Base API URL

```bash
http://localhost:5000/api
```

---

## Integration Notes

* Environment variables can be configured for deployment
* Email verification is mandatory before login
* Unverified login attempts automatically trigger OTP resend
* Authentication pages are reusable and modular
* Compatible with:

  * Web frontend
  * Mobile applications
  * External API integrations

---

# Authentication Flow Architecture

```text
register.html
      ↓
verify-page.html
      ↓
login.html
      ↓
dashboard
```

---

# Technology Stack

## Frontend Technologies

* HTML5
* CSS3
* JavaScript

## Backend Integration Technologies

* REST API
* JWT Authentication
* Email OTP Verification

---

# Security Features

* Password validation
* Email verification system
* JWT token authentication
* Protected dashboard access
* OTP expiration handling
* OTP resend cooldown protection
* Role-based authorization
* Secure authentication workflow

