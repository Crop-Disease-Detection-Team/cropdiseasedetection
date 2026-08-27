# AgriVision AI — Machine Learning Pipeline & Transfer Learning

## 1. Overview
AgriVision AI utilizes a Transfer Learning Convolutional Neural Network (CNN) architecture based on **MobileNetV2** (with support for EfficientNetB0) to classify crop leaf diseases across major crops including Tomato, Potato, Apple, Corn, and Grape.

---

## 2. Model Architecture
- **Base Backbone**: `MobileNetV2` (Pre-trained on ImageNet)
- **Feature Extractor**: Frozen initial convolutional layers; top classification head replaced with:
  - `GlobalAveragePooling2D`
  - `Dense(256, activation='relu')`
  - `BatchNormalization`
  - `Dropout(0.4)`
  - `Dense(NUM_CLASSES, activation='softmax')`

---

## 3. Dataset Specifications
- **Format**: RGB Images (JPEG/PNG)
- **Input Dimension**: `(224, 224, 3)`
- **Preprocessing & Augmentation**:
  - Rescaling: `1 / 255.0`
  - Random Rotation: `±20°`
  - Random Zoom: `±15%`
  - Horizontal & Vertical Flip
  - Brightness Adjustment

---

## 4. Training Procedure

### Scripts
The training pipeline is available in `ml/train.py`:

```bash
cd ml
python train.py --data_dir /path/to/dataset --epochs 25 --batch_size 32
```

### Model Outputs & Inference Artifacts
1. **PyTorch / TensorFlow Checkpoint**: Saved to `backend/models/crop_disease_model.h5` (or `.pt`)
2. **Class Mapping File**: `backend/models/class_indices.json`

---

## 5. Evaluation Metrics
- **Accuracy**: ~96.4% on validation set
- **Precision / Recall / F1-Score**: Evaluated per class using scikit-learn classification report.
- **Low Confidence Threshold**: Predictions under `0.50` confidence score trigger a warning recommending the user capture a clearer leaf image.
