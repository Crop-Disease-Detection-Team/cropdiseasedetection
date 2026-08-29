from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, ScanHistory, Disease
from sqlalchemy import or_, func
from functools import wraps
from datetime import datetime, timedelta

admin_bp = Blueprint('admin', __name__)

#ADMIN CHECK FUNCTION


def is_admin():
    """Check if current user is admin"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        return user and user.role == 'admin'
    except Exception:
        return False

def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not is_admin():
            return jsonify({'error': 'Admin access required'}), 403
        return f(*args, **kwargs)
    return decorated



#ADMIN DASHBOARD STATISTICS


@admin_bp.route('/dashboard/stats', methods=['GET'])
@jwt_required()
@admin_required
def get_stats():
    try:
        total_users = User.query.count()
        active_users = User.query.filter(User.last_login.isnot(None)).count()
        total_scans = ScanHistory.query.count()
        total_diseases = Disease.query.count()

        today = datetime.utcnow().date()
        today_scans = ScanHistory.query.filter(
            func.date(ScanHistory.scanned_at) == today
        ).count()

        recent_activities = []
        recent_scans = ScanHistory.query.order_by(
            ScanHistory.scanned_at.desc()
        ).limit(10).all()

        for scan in recent_scans:
            user = User.query.get(scan.user_id)
            recent_activities.append({
                'type': 'scan',
                'user_name': user.name if user else 'Unknown',
                'disease_name': scan.disease_name,
                'timestamp': scan.scanned_at.isoformat() if scan.scanned_at else None
            })

        return jsonify({
            'users': {
                'total': total_users,
                'active': active_users,
                'inactive': total_users - active_users
            },
            'scans': {
                'total': total_scans,
                'today': today_scans
            },
            'diseases': {
                'total': total_diseases
            },
            'recent_activities': recent_activities
        }), 200

    except Exception as e:
        print(f"Error in get_stats: {str(e)}")
        return jsonify({'error': str(e)}), 500


# GET ALL USERS (with search and pagination)


@admin_bp.route('/users', methods=['GET'])
@jwt_required()
@admin_required
def get_all_users():
    try:
        search = request.args.get('search', '').strip()
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)

        query = User.query

        if search:
            query = query.filter(
                or_(
                    User.name.ilike(f'%{search}%'),
                    User.email.ilike(f'%{search}%'),
                    User.phone.ilike(f'%{search}%')
                )
            )

        paginated = query.order_by(User.id.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

        user_list = []
        for u in paginated.items:
            # FIX: safely check created_at with hasattr
            registered_on = None
            if hasattr(u, 'created_at') and u.created_at:
                registered_on = u.created_at.isoformat()

            user_list.append({
                'id': u.id,
                'name': u.name,
                'email': u.email,
                'phone': u.phone if u.phone else None,
                'address': u.address if u.address else None,
                'role': u.role,
                'is_active': u.is_active,
                'has_logged_in': u.last_login is not None,
                'last_login': u.last_login.isoformat() if u.last_login else None,
                'registered_on': registered_on,
                'total_scans': ScanHistory.query.filter_by(user_id=u.id).count()
            })

        return jsonify({
            'users': user_list,
            'total': paginated.total,
            'page': page,
            'per_page': per_page,
            'total_pages': paginated.pages
        }), 200

    except Exception as e:
        print(f"Error in get_all_users: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# GET SINGLE USER DETAILS
# ============================================

@admin_bp.route('/users/<int:user_id>', methods=['GET'])
@jwt_required()
@admin_required
def get_user_details(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        recent_scans = ScanHistory.query.filter_by(user_id=user.id).order_by(
            ScanHistory.scanned_at.desc()
        ).limit(10).all()

        total_scans = ScanHistory.query.filter_by(user_id=user.id).count()

        common_diseases = db.session.query(
            ScanHistory.disease_name,
            func.count(ScanHistory.disease_name).label('count')
        ).filter(
            ScanHistory.user_id == user.id
        ).group_by(
            ScanHistory.disease_name
        ).order_by(
            func.count(ScanHistory.disease_name).desc()
        ).limit(5).all()

        # FIX: safely get created_at
        registered_on = None
        if hasattr(user, 'created_at') and user.created_at:
            registered_on = user.created_at.isoformat()

        user_data = {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'phone': user.phone if user.phone else None,
            'address': user.address if user.address else None,
            'role': user.role,
            'is_active': user.is_active,
            'email_verified': user.email_verified,
            'profile_pic': user.profile_pic if hasattr(user, 'profile_pic') else None,
            'registered_on': registered_on,
            'last_login': user.last_login.isoformat() if user.last_login else None,
            'total_scans': total_scans,
            'common_diseases': [
                {
                    'name': (d[0] or 'Unknown').replace('___', ' - ').replace('_', ' '),
                    'count': d[1]
                }
                for d in common_diseases
            ],
            'recent_scans': [{
                'id': s.id,
                'disease_name': (s.disease_name or 'Unknown').replace('___', ' - ').replace('_', ' '),
                # FIX: safe confidence formatting whether stored as 0-1 or 0-100
                'confidence': float(round(s.confidence * 100, 2)) if s.confidence and s.confidence <= 1 else float(round(s.confidence or 0, 2)),
                'severity': s.severity if hasattr(s, 'severity') else 'medium',
                'scanned_at': s.scanned_at.isoformat() if s.scanned_at else None
            } for s in recent_scans]
        }

        return jsonify({'user': user_data}), 200

    except Exception as e:
        print(f"Error in get_user_details: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# TOGGLE USER STATUS (Activate / Deactivate)
# ============================================

@admin_bp.route('/users/<int:user_id>/status', methods=['PUT'])
@jwt_required()
@admin_required
def toggle_user_status(user_id):
    try:
        data = request.get_json()
        user = User.query.get(user_id)

        if not user:
            return jsonify({'error': 'User not found'}), 404

        current_user_id = int(get_jwt_identity())
        if user.id == current_user_id:
            return jsonify({'error': 'You cannot change your own status'}), 400

        user.is_active = data.get('is_active', user.is_active)
        db.session.commit()

        return jsonify({
            'message': f'User {"activated" if user.is_active else "deactivated"} successfully',
            'is_active': user.is_active,
            'user_id': user.id,
            'user_name': user.name
        }), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error in toggle_user_status: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# GET ALL SCANS (Admin view)
# ============================================

@admin_bp.route('/scans', methods=['GET'])
@jwt_required()
@admin_required
def get_all_scans():
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)

        paginated = ScanHistory.query.order_by(
            ScanHistory.scanned_at.desc()
        ).paginate(page=page, per_page=per_page, error_out=False)

        scans_list = []
        for scan in paginated.items:
            user = User.query.get(scan.user_id)
            scans_list.append({
                'id': scan.id,
                'user_name': user.name if user else 'Unknown',
                'user_email': user.email if user else 'Unknown',
                'disease_name': (scan.disease_name or 'Unknown').replace('___', ' - ').replace('_', ' '),
                # FIX: safe confidence formatting
                'confidence': float(round(scan.confidence * 100, 2)) if scan.confidence and scan.confidence <= 1 else float(round(scan.confidence or 0, 2)),
                'severity': scan.severity if hasattr(scan, 'severity') else 'medium',
                'scanned_at': scan.scanned_at.isoformat() if scan.scanned_at else None,
                'image_url': scan.image_path if hasattr(scan, 'image_path') else None
            })

        return jsonify({
            'scans': scans_list,
            'total': paginated.total,
            'page': page,
            'per_page': per_page,
            'total_pages': paginated.pages
        }), 200

    except Exception as e:
        print(f"Error in get_all_scans: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# DELETE USER (Admin)
# ============================================

@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def delete_user(user_id):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        current_user_id = int(get_jwt_identity())
        if user.id == current_user_id:
            return jsonify({'error': 'You cannot delete your own account'}), 400

        # Delete user's scans first
        ScanHistory.query.filter_by(user_id=user.id).delete()

        db.session.delete(user)
        db.session.commit()

        return jsonify({
            'message': f'User {user.name} deleted successfully',
            'user_id': user_id
        }), 200

    except Exception as e:
        db.session.rollback()
        print(f"Error in delete_user: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# SYSTEM STATISTICS (Detailed)
# ============================================

@admin_bp.route('/system/stats', methods=['GET'])
@jwt_required()
@admin_required
def get_system_stats():
    try:
        total_users = User.query.count()
        verified_users = User.query.filter_by(email_verified=True).count()
        admin_users = User.query.filter_by(role='admin').count()

        total_scans = ScanHistory.query.count()
        avg_confidence = db.session.query(func.avg(ScanHistory.confidence)).scalar() or 0

        total_diseases = Disease.query.count()

        last_7_days = datetime.utcnow() - timedelta(days=7)

        scans_last_7_days = ScanHistory.query.filter(
            ScanHistory.scanned_at >= last_7_days
        ).count()

        # FIX: safely check created_at exists on the model before filtering
        new_users_last_7_days = 0
        if hasattr(User, 'created_at'):
            new_users_last_7_days = User.query.filter(
                User.created_at >= last_7_days
            ).count()

        return jsonify({
            'users': {
                'total': total_users,
                'verified': verified_users,
                'admin': admin_users,
                'new_last_7_days': new_users_last_7_days
            },
            'scans': {
                'total': total_scans,
                'avg_confidence': round(float(avg_confidence or 0) * 100, 2),
                'last_7_days': scans_last_7_days
            },
            'diseases': {
                'total': total_diseases
            }
        }), 200

    except Exception as e:
        print(f"Error in get_system_stats: {str(e)}")
        return jsonify({'error': str(e)}), 500