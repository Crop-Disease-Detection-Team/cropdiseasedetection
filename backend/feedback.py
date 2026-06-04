# feedback.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User
import smtplib
from email.message import EmailMessage
import os

feedback_bp = Blueprint('feedback', __name__)

# Email configuration (use environment variables in production)
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SENDER_EMAIL = 'your_email@gmail.com'      # Replace with your email
SENDER_PASSWORD = 'your_app_password'      # Replace with your app password
ADMIN_EMAIL = 'bikram204@gmail.com'

@feedback_bp.route('/feedback', methods=['POST'])
@jwt_required()
def submit_feedback():
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()
    message = data.get('message')
    if not message:
        return jsonify({'error': 'Message is required'}), 400

    # Prepare email
    msg = EmailMessage()
    msg['Subject'] = f'Feedback from {user.name}'
    msg['From'] = SENDER_EMAIL
    msg['To'] = ADMIN_EMAIL
    msg.set_content(f"""
    User Name: {user.name}
    User Email: {user.email}
    User ID: {user.id}
    
    Feedback Message:
    {message}
    """)

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(msg)
        return jsonify({'message': 'Feedback sent successfully'}), 200
    except Exception as e:
        print(f"Email error: {e}")
        return jsonify({'error': 'Failed to send email'}), 500