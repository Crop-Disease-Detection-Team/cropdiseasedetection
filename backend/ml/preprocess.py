"""
Image Preprocessing and Data Augmentation Module for AgriVision AI.
Includes image resizing (224x224), RGB conversion, pixel normalization [0, 1],
and Keras sequential data augmentation layers for training.
"""

import numpy as np
from PIL import Image


def preprocess_image(image_path: str, target_size=(224, 224), normalize=True) -> np.ndarray:
    """
    Load an image from disk, convert to RGB, resize to target_size,
    normalize pixels to [0, 1] if requested, and add a batch dimension.
    
    Returns:
        np.ndarray of shape (1, target_size[0], target_size[1], 3)
    """
    img = Image.open(image_path).convert('RGB')
    img = img.resize(target_size, Image.Resampling.BILINEAR)
    arr = np.array(img, dtype='float32')
    
    if normalize:
        arr = arr / 255.0  # Normalize to [0, 1]
        
    arr = np.expand_dims(arr, axis=0)  # Add batch dimension (1, 224, 224, 3)
    return arr


def get_data_augmentation():
    """
    Returns a Keras Sequential layer for data augmentation applied only during training.
    Imports tensorflow lazily.
    """
    import tensorflow as tf
    from tensorflow.keras import layers
    return tf.keras.Sequential([
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.2),
        layers.RandomZoom(0.2),
        layers.RandomContrast(0.2),
        layers.RandomTranslation(height_factor=0.1, width_factor=0.1),
    ], name="data_augmentation")
