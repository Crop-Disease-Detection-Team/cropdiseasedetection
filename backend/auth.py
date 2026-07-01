from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity, get_jwt
)
from models import db, User, TokenBlacklist
from datetime import datetime, timedelta
import re
import logging
import random
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import uuid
import os
from dotenv import load_dotenv
from werkzeug.utils import secure_filename

# Load environment variables
load_dotenv()

auth_bp = Blueprint('auth', __name__)
logger = logging.getLogger(__name__)

# ============================================
# EMAIL CONFIGURATION - SECURED WITH ENV VAR
# ============================================
EMAIL_HOST = "smtp.gmail.com"
EMAIL_PORT = 587
EMAIL_USER = os.environ.get('EMAIL_USER', 'bikram204sharma@gmail.com')
EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD', '')

# ============================================
# RATE LIMITING FOR LOGIN ATTEMPTS
# ============================================
failed_attempts = {}  # {email: {'count': int, 'last_attempt': datetime}}

def check_rate_limit(email):
    """Check if email has exceeded failed login attempts"""
    if email in failed_attempts:
        data = failed_attempts[email]
        if data['count'] >= 5:
            time_since_last = (datetime.utcnow() - data['last_attempt']).total_seconds()
            if time_since_last < 900:  # 15 minutes
                remaining = int(900 - time_since_last)
                return False, f"Too many failed attempts. Try again in {remaining} seconds."
            else:
                del failed_attempts[email]
    return True, None

def record_failed_attempt(email):
    """Record a failed login attempt"""
    if email in failed_attempts:
        failed_attempts[email]['count'] += 1
        failed_attempts[email]['last_attempt'] = datetime.utcnow()
    else:
        failed_attempts[email] = {
            'count': 1,
            'last_attempt': datetime.utcnow()
        }

def clear_failed_attempts(email):
    """Clear failed attempts on successful login"""
    if email in failed_attempts:
        del failed_attempts[email]

def send_email(to_email, otp, name="", purpose="reset"):
    """Send email for password reset or email verification"""

    if purpose == "verification":
        subject = "Verify Your Email - Crop Disease Detection System"
        title = "Email Verification"
        message = "Please verify your email address to complete registration."
    else:
        subject = "Password Reset Request - Crop Disease Detection System"
        title = "Password Reset"
        message = "We received a request to reset your password."

    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }}
            .container {{ max-width: 500px; margin: 0 auto; background: white; border-radius: 15px; padding: 30px; box-shadow: 0 5px 15px rgba(0,0,0,0.1); }}
            .header {{ text-align: center; border-bottom: 3px solid #1a2e1f; padding-bottom: 20px; }}
            .header h1 {{ color: #1a2e1f; margin: 0; }}
            .otp-code {{ text-align: center; font-size: 42px; font-weight: bold; letter-spacing: 8px; color: #1a2e1f; background: #f0fdf4; padding: 20px; border-radius: 10px; margin: 20px 0; }}
            .footer {{ text-align: center; margin-top: 30px; color: #999; font-size: 12px; }}
            .warning {{ color: #dc3545; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🌾 {title}</h1>
            </div>
            <p>Hello <strong>{name if name else 'User'}</strong>,</p>
            <p>{message}</p>
            <p>Your verification code is:</p>
            <div class="otp-code">{otp}</div>
            <p>This code is valid for <strong>5 minutes</strong>.</p>
            <p class="warning">If you didn't request this, please ignore this email.</p>
            <div class="footer">
                <p>Crop Disease Detection System - Nepal</p>
                <p>© 2024 All Rights Reserved</p>
            </div>
        </div>
    </body>
    </html>
    """

    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = EMAIL_USER
        msg['To'] = to_email
        msg.attach(MIMEText(html_content, 'html'))

        with smtplib.SMTP(EMAIL_HOST, EMAIL_PORT) as server:
            server.starttls()
            if EMAIL_PASSWORD:
                server.login(EMAIL_USER, EMAIL_PASSWORD)
            server.send_message(msg)
        print(f"✅ Email sent to {to_email}")
        return True, "Email sent"
    except Exception as e:
        print(f"❌ Email error: {e}")
        print(f"\n📧 OTP for {to_email}: {otp}\n")
        return True, "OTP generated (check terminal)"

def generate_otp():
    return f"{random.randint(100000, 999999):06d}"

# ============================================
# VALIDATION FUNCTIONS
# ============================================

def validate_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def validate_password(password):
    errors = []
    if len(password) < 8:
        errors.append("Password must be at least 8 characters")
    if not re.search(r'[A-Z]', password):
        errors.append("Password must contain 1 uppercase letter")
    if not re.search(r'[a-z]', password):
        errors.append("Password must contain 1 lowercase letter")
    if not re.search(r'[0-9]', password):
        errors.append("Password must contain 1 number")
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        errors.append("Password must contain 1 special character")
    return len(errors) == 0, errors

# ============================================
# ALLOWED FILE EXTENSIONS FOR PROFILE PICS
# ============================================
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ============================================
# REGISTER ENDPOINT
# ============================================

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()

        email = data.get('email', '').lower().strip()
        name = data.get('name', '').strip()
        password = data.get('password', '')
        phone = data.get('phone', '')
        address = data.get('address', '')

        if not name or not email or not password:
            return jsonify({'error': 'Name, email and password required'}), 400

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        existing_user = User.query.filter_by(email=email).first()
        if existing_user:
            if existing_user.email_verified:
                return jsonify({'error': 'Email already registered. Please login.'}), 409
            else:
                db.session.delete(existing_user)
                db.session.commit()

        is_valid, error_msg = validate_password(password)
        if not is_valid:
            return jsonify({'error': error_msg[0] if error_msg else 'Invalid password'}), 400

        otp = generate_otp()

        user = User(
            name=name,
            email=email,
            phone=phone,
            address=address,
            role='user',
            is_active=False,
            email_verified=False,
            verification_otp=otp,
            otp_expires_at=datetime.utcnow() + timedelta(minutes=5),
            otp_last_sent=datetime.utcnow()
        )
        user.set_password(password)

        db.session.add(user)
        db.session.commit()

        success, message = send_email(email, otp, name, purpose="verification")

        if success:
            return jsonify({
                'message': 'Registration successful! Please check your email for verification code.',
                'requires_verification': True,
                'email': email
            }), 201
        else:
            db.session.delete(user)
            db.session.commit()
            return jsonify({'error': 'Failed to send verification email. Please try again.'}), 500

    except Exception as e:
        print(f"Registration error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# VERIFY EMAIL
# ============================================

@auth_bp.route('/verify-email', methods=['POST'])
def verify_email():
    try:
        data = request.get_json()
        email = data.get('email', '').lower().strip()
        otp = data.get('otp', '').strip()

        user = User.query.filter_by(email=email).first()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user.email_verified:
            return jsonify({'error': 'Email already verified. Please login.'}), 400

        if not user.verification_otp or user.verification_otp != otp:
            return jsonify({'error': 'Invalid verification code'}), 400

        if datetime.utcnow() > user.otp_expires_at:
            return jsonify({'error': 'Verification code expired. Please register again.'}), 400

        user.email_verified = True
        user.is_active = True
        user.verification_otp = None
        user.otp_expires_at = None
        user.otp_last_sent = None
        db.session.commit()

        return jsonify({
            'message': 'Email verified successfully! You can now login.',
            'verified': True
        }), 200

    except Exception as e:
        print(f"Verification error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# RESEND VERIFICATION
# ============================================

@auth_bp.route('/resend-verification', methods=['POST'])
def resend_verification():
    try:
        data = request.get_json()
        email = data.get('email', '').lower().strip()

        user = User.query.filter_by(email=email).first()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user.email_verified:
            return jsonify({'error': 'Email already verified. Please login.'}), 400

        if user.otp_last_sent:
            time_since_last = (datetime.utcnow() - user.otp_last_sent).total_seconds()
            if time_since_last < 60:
                remaining = 60 - int(time_since_last)
                return jsonify({'error': f'Please wait {remaining} seconds before requesting again.'}), 429

        otp = generate_otp()
        user.verification_otp = otp
        user.otp_expires_at = datetime.utcnow() + timedelta(minutes=5)
        user.otp_last_sent = datetime.utcnow()
        db.session.commit()

        success, message = send_email(email, otp, user.name, purpose="verification")

        if success:
            return jsonify({'message': 'Verification code resent. Please check your email.'}), 200
        else:
            return jsonify({'error': 'Failed to send email. Please try again.'}), 500

    except Exception as e:
        print(f"Resend error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# LOGIN ENDPOINT
# ============================================

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email', '').lower().strip()
        password = data.get('password', '')

        allowed, error_msg = check_rate_limit(email)
        if not allowed:
            return jsonify({'error': error_msg}), 429

        user = User.query.filter_by(email=email).first()

        if not user or not user.check_password(password):
            record_failed_attempt(email)
            return jsonify({'error': 'Invalid email or password'}), 401

        if not user.email_verified:
            otp = generate_otp()
            user.verification_otp = otp
            user.otp_expires_at = datetime.utcnow() + timedelta(minutes=5)
            user.otp_last_sent = datetime.utcnow()
            db.session.commit()
            send_email(email, otp, user.name, purpose="verification")

            return jsonify({
                'error': 'Email not verified. A new verification code has been sent to your email.',
                'requires_verification': True,
                'email': email
            }), 403

        if not user.is_active:
            return jsonify({'error': 'Account deactivated. Please contact admin.'}), 403

        clear_failed_attempts(email)

        user.last_login = datetime.utcnow()
        db.session.commit()

        # FIX: Use string identity, not int
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))

        return jsonify({
            'message': 'Login successful',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'user': user.to_dict()
        }), 200

    except Exception as e:
        print(f"Login error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# LOGOUT ENDPOINT
# ============================================

@auth_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    try:
        jwt_data = get_jwt()
        jti = jwt_data.get('jti')
        if jti:
            # FIX: Check if TokenBlacklist table exists
            try:
                blacklisted = TokenBlacklist(jti=jti)
                db.session.add(blacklisted)
                db.session.commit()
            except Exception as e:
                print(f"TokenBlacklist error: {e}")
                # If TokenBlacklist doesn't exist, just log the error
                pass
        return jsonify({'message': 'Logged out successfully'}), 200
    except Exception as e:
        print(f"Logout error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Logout failed'}), 500

# ============================================
# FORGOT PASSWORD
# ============================================

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    try:
        data = request.get_json()
        email = data.get('email', '').lower().strip()

        if not email:
            return jsonify({'error': 'Email is required'}), 400

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        user = User.query.filter_by(email=email).first()

        if not user:
            return jsonify({'message': 'If registered, OTP will be sent'}), 200

        if user.otp_last_sent:
            time_since_last = (datetime.utcnow() - user.otp_last_sent).total_seconds()
            if time_since_last < 60:
                remaining = 60 - int(time_since_last)
                return jsonify({'error': f'Please wait {remaining} seconds before requesting again.'}), 429

        otp = generate_otp()
        user.verification_otp = otp
        user.otp_expires_at = datetime.utcnow() + timedelta(minutes=5)
        user.otp_last_sent = datetime.utcnow()
        db.session.commit()

        success, msg = send_email(email, otp, user.name, purpose="reset")

        if success:
            return jsonify({'message': 'OTP sent to your email'}), 200
        else:
            return jsonify({'error': 'Failed to send email'}), 500

    except Exception as e:
        print(f"Forgot password error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# VERIFY RESET OTP
# ============================================

@auth_bp.route('/verify-reset-otp', methods=['POST'])
def verify_reset_otp():
    try:
        data = request.get_json()
        email = data.get('email', '').lower().strip()
        otp = data.get('otp', '').strip()

        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.verification_otp or user.verification_otp != otp:
            return jsonify({'error': 'Invalid OTP'}), 400

        if datetime.utcnow() > user.otp_expires_at:
            return jsonify({'error': 'OTP expired'}), 400

        temp_token = create_access_token(
            identity=email,
            expires_delta=timedelta(minutes=5)
        )

        return jsonify({
            'message': 'OTP verified',
            'reset_token': temp_token
        }), 200

    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# RESET PASSWORD
# ============================================

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    try:
        data = request.get_json()
        email = data.get('email', '').lower().strip()
        otp = data.get('otp', '').strip()
        new_password = data.get('new_password', '')

        user = User.query.filter_by(email=email).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.verification_otp or user.verification_otp != otp:
            return jsonify({'error': 'Invalid OTP'}), 400

        if datetime.utcnow() > user.otp_expires_at:
            return jsonify({'error': 'OTP expired'}), 400

        is_valid, errors = validate_password(new_password)
        if not is_valid:
            return jsonify({'error': errors[0] if errors else 'Invalid password'}), 400

        user.set_password(new_password)
        user.verification_otp = None
        user.otp_expires_at = None
        db.session.commit()

        return jsonify({'message': 'Password reset successful!'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# GET CURRENT USER - FIXED
# ============================================

@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    try:
        user_id = get_jwt_identity()
        # FIX: Convert to int properly
        user = User.query.get(int(user_id))
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify({'user': user.to_dict()}), 200
    except Exception as e:
        print(f"Error in /me: {str(e)}")
        return jsonify({'error': str(e)}), 500

# ============================================
# CHANGE PASSWORD
# ============================================

@auth_bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        data = request.get_json()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.check_password(data.get('old_password')):
            return jsonify({'error': 'Current password is incorrect'}), 401

        is_valid, errors = validate_password(data.get('new_password'))
        if not is_valid:
            return jsonify({'error': errors[0] if errors else 'Invalid password'}), 400

        user.set_password(data['new_password'])
        db.session.commit()

        return jsonify({'message': 'Password changed successfully'}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# REFRESH TOKEN
# ============================================

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    try:
        user_id = get_jwt_identity()
        new_token = create_access_token(identity=str(user_id))
        return jsonify({'access_token': new_token}), 200
    except Exception as e:
        return jsonify({'error': 'Invalid refresh token'}), 401

# ============================================
# UPDATE PROFILE
# ============================================

@auth_bp.route('/update-profile', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))

        if not user:
            return jsonify({'error': 'User not found'}), 404

        data = request.get_json()

        if 'name' in data and data['name']:
            user.name = data['name'].strip()
        if 'email' in data and data['email']:
            if validate_email(data['email']):
                user.email = data['email'].lower().strip()
            else:
                return jsonify({'error': 'Invalid email format'}), 400
        if 'phone' in data:
            user.phone = data['phone']
        if 'address' in data:
            user.address = data['address']

        db.session.commit()

        return jsonify({
            'message': 'Profile updated successfully',
            'user': user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# ============================================
# UPLOAD PROFILE PICTURE - FIXED
# ============================================

@auth_bp.route('/upload-profile-pic', methods=['POST'])
@jwt_required()
def upload_profile_pic():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if 'profile_pic' not in request.files:
            return jsonify({'error': 'No file provided'}), 400

        file = request.files['profile_pic']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400

        # Validate file type
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, gif, webp'}), 400

        # Secure the filename
        filename = secure_filename(file.filename)
        
        upload_dir = 'uploads/profiles'
        os.makedirs(upload_dir, exist_ok=True)

        # Generate unique filename
        file_extension = filename.rsplit('.', 1)[1].lower() if '.' in filename else 'jpg'
        new_filename = f"profile_{user_id}_{uuid.uuid4().hex[:8]}.{file_extension}"
        filepath = os.path.join(upload_dir, new_filename)

        file.save(filepath)

        profile_url = f"/uploads/profiles/{new_filename}"
        user.profile_pic = profile_url
        db.session.commit()

        return jsonify({
            'message': 'Profile picture updated successfully',
            'profile_pic_url': profile_url,
            'user': user.to_dict()
        }), 200

    except Exception as e:
        print(f"Error uploading profile picture: {str(e)}")
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# ============================================
# HEALTH CHECK ENDPOINT - ADD THIS
# ============================================

@auth_bp.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'auth'
    }), 200