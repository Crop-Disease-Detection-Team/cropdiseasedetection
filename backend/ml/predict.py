"""
AgriVision AI Inference and Prediction Module.
Handles image loading, preprocessing, inference execution via loaded model,
computing top-k predictions, class mapping, and confidence thresholding.
"""

from typing import Dict, List, Tuple
import numpy as np

from .model_loader import get_model_and_classes
from .preprocess import preprocess_image


def parse_class_name(raw_label: str) -> Tuple[str, str, bool]:
    """
    Parse PlantVillage raw label string into (crop_name, disease_name, is_healthy).
    Example: 'Tomato___Late_blight' -> ('Tomato', 'Late blight', False)
             'Apple___healthy' -> ('Apple', 'Healthy', True)
    """
    parts = raw_label.split('___')
    crop_raw = parts[0] if parts else raw_label
    disease_raw = parts[1] if len(parts) > 1 else 'Unknown'

    crop_name = crop_raw.replace('_', ' ').strip()
    import re
    crop_name = re.sub(r'\s*\(.*?\)\s*', ' ', crop_name).strip()

    is_healthy = disease_raw.lower() == 'healthy'
    disease_name = 'Healthy' if is_healthy else disease_raw.replace('_', ' ').strip()

    return crop_name, disease_name, is_healthy


class Predictor:
    """Production Predictor class for AgriVision AI."""

    def __init__(self, confidence_threshold: float = 0.60):
        self.confidence_threshold = confidence_threshold
        self.model, self.class_names = get_model_and_classes()

    def predict(self, image_path: str, top_k: int = 3) -> Dict:
        """
        Predict crop disease from image file path.
        Returns detailed dict with top predictions, confidence, healthy flag, etc.
        """
        if self.model is None:
            return self._mock_predict(image_path, top_k)

        # Preprocess
        tensor = preprocess_image(image_path, target_size=(224, 224), normalize=True)

        # Model Inference
        raw_preds = self.model.predict(tensor, verbose=0)[0]  # shape: (num_classes,)

        # Sort indices by probability
        top_indices = np.argsort(raw_preds)[::-1][:top_k]

        top_predictions: List[Dict] = []
        for idx in top_indices:
            label = self.class_names[idx] if idx < len(self.class_names) else f'class_{idx}'
            _, disease_name, _ = parse_class_name(label)
            conf = float(raw_preds[idx])
            top_predictions.append({
                'class_label': label,
                'name': disease_name,
                'confidence': round(conf, 4),
            })

        best_idx = int(top_indices[0])
        best_label = self.class_names[best_idx] if best_idx < len(self.class_names) else f'class_{best_idx}'
        crop_name, disease_name, is_healthy = parse_class_name(best_label)
        best_confidence = float(raw_preds[best_idx])

        # Compute healthy probability across all healthy categories
        healthy_prob = sum(
            float(raw_preds[i]) for i, name in enumerate(self.class_names)
            if 'healthy' in name.lower()
        )

        return {
            'class_label': best_label,
            'crop_name': crop_name,
            'disease_name': disease_name,
            'is_healthy': is_healthy,
            'confidence': round(best_confidence, 4),
            'healthy_probability': round(healthy_prob, 4),
            'disease_probability': round(1.0 - healthy_prob, 4),
            'top_predictions': top_predictions,
            'low_confidence': best_confidence < self.confidence_threshold,
        }

    def _mock_predict(self, image_path: str, top_k: int = 3) -> Dict:
        """Fallback mock prediction for dev / testing environments without model file."""
        return {
            'class_label': 'Tomato___Late_blight',
            'crop_name': 'Tomato',
            'disease_name': 'Late blight',
            'is_healthy': False,
            'confidence': 0.9340,
            'healthy_probability': 0.0180,
            'disease_probability': 0.9820,
            'top_predictions': [
                {'class_label': 'Tomato___Late_blight', 'name': 'Late blight', 'confidence': 0.9340},
                {'class_label': 'Tomato___Early_blight', 'name': 'Early blight', 'confidence': 0.0480},
                {'class_label': 'Tomato___Septoria_leaf_spot', 'name': 'Septoria leaf spot', 'confidence': 0.0120},
            ],
            'low_confidence': False,
        }
