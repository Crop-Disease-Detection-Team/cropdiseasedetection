from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, ScanHistory, Disease, UserFavorite
from datetime import datetime  
import os
import uuid  
import logging

from ml_model import get_predictor

user_bp = Blueprint('user', __name__)
logger = logging.getLogger(__name__)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

#diseases (getting all )

@user_bp.route('/diseases', methods=['GET'])
@jwt_required()
def get_diseases():
    try:
        diseases = Disease.query.all()
        return jsonify({
            'diseases': [d.to_dict() for d in diseases],
            'total': len(diseases)
        }), 200
    except Exception as e:
        logger.error(f"Get diseases error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

#getting the diseases database deitals from the table"diseases"

@user_bp.route('/diseases/<int:disease_id>', methods=['GET'])
@jwt_required()
def get_disease_detail(disease_id):
    try:
        disease = Disease.query.get(disease_id)
        if not disease:
            return jsonify({'error': 'Disease not found'}), 404
        return jsonify(disease.to_dict()), 200
    except Exception as e:
        logger.error(f"Get disease detail error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

#predicting disease

@user_bp.route('/predict', methods=['POST'])
@jwt_required()
def predict():
    try:
        user_id = get_jwt_identity()

        if 'image' not in request.files:
            return jsonify({'error': 'No image provided'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400

        image_bytes = file.read()

        predictor = get_predictor()
        predictions = predictor.predict(image_bytes)

        if not predictions:
            return jsonify({'error': 'Prediction failed'}), 500

        top_prediction = predictions[0]

        filename = f"{uuid.uuid4().hex}.jpg"
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.seek(0)
        file.save(filepath)

        disease_info = Disease.query.filter_by(
            disease_name=top_prediction['disease_name']
        ).first()

        scan = ScanHistory(
            user_id=user_id,
            image_filename=filename,
            image_path=filepath,
            disease_name=top_prediction['disease_name'],
            confidence=top_prediction['confidence'],
            scanned_at=datetime.utcnow(),
            ip_address=request.remote_addr
        )
        db.session.add(scan)
        db.session.commit()

        return jsonify({
            'scan_id': scan.id,
            'disease': top_prediction['disease_name'],
            'confidence': top_prediction['confidence'],
            'treatment': disease_info.organic_treatment if disease_info else 'Consult local agriculture expert',
            'prevention': disease_info.prevention_tips if disease_info else 'Regular crop monitoring',
            'symptoms': disease_info.symptoms if disease_info else 'Check leaves for unusual spots',
            'description': disease_info.description if disease_info else 'No description available'
        }), 200

    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

#getting the scan history 
@user_bp.route('/history', methods=['GET'])
@jwt_required()
def get_history():
    try:
        user_id = get_jwt_identity()
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)

        scans = ScanHistory.query.filter_by(user_id=user_id)\
            .order_by(ScanHistory.scanned_at.desc())\
            .paginate(page=page, per_page=per_page, error_out=False)

        return jsonify({
            'scans': [scan.to_dict() for scan in scans.items],
            'total': scans.total,
            'page': page,
            'pages': scans.pages
        }), 200

    except Exception as e:
        logger.error(f"Get history error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

#getting the user statics 


@user_bp.route('/statistics', methods=['GET'])
@jwt_required()
def get_statistics():
    try:
        user_id = get_jwt_identity()

        total_scans = ScanHistory.query.filter_by(user_id=user_id).count()
        favorites_count = UserFavorite.query.filter_by(user_id=user_id).count()

        avg_confidence = db.session.query(
            db.func.avg(ScanHistory.confidence)
        ).filter_by(user_id=user_id).scalar()

        return jsonify({
            'total_scans': total_scans,
            'favorites_count': favorites_count,
            'average_confidence': round(float(avg_confidence), 2) if avg_confidence else 0
        }), 200

    except Exception as e:
        logger.error(f"Get statistics error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500


#FAVORITES
#this is the optional code for future updates ............#can ignore this section for now #cmt by bikky 

@user_bp.route('/favorites', methods=['GET'])
@jwt_required()
def get_favorites():
    try:
        user_id = get_jwt_identity()
        favorites = UserFavorite.query.filter_by(user_id=user_id).all()
        return jsonify({
            'favorites': [fav.to_dict() for fav in favorites]
        }), 200
    except Exception as e:
        logger.error(f"Get favorites error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@user_bp.route('/favorites/<int:disease_id>', methods=['POST'])
@jwt_required()
def add_favorite(disease_id):
    try:
        user_id = get_jwt_identity()

        existing = UserFavorite.query.filter_by(
            user_id=user_id, disease_id=disease_id
        ).first()

        if existing:
            return jsonify({'message': 'Already in favorites'}), 200

        favorite = UserFavorite(user_id=user_id, disease_id=disease_id)
        db.session.add(favorite)
        db.session.commit()

        return jsonify({'message': 'Added to favorites'}), 201
    except Exception as e:
        logger.error(f"Add favorite error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

@user_bp.route('/favorites/<int:disease_id>', methods=['DELETE'])
@jwt_required()
def remove_favorite(disease_id):
    try:
        user_id = get_jwt_identity()

        favorite = UserFavorite.query.filter_by(
            user_id=user_id, disease_id=disease_id
        ).first()

        if not favorite:
            return jsonify({'error': 'Not in favorites'}), 404

        db.session.delete(favorite)
        db.session.commit()

        return jsonify({'message': 'Removed from favorites'}), 200
    except Exception as e:
        logger.error(f"Remove favorite error: {str(e)}")
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# DELETE ALL SCAN HISTORY
# ============================================

@user_bp.route('/history', methods=['DELETE'])
@jwt_required()
def delete_all_history():
    try:
        user_id = get_jwt_identity()
        deleted = ScanHistory.query.filter_by(user_id=user_id).delete()
        db.session.commit()
        return jsonify({'message': f'Deleted {deleted} scan records'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Delete history error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

# ============================================
# GET USER SCANS (for dashboard recent scans)
# FIX: removed duplicate route that was in auth.py
# ============================================

@user_bp.route('/scans', methods=['GET'])
@jwt_required()
def get_user_scans():
    try:
        user_id = get_jwt_identity()
        scans = ScanHistory.query.filter_by(user_id=user_id).order_by(
            ScanHistory.scanned_at.desc()
        ).all()
        return jsonify({
            'scans': [{
                'id': s.id,
                'disease_name': s.disease_name,
                'confidence': float(s.confidence) if s.confidence is not None else 0,
                'severity': s.severity if hasattr(s, 'severity') else 'medium',
                'scanned_at': s.scanned_at.isoformat() if s.scanned_at else None,
                'image_path': s.image_path
            } for s in scans],
            'total': len(scans)
        }), 200
    except Exception as e:
        logger.error(f"Get user scans error: {str(e)}")
        return jsonify({'error': str(e)}), 500