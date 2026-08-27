"""
AgriVision AI Machine Learning Package
Provides dataset preparation, image preprocessing, model training, evaluation, and prediction pipeline.
"""

from .preprocess import preprocess_image, get_data_augmentation
from .dataset import load_and_clean_dataset, prepare_datasets
from .utils import save_class_indices, load_class_indices, plot_training_history, plot_confusion_matrix
from .predict import Predictor, parse_class_name
from .model_loader import get_model_and_classes

__all__ = [
    'preprocess_image',
    'get_data_augmentation',
    'load_and_clean_dataset',
    'prepare_datasets',
    'save_class_indices',
    'load_class_indices',
    'plot_training_history',
    'plot_confusion_matrix',
    'Predictor',
    'parse_class_name',
    'get_model_and_classes',
]
