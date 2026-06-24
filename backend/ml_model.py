import tensorflow as tf
import numpy as np
from PIL import Image
import io
import os

class DiseasePredictor:
    def __init__(self, model_path=None):
        # Use absolute path to your model
        if model_path is None:
            # Try multiple locations
            possible_paths = [
                r'C:\Users\Bikky\crop-disease-detector\models\crop_disease_model.h5',
                r'C:\Users\Bikky\crop-disease-detector\backend\models\crop_disease_model.h5',
                'models/crop_disease_model.h5',
                '../models/crop_disease_model.h5',
            ]
            
            self.model_path = None
            for path in possible_paths:
                if os.path.exists(path):
                    self.model_path = path
                    print(f"Found model at: {path}")
                    break
            
            if self.model_path is None:
                print(f" Model not found! Checked: {possible_paths}")
                self.model_loaded = False
                self.load_class_names()
                return
        else:
            self.model_path = model_path
        
        self.model = None
        self.class_names = []
        self.model_loaded = False
        self.load_model()
        self.load_class_names()
    
    def load_model(self):
        try:
            print(f" Loading model from {self.model_path}...")
            self.model = tf.keras.models.load_model(self.model_path)
            self.model_loaded = True
            print(f" Model loaded successfully!")
            
            # Test model with dummy input
            dummy_input = np.random.rand(1, 224, 224, 3)
            dummy_output = self.model.predict(dummy_input, verbose=0)
            print(f" Model test passed! Output shape: {dummy_output.shape}")
            
        except Exception as e:
            print(f" Error loading model: {e}")
            self.model_loaded = False
    
    def load_class_names(self):
        # Default 38 classes (must match your model's classes)
        self.class_names = [
            'Apple___Apple_scab', 'Apple___Black_rot', 'Apple___Cedar_apple_rust', 'Apple___healthy',
            'Blueberry___healthy', 'Cherry___healthy', 'Cherry___Powdery_mildew',
            'Corn___Cercospora_leaf_spot', 'Corn___Common_rust', 'Corn___healthy', 'Corn___Northern_Leaf_Blight',
            'Grape___Black_rot', 'Grape___Esca_(Black_Measles)', 'Grape___healthy', 'Grape___Leaf_blight',
            'Orange___Haunglongbing', 'Peach___Bacterial_spot', 'Peach___healthy',
            'Pepper_bell___Bacterial_spot', 'Pepper_bell___healthy',
            'Potato___Early_blight', 'Potato___healthy', 'Potato___Late_blight',
            'Raspberry___healthy', 'Soybean___healthy',
            'Squash___Powdery_mildew', 'Strawberry___healthy', 'Strawberry___Leaf_scorch',
            'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___healthy', 'Tomato___Late_blight',
            'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot', 'Tomato___Spider_mites',
            'Tomato___Target_Spot', 'Tomato___Tomato_mosaic_virus', 'Tomato___Tomato_Yellow_Leaf_Curl_Virus'
        ]
        print(f" Loaded {len(self.class_names)} disease classes")
    
    def preprocess_image(self, image_bytes):
        img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        img = img.resize((224, 224))
        img_array = np.array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)
        return img_array
    
    def predict(self, image_bytes):
        # If model is not loaded, return demo prediction
        if not self.model_loaded:
            print(" Using DEMO MODE - model not loaded")
            return self._demo_predict(image_bytes)
        
        try:
            img_array = self.preprocess_image(image_bytes)
            predictions = self.model.predict(img_array, verbose=0)[0]
            
            # Get top 3 predictions
            top_3_idx = np.argsort(predictions)[-3:][::-1]
            
            print("\n TOP PREDICTIONS FROM MODEL:")
            results = []
            for idx in top_3_idx:
                disease_name = self.class_names[idx]
                confidence = round(float(predictions[idx]) * 100, 2)
                display_name = disease_name.replace('___', ' - ').replace('_', ' ')
                print(f"   {display_name}: {confidence}%")
                results.append({
                    'disease_code': disease_name,
                    'disease_name': display_name,
                    'confidence': confidence,
                    'index': int(idx)
                })
            return results
        except Exception as e:
            print(f" Prediction error: {e}")
            return self._demo_predict(image_bytes)
    
    def _demo_predict(self, image_bytes):
        print(" DEMO MODE: Returning sample prediction")
        return [
            {
                'disease_code': 'Tomato___Late_blight',
                'disease_name': 'Tomato - Late Blight',
                'confidence': 96.5,
                'index': 32
            }
        ]

# Singleton instance
_predictor = None

def get_predictor():
    global _predictor
    if _predictor is None:
        _predictor = DiseasePredictor()
    return _predictor