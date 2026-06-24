from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Disease, Medicine, DiseaseMedicineMapping, ScanHistory
from sqlalchemy import func, desc, text
import logging

disease_bp = Blueprint('disease', __name__)
logger = logging.getLogger(__name__)

# ============================================
# GET ALL DISEASES (with pagination & filters)
# ============================================

@disease_bp.route('/user/diseases', methods=['GET'])
@jwt_required()
def get_diseases():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get query parameters
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 100, type=int)
        crop_type = request.args.get('crop_type', None)
        search = request.args.get('search', None)
        
        # Build query
        query = Disease.query
        
        if crop_type:
            query = query.filter(Disease.crop_type == crop_type)
        
        if search:
            query = query.filter(Disease.disease_name.ilike(f'%{search}%'))
        
        # Paginate
        paginated = query.order_by(Disease.crop_type, Disease.disease_name).paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        diseases = []
        for disease in paginated.items:
            # Handle severity level enum
            severity_value = disease.severity_level
            if hasattr(severity_value, 'value'):
                severity_value = severity_value.value
            elif severity_value is None:
                severity_value = 'Medium'
            else:
                severity_value = str(severity_value)
            
            diseases.append({
                'id': disease.id,
                'disease_name': disease.disease_name,
                'crop_type': disease.crop_type,
                'severity_level': severity_value,
                'sample_image_url': disease.sample_image_url,
                'description': disease.description[:150] + '...' if disease.description and len(disease.description) > 150 else disease.description
            })
        
        return jsonify({
            'diseases': diseases,
            'total': paginated.total,
            'page': page,
            'per_page': per_page,
            'total_pages': paginated.pages
        }), 200
        
    except Exception as e:
        logger.error(f"Error in get_diseases: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# GET SINGLE DISEASE WITH MEDICINES AND RATINGS
# ============================================

@disease_bp.route('/user/diseases/<int:disease_id>', methods=['GET'])
@jwt_required()
def get_disease_detail(disease_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get disease
        disease = Disease.query.get(disease_id)
        
        if not disease:
            return jsonify({'error': 'Disease not found'}), 404
        
        # Get medicines for this disease
        medicines_list = []
        
        # Try using relationship first
        if hasattr(disease, 'medicine_mappings') and disease.medicine_mappings:
            for mapping in disease.medicine_mappings:
                med = mapping.medicine
                if med:
                    # Handle enum values
                    med_type = med.type
                    if hasattr(med_type, 'value'):
                        med_type = med_type.value
                    elif med_type is None:
                        med_type = 'General'
                    
                    app_method = med.application_method
                    if hasattr(app_method, 'value'):
                        app_method = app_method.value
                    elif app_method is None:
                        app_method = 'Spray'
                    
                    medicines_list.append({
                        'id': med.id,
                        'medicine_name': med.medicine_name,
                        'active_ingredient': med.active_ingredient,
                        'type': med_type,
                        'application_method': app_method,
                        'dosage_per_liter': med.dosage_per_liter,
                        'waiting_period_days': med.waiting_period_days,
                        'safety_precautions': med.safety_precautions,
                        'is_organic': med.is_organic,
                        'effectiveness_rating': mapping.effectiveness_rating if mapping.effectiveness_rating is not None else 3,
                        'usage_instructions': mapping.usage_instructions
                    })
        
        # Sort by effectiveness rating (highest first)
        medicines_list.sort(key=lambda x: x.get('effectiveness_rating', 0), reverse=True)
        
        # Handle severity level enum
        severity_value = disease.severity_level
        if hasattr(severity_value, 'value'):
            severity_value = severity_value.value
        elif severity_value is None:
            severity_value = 'Medium'
        else:
            severity_value = str(severity_value)
        
        disease_data = {
            'id': disease.id,
            'disease_name': disease.disease_name,
            'crop_type': disease.crop_type,
            'scientific_name': disease.scientific_name,
            'description': disease.description,
            'symptoms': disease.symptoms,
            'causes': disease.causes,
            'organic_treatment': disease.organic_treatment,
            'chemical_treatment': disease.chemical_treatment,
            'prevention_tips': disease.prevention_tips,
            'severity_level': severity_value,
            'typical_duration': disease.typical_duration,
            'affected_crop_parts': disease.affected_crop_parts,
            'sample_image_url': disease.sample_image_url,
            'cultivation_regions': disease.cultivation_regions,
            'medicines': medicines_list
        }
        
        return jsonify(disease_data), 200
        
    except Exception as e:
        logger.error(f"Error in get_disease_detail: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


# ============================================
# GET USER STATISTICS
# ============================================

@disease_bp.route('/user/statistics', methods=['GET'])
@jwt_required()
def get_user_statistics():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get stats from scan history
        total_scans = ScanHistory.query.filter_by(user_id=user.id).count()
        
        # Get average confidence
        avg_confidence_result = db.session.query(func.avg(ScanHistory.confidence)).filter(
            ScanHistory.user_id == user.id,
            ScanHistory.confidence.isnot(None)
        ).first()
        
        avg_confidence = round(avg_confidence_result[0] * 100, 2) if avg_confidence_result[0] else 0
        
        # Get favorite diseases (most scanned)
        favorite_diseases = db.session.query(
            ScanHistory.disease_name,
            func.count(ScanHistory.disease_name).label('count')
        ).filter(
            ScanHistory.user_id == user.id
        ).group_by(
            ScanHistory.disease_name
        ).order_by(
            desc('count')
        ).limit(5).all()
        
        stats = {
            'total_scans': total_scans,
            'favorites_count': len(favorite_diseases),
            'average_confidence': avg_confidence,
            'favorite_diseases': [{
                'name': d[0].replace('___', ' - ').replace('_', ' ') if d[0] else 'Unknown',
                'count': d[1]
            } for d in favorite_diseases]
        }
        
        return jsonify(stats), 200
        
    except Exception as e:
        logger.error(f"Error in get_user_statistics: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# GET USER HISTORY
# ============================================

@disease_bp.route('/user/history', methods=['GET'])
@jwt_required()
def get_user_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        # Get scan history
        scans = ScanHistory.query.filter_by(user_id=user.id).order_by(
            ScanHistory.scanned_at.desc()
        ).paginate(page=page, per_page=per_page, error_out=False)
        
        scans_list = []
        for scan in scans.items:
            # Get severity for this disease
            disease = Disease.query.filter_by(disease_name=scan.disease_name).first()
            severity = disease.severity_level if disease else 'Medium'
            if hasattr(severity, 'value'):
                severity = severity.value
            
            scans_list.append({
                'id': scan.id,
                'disease_name': scan.disease_name.replace('___', ' - ').replace('_', ' ') if scan.disease_name else 'Unknown',
                'confidence': round(scan.confidence * 100, 2) if scan.confidence and scan.confidence < 1 else round(scan.confidence or 0, 2),
                'severity': severity,
                'image_path': scan.image_path,
                'scanned_at': scan.scanned_at.isoformat() if scan.scanned_at else None
            })
        
        return jsonify({
            'scans': scans_list,
            'total': scans.total,
            'page': scans.page,
            'per_page': per_page,
            'total_pages': scans.pages
        }), 200
        
    except Exception as e:
        logger.error(f"Error in get_user_history: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# DELETE USER HISTORY (all scans)
# ============================================

@disease_bp.route('/user/history', methods=['DELETE'])
@jwt_required()
def delete_user_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Delete all scans for this user
        deleted_count = ScanHistory.query.filter_by(user_id=user.id).delete()
        db.session.commit()
        
        return jsonify({
            'message': f'Successfully deleted {deleted_count} scan records',
            'deleted_count': deleted_count
        }), 200
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error in delete_user_history: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# SEARCH DISEASES
# ============================================

@disease_bp.route('/user/diseases/search', methods=['GET'])
@jwt_required()
def search_diseases():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        query = request.args.get('q', '')
        crop = request.args.get('crop', None)
        
        if not query or len(query) < 2:
            return jsonify({'diseases': []}), 200
        
        disease_query = Disease.query.filter(Disease.disease_name.ilike(f'%{query}%'))
        
        if crop:
            disease_query = disease_query.filter(Disease.crop_type == crop)
        
        diseases = disease_query.limit(20).all()
        
        results = []
        for disease in diseases:
            severity_value = disease.severity_level
            if hasattr(severity_value, 'value'):
                severity_value = severity_value.value
            elif severity_value is None:
                severity_value = 'Medium'
            
            results.append({
                'id': disease.id,
                'disease_name': disease.disease_name,
                'crop_type': disease.crop_type,
                'severity_level': severity_value,
                'sample_image_url': disease.sample_image_url
            })
        
        return jsonify({
            'query': query,
            'total': len(results),
            'diseases': results
        }), 200
        
    except Exception as e:
        logger.error(f"Error in search_diseases: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# GET DISEASES BY CROP
# ============================================

@disease_bp.route('/user/diseases/crop/<crop_type>', methods=['GET'])
@jwt_required()
def get_diseases_by_crop(crop_type):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        diseases = Disease.query.filter_by(crop_type=crop_type).order_by(Disease.disease_name).all()
        
        results = []
        for disease in diseases:
            severity_value = disease.severity_level
            if hasattr(severity_value, 'value'):
                severity_value = severity_value.value
            elif severity_value is None:
                severity_value = 'Medium'
            
            results.append({
                'id': disease.id,
                'disease_name': disease.disease_name,
                'severity_level': severity_value,
                'sample_image_url': disease.sample_image_url,
                'description': disease.description[:100] + '...' if disease.description and len(disease.description) > 100 else disease.description
            })
        
        return jsonify({
            'crop': crop_type,
            'total': len(results),
            'diseases': results
        }), 200
        
    except Exception as e:
        logger.error(f"Error in get_diseases_by_crop: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ============================================
# GET CROP TYPES (for filter dropdown)
# ============================================

@disease_bp.route('/user/crops', methods=['GET'])
@jwt_required()
def get_crop_types():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get unique crop types
        crops = db.session.query(Disease.crop_type).distinct().filter(
            Disease.crop_type.isnot(None)
        ).order_by(Disease.crop_type).all()
        
        crop_list = [crop[0] for crop in crops if crop[0]]
        
        return jsonify({
            'crops': crop_list,
            'total': len(crop_list)
        }), 200
        
    except Exception as e:
        logger.error(f"Error in get_crop_types: {str(e)}")
        return jsonify({'error': str(e)}), 500