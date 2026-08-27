"""
Singleton Model Loader Module for AgriVision AI.
Ensures the Keras model and class index mappings are loaded into memory ONCE at server startup,
preventing costly reloading overhead per inference request.
"""

import json
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)

_MODEL_INSTANCE = None
_CLASS_NAMES_CACHE = None


def get_model_and_classes(model_dir: str = None):
    """
    Get or load the singleton model instance and class names list.
    Returns:
        (model, class_names) tuple. Model can be None if uninitialized or using mock.
    """
    global _MODEL_INSTANCE, _CLASS_NAMES_CACHE

    if _MODEL_INSTANCE is not None and _CLASS_NAMES_CACHE is not None:
        return _MODEL_INSTANCE, _CLASS_NAMES_CACHE

    if model_dir is None:
        model_dir = Path(__file__).resolve().parent.parent.parent / 'model_store'
    else:
        model_dir = Path(model_dir)

    # Search for available model files
    candidate_paths = [
        model_dir / 'best_model.keras',
        model_dir / 'agrivision_model.keras',
        model_dir / 'agrivision_model_final.keras',
    ]

    model_path = None
    for path in candidate_paths:
        if path.exists():
            model_path = path
            break

    if model_path is None:
        logger.warning(f"No trained model found in {model_dir}. Singleton model remains None.")
        return None, _get_default_class_names()

    try:
        import tensorflow as tf
        logger.info(f"Loading TensorFlow model from {model_path}...")
        _MODEL_INSTANCE = tf.keras.models.load_model(str(model_path))
        logger.info("TensorFlow model loaded successfully into memory singleton.")
    except Exception as e:
        logger.exception(f"Failed to load TensorFlow model from {model_path}: {e}")
        _MODEL_INSTANCE = None

    # Load class indices
    indices_path = model_dir / 'class_indices.json'
    if indices_path.exists():
        try:
            with open(indices_path, 'r') as f:
                idx_map = json.load(f)
            _CLASS_NAMES_CACHE = [idx_map[str(i)] for i in range(len(idx_map))]
            logger.info(f"Loaded {len(_CLASS_NAMES_CACHE)} class indices from {indices_path}")
        except Exception:
            logger.exception("Error loading class_indices.json")
            _CLASS_NAMES_CACHE = _get_default_class_names()
    else:
        _CLASS_NAMES_CACHE = _get_default_class_names()

    return _MODEL_INSTANCE, _CLASS_NAMES_CACHE


def _get_default_class_names() -> list:
    """Default 38 PlantVillage class labels as fallback."""
    return [
        'Apple___Apple_scab',
        'Apple___Black_rot',
        'Apple___Cedar_apple_rust',
        'Apple___healthy',
        'Blueberry___healthy',
        'Cherry_(including_sour)___Powdery_mildew',
        'Cherry_(including_sour)___healthy',
        'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
        'Corn_(maize)___Common_rust_',
        'Corn_(maize)___Northern_Leaf_Blight',
        'Corn_(maize)___healthy',
        'Grape___Black_rot',
        'Grape___Esca_(Black_Measles)',
        'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
        'Grape___healthy',
        'Orange___Haunglongbing_(Citrus_greening)',
        'Peach___Bacterial_spot',
        'Peach___healthy',
        'Pepper,_bell___Bacterial_spot',
        'Pepper,_bell___healthy',
        'Potato___Early_blight',
        'Potato___Late_blight',
        'Potato___healthy',
        'Raspberry___healthy',
        'Soybean___healthy',
        'Squash___Powdery_mildew',
        'Strawberry___Leaf_scorch',
        'Strawberry___healthy',
        'Tomato___Bacterial_spot',
        'Tomato___Early_blight',
        'Tomato___Late_blight',
        'Tomato___Leaf_Mold',
        'Tomato___Septoria_leaf_spot',
        'Tomato___Spider_mites Two-spotted_spider_mite',
        'Tomato___Target_Spot',
        'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
        'Tomato___Tomato_mosaic_virus',
        'Tomato___healthy',
    ]
