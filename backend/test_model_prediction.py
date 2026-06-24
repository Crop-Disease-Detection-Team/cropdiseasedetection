import tensorflow as tf
import numpy as np
from PIL import Image
import os

# Suppress warnings
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

# Load model
model_path = "models/crop_disease_model.h5"

if not os.path.exists(model_path):
    print(f" Model not found at {model_path}")
    print("Please train the model first: python train_model.py")
    exit(1)

print("📁 Loading model...")
model = tf.keras.models.load_model(model_path)
print("✅ Model loaded successfully!")

# Load class names
class_names_path = "models/class_names.txt"
if os.path.exists(class_names_path):
    with open(class_names_path, 'r') as f:
        class_names = [line.strip() for line in f.readlines()]
    print(f" Loaded {len(class_names)} disease classes")
else:
    # Default class names (38 diseases)
    class_names = [
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

# Create a simple test image (random noise - for testing only)
print("\n🔍 Creating test image...")
test_img = np.random.rand(224, 224, 3) * 255
test_img = test_img.astype(np.uint8)

# Preprocess
test_img = test_img / 255.0
test_img = np.expand_dims(test_img, axis=0)

print("Making prediction...")
predictions = model.predict(test_img)
predicted_idx = np.argmax(predictions[0])
confidence = predictions[0][predicted_idx] * 100

print(f"\n Prediction Result:")
print(f"   Disease: {class_names[predicted_idx]}")
print(f"   Confidence: {confidence:.2f}%")

# Show top 3 predictions
print(f"\n Top 3 Predictions:")
top_3 = np.argsort(predictions[0])[-3:][::-1]
for i, idx in enumerate(top_3):
    print(f"   {i+1}. {class_names[idx]}: {predictions[0][idx]*100:.2f}%")

print("\n Test complete!")