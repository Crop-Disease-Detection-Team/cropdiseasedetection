"""
Helper Utilities for AgriVision AI Machine Learning Pipeline.
Handles saving class index mappings, plotting accuracy/loss curves,
generating confusion matrix plots, and saving classification metrics.
"""

import json
import os


def save_class_indices(class_names: list, save_path: str):
    """Save index -> class_name dictionary as JSON."""
    idx_map = {i: name for i, name in enumerate(class_names)}
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    with open(save_path, 'w') as f:
        json.dump(idx_map, f, indent=2)
    print(f"Saved {len(class_names)} class indices to {save_path}")


def load_class_indices(load_path: str) -> list:
    """Load index -> class_name map and return as sorted list of class names."""
    with open(load_path, 'r') as f:
        idx_map = json.load(f)
    return [idx_map[str(i)] for i in range(len(idx_map))]


def plot_training_history(history, save_path: str = 'training_history.png'):
    """Plot and save training vs validation accuracy and loss graphs."""
    import matplotlib.pyplot as plt

    acc = history.history.get('accuracy', [])
    val_acc = history.history.get('val_accuracy', [])
    loss = history.history.get('loss', [])
    val_loss = history.history.get('val_loss', [])
    epochs_range = range(len(acc))

    plt.figure(figsize=(14, 5))
    
    plt.subplot(1, 2, 1)
    plt.plot(epochs_range, acc, label='Training Accuracy', color='#2e7d32', linewidth=2)
    plt.plot(epochs_range, val_acc, label='Validation Accuracy', color='#1565c0', linewidth=2)
    plt.legend(loc='lower right')
    plt.title('Training and Validation Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')

    plt.subplot(1, 2, 2)
    plt.plot(epochs_range, loss, label='Training Loss', color='#c62828', linewidth=2)
    plt.plot(epochs_range, val_loss, label='Validation Loss', color='#f57c00', linewidth=2)
    plt.legend(loc='upper right')
    plt.title('Training and Validation Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')

    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    plt.tight_layout()
    plt.savefig(save_path, dpi=300)
    plt.close()
    print(f"Saved training history graph to {save_path}")


def save_training_history_csv(history, save_path: str = 'training_history.csv'):
    """Save history object metrics to CSV file."""
    import pandas as pd
    df = pd.DataFrame(history.history)
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    df.to_csv(save_path, index_label='epoch')
    print(f"Saved training history log to {save_path}")


def plot_confusion_matrix(y_true, y_pred, class_names, save_path: str = 'confusion_matrix.png'):
    """Generate and save a styled confusion matrix heatmap."""
    import matplotlib.pyplot as plt
    import seaborn as sns
    from sklearn.metrics import confusion_matrix

    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(18, 16))
    sns.heatmap(cm, annot=False, fmt='d', cmap='YlGnBu',
                xticklabels=class_names, yticklabels=class_names)
    plt.title('PlantVillage 38-Class Confusion Matrix')
    plt.xlabel('Predicted Label')
    plt.ylabel('True Label')
    plt.xticks(rotation=90, fontsize=8)
    plt.yticks(rotation=0, fontsize=8)
    
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    plt.tight_layout()
    plt.savefig(save_path, dpi=300)
    plt.close()
    print(f"Saved confusion matrix plot to {save_path}")


def save_classification_report(y_true, y_pred, class_names, save_path: str = 'classification_report.txt'):
    """Generate classification report text (precision, recall, f1-score) and save to file."""
    from sklearn.metrics import classification_report
    report = classification_report(y_true, y_pred, target_names=class_names, digits=4)
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    with open(save_path, 'w') as f:
        f.write("AgriVision AI - PlantVillage Classification Report\n")
        f.write("=" * 60 + "\n\n")
        f.write(report)
    print(f"Saved classification report to {save_path}")
