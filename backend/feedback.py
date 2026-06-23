# feedback.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Feedback
from datetime import datetime
import smtplib
from email.message import EmailMessage
import os
import logging

feedback_bp = Blueprint('feedback', __name__)
logger = logging.getLogger(__name__)

# ============================================
# EMAIL CONFIGURATION (Use environment variables)
# ============================================
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SENDER_EMAIL = os.environ.get('EMAIL_USER', 'bikram204sharma@gmail.com')
SENDER_PASSWORD = os.environ.get('EMAIL_PASSWORD', 'fnpexpxeuwnlukmz')
ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL', 'bikram204sharma@gmail.com')


def send_feedback_email(user_name, user_email, user_id, message):
    """Send feedback email to admin"""
    msg = EmailMessage()
    msg['Subject'] = f'🌾 Crop Disease AI - Feedback from {user_name}'
    msg['From'] = SENDER_EMAIL
    msg['To'] = ADMIN_EMAIL
    msg['Reply-To'] = user_email
    
    # HTML email content
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; }}
            .container {{ max-width: 600px; margin: 0 auto; background: #f8f9fa; border-radius: 12px; overflow: hidden; }}
            .header {{ background: #1a2e1f; color: white; padding: 20px; text-align: center; }}
            .content {{ padding: 20px; background: white; }}
            .user-info {{ background: #f0f2f5; padding: 15px; border-radius: 8px; margin-bottom: 20px; }}
            .feedback-message {{ background: #fff; border-left: 4px solid #1a2e1f; padding: 15px; margin-top: 10px; }}
            .footer {{ background: #f0f2f5; padding: 15px; text-align: center; font-size: 12px; color: #666; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h2> New Feedback Received</h2>
            </div>
            <div class="content">
                <div class="user-info">
                    <strong> User:</strong> {user_name}<br>
                    <strong> Email:</strong> {user_email}<br>
                    <strong> User ID:</strong> {user_id}<br>
                    <strong> Date:</strong> {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')}
                </div>
                <div class="feedback-message">
                    <strong> Feedback Message:</strong><br>
                    <p style="margin-top: 10px; line-height: 1.6;">{message}</p>
                </div>
            </div>
            <div class="footer">
                <p>Crop Disease Detection System - Nepal</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    plain_text = f"""
    New Feedback from {user_name}
    
    User: {user_name}
    Email: {user_email}
    User ID: {user_id}
    Date: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')}
    
    Feedback Message:
    {message}
    
    ---
    Crop Disease Detection System - Nepal
    """
    
    msg.set_content(plain_text)
    msg.add_alternative(html_content, subtype='html')
    
    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(msg)
        logger.info(f"Feedback email sent from {user_email}")
        return True, "Email sent"
    except Exception as e:
        logger.error(f"Email error: {e}")
        return False, str(e)


# ============================================
# SUBMIT FEEDBACK
# ============================================
@feedback_bp.route('/feedback', methods=['POST'])
@jwt_required()
def submit_feedback():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404

        data = request.get_json()
        message = data.get('message', '').strip()
        
        if not message:
            return jsonify({'error': 'Message is required'}), 400
        
        if len(message) < 5:
            return jsonify({'error': 'Message must be at least 5 characters'}), 400
        
        if len(message) > 2000:
            return jsonify({'error': 'Message too long (max 2000 characters)'}), 400
        
        # Save feedback to database
        try:
            feedback = Feedback(
                user_id=user.id,
                message=message,
                status='pending',
                created_at=datetime.utcnow()
            )
            db.session.add(feedback)
            db.session.commit()
            logger.info(f"Feedback saved for user {user.id}")
        except Exception as db_error:
            logger.error(f"Database error: {db_error}")
            # Continue to send email even if DB save fails
        
        # Send email notification
        email_sent, email_result = send_feedback_email(
            user.name, 
            user.email, 
            user.id, 
            message
        )
        
        if email_sent:
            return jsonify({
                'message': 'Feedback sent successfully! Thank you for your input.',
                'feedback_id': feedback.id if feedback.id else None
            }), 200
        else:
            # Email failed but feedback saved
            return jsonify({
                'message': 'Feedback saved. Our team will review it shortly.',
                'warning': 'Email notification failed, but your feedback was recorded.',
                'feedback_id': feedback.id if feedback.id else None
            }), 200
            
    except Exception as e:
        logger.error(f"Feedback submission error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500


# ============================================
# GET USER FEEDBACK HISTORY
# ============================================
@feedback_bp.route('/feedback/history', methods=['GET'])
@jwt_required()
def get_feedback_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get feedback for this user
        feedbacks = Feedback.query.filter_by(user_id=user.id).order_by(
            Feedback.created_at.desc()
        ).all()
        
        result = []
        for fb in feedbacks:
            result.append({
                'id': fb.id,
                'message': fb.message,
                'status': fb.status,
                'created_at': fb.created_at.isoformat() if fb.created_at else None
            })
        
        return jsonify({
            'total': len(result),
            'feedbacks': result
        }), 200
        
    except Exception as e:
        logger.error(f"Feedback history error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


# ============================================
# ADMIN: GET ALL FEEDBACK
# ============================================
@feedback_bp.route('/admin/feedback', methods=['GET'])
@jwt_required()
def get_all_feedback():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        # Check if user is admin
        if not user or user.role != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        status = request.args.get('status', None)
        
        query = Feedback.query
        if status:
            query = query.filter_by(status=status)
        
        feedbacks = query.order_by(Feedback.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        result = []
        for fb in feedbacks.items:
            result.append({
                'id': fb.id,
                'user_id': fb.user_id,
                'user_name': fb.user.name if fb.user else 'Unknown',
                'user_email': fb.user.email if fb.user else 'Unknown',
                'message': fb.message,
                'status': fb.status,
                'created_at': fb.created_at.isoformat() if fb.created_at else None
            })
        
        return jsonify({
            'total': feedbacks.total,
            'page': feedbacks.page,
            'pages': feedbacks.pages,
            'feedbacks': result
        }), 200
        
    except Exception as e:
        logger.error(f"Admin feedback error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


# ============================================
# ADMIN: UPDATE FEEDBACK STATUS
# ============================================
@feedback_bp.route('/admin/feedback/<int:feedback_id>/status', methods=['PUT'])
@jwt_required()
def update_feedback_status(feedback_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        # Check if user is admin
        if not user or user.role != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        feedback = Feedback.query.get(feedback_id)
        if not feedback:
            return jsonify({'error': 'Feedback not found'}), 404
        
        data = request.get_json()
        new_status = data.get('status')
        
        valid_statuses = ['pending', 'read', 'resolved']
        if new_status not in valid_statuses:
            return jsonify({'error': f'Invalid status. Must be one of: {valid_statuses}'}), 400
        
        feedback.status = new_status
        db.session.commit()
        
        return jsonify({
            'message': f'Feedback status updated to {new_status}',
            'feedback_id': feedback.id,
            'status': feedback.status
        }), 200
        
    except Exception as e:
        logger.error(f"Update feedback status error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500


# ============================================
# ADMIN: DELETE FEEDBACK
# ============================================
@feedback_bp.route('/admin/feedback/<int:feedback_id>', methods=['DELETE'])
@jwt_required()
def delete_feedback(feedback_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        # Check if user is admin
        if not user or user.role != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        feedback = Feedback.query.get(feedback_id)
        if not feedback:
            return jsonify({'error': 'Feedback not found'}), 404
        
        db.session.delete(feedback)
        db.session.commit()
        
        return jsonify({'message': 'Feedback deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Delete feedback error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500


# ============================================
# GET FEEDBACK STATISTICS (Admin)
# ============================================
@feedback_bp.route('/admin/feedback/stats', methods=['GET'])
@jwt_required()
def get_feedback_stats():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        # Check if user is admin
        if not user or user.role != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        total = Feedback.query.count()
        pending = Feedback.query.filter_by(status='pending').count()
        read = Feedback.query.filter_by(status='read').count()
        resolved = Feedback.query.filter_by(status='resolved').count()
        
        # Get last 7 days stats
        from datetime import timedelta
        week_ago = datetime.utcnow() - timedelta(days=7)
        last_week = Feedback.query.filter(Feedback.created_at >= week_ago).count()
        
        return jsonify({
            'total': total,
            'pending': pending,
            'read': read,
            'resolved': resolved,
            'last_7_days': last_week
        }), 200
        
    except Exception as e:
        logger.error(f"Feedback stats error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500