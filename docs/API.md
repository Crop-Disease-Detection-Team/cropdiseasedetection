# AgriVision AI API

Base URL: `/api`

## Auth
- `POST /auth/signup/`
- `POST /auth/verify-otp/`
- `POST /auth/verify-email/`
- `POST /auth/login/`
- `POST /auth/token/refresh/`
- `POST /auth/forgot-password/`
- `POST /auth/reset-password/`
- `POST /auth/logout/`

## Profile
- `GET /auth/me/`
- `PATCH /auth/me/`

## Dashboard
- `GET /scans/dashboard/`

## Scans
- `POST /scans/predict/`
- `GET /scans/history/`
- `GET /scans/history/<id>/`
- `DELETE /scans/history/<id>/`

## Disease library
- `GET /scans/diseases/`
- `GET /scans/diseases/<id>/`

## Example prediction response
```json
{
  "scan_id": 18,
  "crop_name": "Tomato",
  "scientific_name": "Solanum lycopersicum",
  "disease_name": "Tomato___Late_blight",
  "confidence": 0.982,
  "severity": "High",
  "description": "Devastating oomycete disease.",
  "symptoms": ["Water-soaked lesions", "White fuzzy growth under leaves"],
  "causes": ["Cool weather", "Persistent moisture"],
  "organic_treatments": ["Copper spray", "Neem oil"],
  "chemical_treatments": ["Mancozeb", "Metalaxyl"],
  "prevention": ["Water at the base", "Improve spacing"],
  "affected_parts": ["Leaves", "Fruit"],
  "duration": "Wet season",
  "weather": "Cool and humid",
  "possible_matches": [
    {"name": "Tomato___Early_blight", "confidence": 0.012},
    {"name": "Tomato___Septoria_leaf_spot", "confidence": 0.006}
  ]
}
```
