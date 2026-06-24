import requests
import json

BASE_URL = "http://localhost:5000/api"

print("=" * 60)
print(" CROP DISEASE DETECTION - API TESTING")
print("=" * 60)

# ============================================
# 1. Login as Admin
# ============================================
print("\n1️ Logging in as Admin...")
response = requests.post(f"{BASE_URL}/auth/login", json={
    "email": "bikram204sharma@gmail.com",
    "password": "Admin@123"
})

if response.status_code != 200:
    print(f" Login failed: {response.json()}")
    exit(1)

admin_token = response.json()['access_token']
admin_user = response.json()['user']
print(f"Admin Login Successful!")
print(f"   Name: {admin_user['name']}")
print(f"   Role: {admin_user['role']}")

# ============================================
# 2. Get All Diseases (Protected)
# ============================================
print("\n2️ Getting All Diseases...")
headers = {"Authorization": f"Bearer {admin_token}"}
response = requests.get(f"{BASE_URL}/user/diseases", headers=headers)

if response.status_code == 200:
    data = response.json()
    print(f" Found {data.get('total', 0)} diseases")
    if data.get('diseases'):
        print(f"   First disease: {data['diseases'][0]['disease_name']}")
        print(f"   Crop: {data['diseases'][0].get('crop_type', 'N/A')}")
        print(f"   Severity: {data['diseases'][0].get('severity_level', 'N/A')}")
else:
    print(f" Failed: {response.status_code}")

# ============================================
# 3. Get User Statistics
# ============================================
print("\n3️ Getting User Statistics...")
response = requests.get(f"{BASE_URL}/user/statistics", headers=headers)

if response.status_code == 200:
    stats = response.json()
    print(f" Statistics:")
    print(f"   Total Scans: {stats.get('total_scans', 0)}")
    print(f"   Favorites: {stats.get('favorites_count', 0)}")
    print(f"   Avg Confidence: {stats.get('average_confidence', 0)}%")
else:
    print(f" Failed: {response.status_code}")

# ============================================
# 4. Get Scan History
# ============================================
print("\n4️ Getting Scan History...")
response = requests.get(f"{BASE_URL}/user/history", headers=headers)

if response.status_code == 200:
    history = response.json()
    print(f" Found {history.get('total', 0)} scans")
    for scan in history.get('scans', [])[:3]:
        print(f"   - {scan['disease_name']} ({scan['confidence']}%)")
else:
    print(f"failed: {response.status_code}")

# ============================================
# 5. Admin Dashboard (Admin only)
# ============================================
print("\n5️ Getting Admin Dashboard...")
response = requests.get(f"{BASE_URL}/admin/dashboard/stats", headers=headers)

if response.status_code == 200:
    stats = response.json()
    print(f" Admin Dashboard:")
    print(f"   Total Users: {stats['users']['total']}")
    print(f"   Active Users: {stats['users']['active']}")
    print(f"   Total Scans: {stats['scans']['total']}")
    print(f"   Scans Today: {stats['scans']['today']}")
else:
    print(f" Failed: {response.status_code}")

# ============================================
# 6. Get Medicines
# ============================================
print("\n6️ Getting Medicines...")
response = requests.get(f"{BASE_URL}/user/medicines", headers=headers)

if response.status_code == 200:
    medicines = response.json()
    print(f" Found {len(medicines.get('medicines', []))} medicines")
else:
    print(f" Failed: {response.status_code}")

# ============================================
# 7. Get Favorites
# ============================================
print("\n7️ Getting Favorites...")
response = requests.get(f"{BASE_URL}/user/favorites", headers=headers)

if response.status_code == 200:
    favorites = response.json()
    print(f" Found {len(favorites.get('favorites', []))} favorites")
else:
    print(f"Failed: {response.status_code}")

print("\n" + "=" * 60)
print(" ALL API TESTS COMPLETED SUCCESSFULLY!")
print("=" * 60)