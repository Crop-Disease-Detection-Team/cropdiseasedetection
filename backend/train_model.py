"""
AgriVision AI — Convenience Model Training Script.

Usage:
    python train_model.py --data_dir /path/to/PlantVillage/dataset
    python train_model.py --data_dir ./data/PlantVillage --epochs 15 --model mobilenetv2

Outputs generated in model_store/:
- best_model.keras (Trained model weights)
- agrivision_model.keras (Duplicate for compatibility)
- class_indices.json (Class mapping dictionary)
- training_history.png & training_history.csv
- confusion_matrix.png
- classification_report.txt
"""

import argparse
import os
import sys

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ml.train import train

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train AgriVision AI Crop Disease Detection Model")
    parser.add_argument("--data_dir", type=str, required=True, help="Directory containing PlantVillage subfolders")
    parser.add_argument("--model", type=str, choices=['efficientnetb0', 'mobilenetv2'], default='efficientnetb0')
    parser.add_argument("--epochs", type=int, default=20, help="Initial top-layer epochs")
    parser.add_argument("--fine_tune_epochs", type=int, default=10, help="Fine-tuning epochs")
    parser.add_argument("--batch_size", type=int, default=32)
    parser.add_argument("--save_dir", type=str, default="model_store")
    
    args = parser.parse_args()
    
    save_path = os.path.abspath(args.save_dir)
    os.makedirs(save_path, exist_ok=True)
    
    print("=" * 60)
    print("AgriVision AI — Production Model Training")
    print("=" * 60)
    print(f"Dataset path: {args.data_dir}")
    print(f"Architecture: {args.model}")
    print(f"Epochs: {args.epochs} warmup + {args.fine_tune_epochs} fine-tune")
    print(f"Save Directory: {save_path}")
    print("=" * 60)
    
    train(
        data_dir=args.data_dir,
        model_type=args.model,
        epochs=args.epochs,
        fine_tune_epochs=args.fine_tune_epochs,
        batch_size=args.batch_size,
        save_dir=save_path,
    )
