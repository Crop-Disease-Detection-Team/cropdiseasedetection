# predict.py - PyTorch EfficientNet-B3 inference for Plant Disease Detection
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, ScanHistory
from datetime import datetime
import logging
import os
import uuid
import io
from PIL import Image
import torch
import torch.nn as nn
from torchvision import transforms
import json
from pathlib import Path

# ------------------------------
# PyTorch model setup (runs once when server starts)
# ------------------------------
class PlantDiseaseClassifier(nn.Module):
    def __init__(self, num_classes=38, dropout=0.4):
        super().__init__()
        from torchvision.models import efficientnet_b3, EfficientNet_B3_Weights
        backbone = efficientnet_b3(weights=EfficientNet_B3_Weights.IMAGENET1K_V1)
        self.features = backbone.features
        self.avgpool = backbone.avgpool
        in_features = 1536  # EfficientNet-B3
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(in_features, 512),
            nn.GELU(),
            nn.Dropout(dropout * 0.75),
            nn.Linear(512, num_classes)
        )
    def forward(self, x):
        x = self.features(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        return self.classifier(x)

# ---- Paths ----
BASE_DIR = Path(__file__).parent
MODEL_PATH = BASE_DIR / "models" / "best_model.pth"
CLASS_NAMES_PATH = BASE_DIR / "models" / "class_names.json"

# Check if model exists (if not, still run with warning)
model_available = True
if not MODEL_PATH.exists():
    print(f"WARNING: Model not found at {MODEL_PATH}")
    print("   Prediction will use dummy data")
    model_available = False

if not CLASS_NAMES_PATH.exists():
    print(f" WARNING: Class names not found at {CLASS_NAMES_PATH}")
    model_available = False

device = torch.device("cpu")
model = None
class_names = []

if model_available:
    try:
        model = PlantDiseaseClassifier(num_classes=38)
        checkpoint = torch.load(MODEL_PATH, map_location=device)
        model.load_state_dict(checkpoint['model_state_dict'])
        model.eval()
        print("PyTorch model loaded")
        
        with open(CLASS_NAMES_PATH, "r") as f:
            class_names = json.load(f)
        print(f"Loaded {len(class_names)} class names")
    except Exception as e:
        print(f" Error loading model: {e}")
        model_available = False

mean = [0.485, 0.456, 0.406]
std = [0.229, 0.224, 0.225]
transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean, std),
])

predict_bp = Blueprint('predict', __name__)
logger = logging.getLogger(__name__)


def save_uploaded_image(file, user_id):
    """Save uploaded image and return (image_url, filename)"""
    upload_dir = 'uploads/scans'
    os.makedirs(upload_dir, exist_ok=True)
    
    ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else 'jpg'
    filename = f"scan_{user_id}_{uuid.uuid4().hex[:8]}_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.{ext}"
    filepath = os.path.join(upload_dir, filename)
    
    file.seek(0)
    file.save(filepath)
    
    # Return relative URL (to be served by Flask)
    image_url = f"/uploads/scans/{filename}"
    return image_url, filename


def get_disease_details(disease_code):
    """Fetch disease details from database"""
    from disease import Disease
    disease = Disease.query.filter_by(disease_name=disease_code).first()
    
    if disease:
        severity = disease.severity_level
        if hasattr(severity, 'value'):
            severity = severity.value
        elif severity is None:
            severity = 'Medium'
        
        result = {
            'disease_name': disease.disease_name.replace('___', ' - ').replace('_', ' '),
            'disease_code': disease.disease_name,
            'crop_type': disease.crop_type,
            'severity_level': severity,
            'scientific_name': disease.scientific_name,
            'description': disease.description,
            'symptoms': disease.symptoms,
            'causes': disease.causes,
            'organic_treatment': disease.organic_treatment,
            'chemical_treatment': disease.chemical_treatment,
            'prevention_tips': disease.prevention_tips,
            'affected_crop_parts': disease.affected_crop_parts,
            'typical_duration': disease.typical_duration,
            'cultivation_regions': disease.cultivation_regions,
            'disease_id': disease.id,
            'medicines': []
        }
        
        for mapping in disease.medicine_mappings:
            med = mapping.medicine
            if med:
                med_type = med.type
                if hasattr(med_type, 'value'):
                    med_type = med_type.value
                app_method = med.application_method
                if hasattr(app_method, 'value'):
                    app_method = app_method.value
                result['medicines'].append({
                    'medicine_name': med.medicine_name,
                    'active_ingredient': med.active_ingredient,
                    'type': med_type,
                    'dosage_per_liter': med.dosage_per_liter,
                    'application_method': app_method or 'Spray',
                    'waiting_period_days': med.waiting_period_days,
                    'effectiveness_rating': mapping.effectiveness_rating or 3
                })
        return result, disease
    return None, None


# ------------------------------
# Prediction endpoint
# ------------------------------
@predict_bp.route('/predict', methods=['POST'])
@jwt_required()
def predict_disease():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Save image and get URL
        try:
            image_url, image_filename = save_uploaded_image(file, user.id)
        except Exception as save_error:
            print(f"Error saving image: {save_error}")
            image_url = None
            image_filename = None
        
        # --- PyTorch inference ---
        if model_available and model:
            file.seek(0)
            image_bytes = file.read()
            pil_image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
            input_tensor = transform(pil_image).unsqueeze(0)
            
            with torch.no_grad():
                output = model(input_tensor)
                probs = torch.softmax(output, dim=1).numpy()[0]
                pred_idx = int(torch.argmax(output, dim=1).cpu().numpy()[0])
                confidence = float(probs[pred_idx])
                predicted_class = class_names[pred_idx]
            
            # Top 5 predictions
            top_predictions = []
            top_indices = probs.argsort()[-5:][::-1]
            for idx in top_indices:
                top_predictions.append({
                    'disease_name': class_names[idx].replace('___', ' - ').replace('_', ' '),
                    'disease_code': class_names[idx],
                    'confidence': float(probs[idx])
                })
        else:
            # Dummy prediction when model not available
            predicted_class = "Tomato___Late_blight"
            confidence = 94.5
            top_predictions = []
        
        disease_code = predicted_class
        
        # Fetch disease details from database
        result, disease = get_disease_details(disease_code)
        
        if result:
            # Add confidence and top predictions
            result['confidence'] = round(confidence * 100, 2) if confidence < 1 else round(confidence, 2)
            result['top_predictions'] = top_predictions
            
            # Save scan history
            recommendation = f"""Organic Treatment: {result.get('organic_treatment', 'Not specified')}
Chemical Treatment: {result.get('chemical_treatment', 'Not specified')}
Prevention Tips: {result.get('prevention_tips', 'Regular monitoring and crop rotation.')}"""
            
            scan = ScanHistory(
                user_id=user.id,
                image_path=image_url,
                image_filename=image_filename,
                disease_name=disease_code,
                confidence=confidence if confidence < 1 else confidence / 100,
                severity=result.get('severity_level', 'Medium'),
                recommendation=recommendation[:500],
                scanned_at=datetime.utcnow()
            )
            db.session.add(scan)
            db.session.commit()
        else:
            # Fallback when disease not in database
            result = {
                'disease_name': predicted_class.replace('___', ' - ').replace('_', ' '),
                'disease_code': disease_code,
                'confidence': round(confidence * 100, 2) if confidence < 1 else round(confidence, 2),
                'crop_type': 'Unknown',
                'severity_level': 'Medium',
                'scientific_name': 'Not specified',
                'description': 'Disease detected by AI model',
                'symptoms': 'Consult local agricultural expert',
                'causes': 'Consult local agricultural expert',
                'organic_treatment': 'Consult local agricultural expert',
                'chemical_treatment': 'Consult local agricultural expert',
                'prevention_tips': 'Regular monitoring and crop rotation',
                'affected_crop_parts': 'Leaves',
                'typical_duration': 'Seasonal',
                'cultivation_regions': 'All regions',
                'disease_id': None,
                'medicines': [],
                'top_predictions': top_predictions
            }
            scan = ScanHistory(
                user_id=user.id,
                image_path=image_url,
                image_filename=image_filename,
                disease_name=disease_code,
                confidence=confidence if confidence < 1 else confidence / 100,
                severity='Medium',
                recommendation='Consult local agricultural expert for treatment',
                scanned_at=datetime.utcnow()
            )
            db.session.add(scan)
            db.session.commit()
        
        return jsonify(result), 200
        
    except Exception as e:
        print(f"Prediction error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


# ------------------------------
# Batch prediction endpoint
# ------------------------------
@predict_bp.route('/predict/batch', methods=['POST'])
@jwt_required()
def predict_batch():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        if 'images' not in request.files:
            return jsonify({'error': 'No images provided'}), 400
        
        files = request.files.getlist('images')
        if len(files) == 0:
            return jsonify({'error': 'No files selected'}), 400
        
        results = []
        for file in files:
            if model_available and model:
                img_bytes = file.read()
                pil_image = Image.open(io.BytesIO(img_bytes)).convert('RGB')
                input_tensor = transform(pil_image).unsqueeze(0)
                with torch.no_grad():
                    output = model(input_tensor)
                    probs = torch.softmax(output, dim=1).numpy()[0]
                    pred_idx = int(torch.argmax(output, dim=1).cpu().numpy()[0])
                    confidence = float(probs[pred_idx])
                    predicted_class = class_names[pred_idx]
            else:
                predicted_class = "Tomato___Late_blight"
                confidence = 94.5
            
            results.append({
                'filename': file.filename,
                'disease_name': predicted_class.replace('___', ' - ').replace('_', ' '),
                'disease_code': predicted_class,
                'confidence': round(confidence * 100, 2) if confidence < 1 else round(confidence, 2)
            })
        
        return jsonify({
            'total': len(results),
            'results': results
        }), 200
        
    except Exception as e:
        print(f"Batch prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ------------------------------
# Model info endpoint
# ------------------------------
@predict_bp.route('/model/info', methods=['GET'])
def model_info():
    try:
        return jsonify({
            'model_loaded': model_available,
            'model_path': str(MODEL_PATH) if MODEL_PATH.exists() else None,
            'num_classes': len(class_names) if class_names else 0,
            'input_shape': (224, 224, 3),
            'framework': 'PyTorch'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e), 'model_loaded': False}), 200


# ------------------------------
# Scan history endpoint
# ------------------------------
@predict_bp.route('/history', methods=['GET'])
@jwt_required()
def get_scan_history():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        scans = ScanHistory.query.filter_by(user_id=user.id).order_by(
            ScanHistory.scanned_at.desc()
        ).paginate(page=page, per_page=per_page, error_out=False)
        
        # Build response
        result = {
            'scans': [],
            'total': scans.total,
            'page': scans.page,
            'pages': scans.pages
        }
        for scan in scans.items:
            scan_dict = {
                'id': scan.id,
                'disease_name': scan.disease_name.replace('___', ' - ').replace('_', ' ') if scan.disease_name else 'Unknown',
                'confidence': round(scan.confidence * 100, 2) if scan.confidence and scan.confidence < 1 else round(scan.confidence or 0, 2),
                'severity': scan.severity,
                'scanned_at': scan.scanned_at.isoformat() if scan.scanned_at else None,
                'image_url': scan.image_path,
                'recommendation': scan.recommendation[:200] if scan.recommendation else None
            }
            result['scans'].append(scan_dict)
        
        return jsonify(result), 200
        
    except Exception as e:
        print(f"History error: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ------------------------------
# Single scan detail endpoint
# ------------------------------
@predict_bp.route('/history/<int:scan_id>', methods=['GET'])
@jwt_required()
def get_scan_detail(scan_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(int(user_id))
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        scan = ScanHistory.query.filter_by(id=scan_id, user_id=user.id).first()
        
        if not scan:
            return jsonify({'error': 'Scan not found'}), 404
        
        result = {
            'id': scan.id,
            'disease_name': scan.disease_name.replace('___', ' - ').replace('_', ' ') if scan.disease_name else 'Unknown',
            'confidence': round(scan.confidence * 100, 2) if scan.confidence and scan.confidence < 1 else round(scan.confidence or 0, 2),
            'severity': scan.severity,
            'scanned_at': scan.scanned_at.isoformat() if scan.scanned_at else None,
            'image_url': scan.image_path,
            'recommendation': scan.recommendation
        }
        
        return jsonify(result), 200
        
    except Exception as e:
        print(f"Scan detail error: {str(e)}")
        return jsonify({'error': str(e)}), 500


# ------------------------------
# Delete scan history
# ------------------------------
@predict_bp.route('/history', methods=['DELETE'])
@jwt_required()
def delete_scan_history():
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
        print(f"Delete history error: {str(e)}")
        return jsonify({'error': str(e)}), 500