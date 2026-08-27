"""
AgriVision AI Model Evaluation Module.
Generates evaluation metrics on test dataset:
- Accuracy, Precision, Recall, F1-Score
- Confusion Matrix Heatmap
- Classification Report (saved as text file)
- ROC curve export where applicable
"""

import argparse
import os
import numpy as np
import tensorflow as tf

from .dataset import prepare_datasets
from .utils import (
    load_class_indices,
    plot_confusion_matrix,
    save_classification_report,
)


def evaluate(data_dir: str, model_path: str, save_dir: str = '../model_store'):
    """Run model evaluation on test dataset split."""
    os.makedirs(save_dir, exist_ok=True)
    
    print(f"Loading trained model from {model_path}...")
    model = tf.keras.models.load_model(model_path)
    
    print(f"Loading test dataset from {data_dir}...")
    _, _, test_ds, class_names = prepare_datasets(data_dir)
    
    y_true = []
    y_pred = []
    
    print("Running inference on test dataset batches...")
    for images, labels in test_ds:
        preds = model.predict(images, verbose=0)
        pred_labels = np.argmax(preds, axis=1)
        
        y_true.extend(labels.numpy())
        y_pred.extend(pred_labels)

    y_true = np.array(y_true)
    y_pred = np.array(y_pred)

    print("\n--- Evaluation Results ---")
    plot_confusion_matrix(
        y_true, y_pred, class_names, os.path.join(save_dir, 'confusion_matrix.png')
    )
    save_classification_report(
        y_true, y_pred, class_names, os.path.join(save_dir, 'classification_report.txt')
    )
    
    accuracy = np.mean(y_true == y_pred)
    print(f"Test Accuracy: {accuracy * 100:.2f}%")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate AgriVision AI Model")
    parser.add_argument("--data_dir", type=str, required=True)
    parser.add_argument("--model_path", type=str, default="../model_store/best_model.keras")
    parser.add_argument("--save_dir", type=str, default="../model_store")
    
    args = parser.parse_args()
    evaluate(args.data_dir, args.model_path, args.save_dir)
