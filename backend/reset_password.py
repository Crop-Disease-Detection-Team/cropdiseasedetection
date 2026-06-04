from flask_bcrypt import Bcrypt

bcrypt = Bcrypt()

# Generate hash for Admin@123
admin_hash = bcrypt.generate_password_hash('Admin@123').decode('utf-8')
print(f"Admin@123 hash: {admin_hash}")

# Generate hash for User@123
user_hash = bcrypt.generate_password_hash('User@123').decode('utf-8')
print(f"User@123 hash: {user_hash}")