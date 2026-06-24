import random
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta

# GMAIL SMTP CONFIGURATION
EMAIL_HOST = "smtp.gmail.com"
EMAIL_PORT = 587
EMAIL_USER = "bikram204sharma@gmail.com"
EMAIL_PASSWORD = "fnpexpxeuwnlukmz"  

def generate_otp():
    """Generate 6-digit OTP"""
    return f"{random.randint(100000, 999999):06d}"

def can_send_otp(user):
    """Check if user can send OTP (1 minute cooldown)"""
    if not hasattr(user, 'otp_last_sent') or not user.otp_last_sent:
        return True, 0
    
    time_since_last = (datetime.utcnow() - user.otp_last_sent).total_seconds()
    if time_since_last < 60:
        remaining = 60 - int(time_since_last)
        return False, remaining
    
    return True, 0

def save_otp_for_user(user, otp, db_session):
    """Save OTP for user with expiration (5 minutes)"""
    user.verification_otp = otp
    user.otp_expires_at = datetime.utcnow() + timedelta(minutes=5)
    user.otp_last_sent = datetime.utcnow()
    db_session.commit()

def is_otp_valid_for_user(user, otp):
    """Check if OTP is valid for user"""
    if not user.verification_otp:
        return False, "No OTP requested. Please request a new one."
    
    if user.verification_otp != otp:
        return False, "Invalid OTP. Please try again."
    
    if datetime.utcnow() > user.otp_expires_at:
        return False, "OTP expired. Please request a new one."
    
    return True, "OTP verified successfully"

def clear_user_otp(user, db_session):
    """Clear OTP after verification"""
    user.verification_otp = None
    user.otp_expires_at = None
    user.otp_last_sent = None
    db_session.commit()

def send_otp_email(to_email, otp, name="", purpose="reset"):
    """Send OTP email to ANY email address"""
    
    if purpose == "verification":
        subject = "Verify Your Email - Crop Disease Detection System"
        title = "Email Verification"
    else:
        subject = "Password Reset Request - Crop Disease Detection System"
        title = "Reset Your Password"
    
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
            <p>We received a request to {purpose} your password. Use the verification code below:</p>
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
            server.login(EMAIL_USER, EMAIL_PASSWORD)
            server.send_message(msg)
        
        print(f" OTP sent to {to_email}")
        return True, "Verification code sent to your email"
        
    except Exception as e:
        print(f" Email error: {e}")
        print(f"\n OTP for {to_email}: {otp}\n")
        return True, "Verification code generated (check terminal for OTP)"