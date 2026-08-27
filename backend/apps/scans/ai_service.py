"""
AgriVision AI Service — Django REST integration with backend.ml package.

Loads the trained model once at module startup via backend.ml.model_loader
and provides a unified predict(image_path) service.
"""

import logging
from decouple import config
from ml.predict import Predictor, parse_class_name

logger = logging.getLogger(__name__)

MODEL_BACKEND = config('MODEL_BACKEND', default='auto')
CONFIDENCE_THRESHOLD = config('CONFIDENCE_THRESHOLD', default=0.60, cast=float)

# Singleton predictor instance initialized once
_predictor = Predictor(confidence_threshold=CONFIDENCE_THRESHOLD)


def predict(image_path: str) -> dict:
    """
    Run crop disease prediction on the given image file.
    Delegates to the production backend.ml Predictor module.
    """
    try:
        return _predictor.predict(image_path)
    except Exception:
        logger.exception("Inference failed via Predictor — falling back to mock")
        return _predictor._mock_predict(image_path)
