"""
AgriVision AI Production Model Training Script.
Primary Architecture: MobileNetV2 (ImageNet pretrained)
Fallback Architecture: EfficientNetB0
Features:
- Custom classification head (GAP -> BatchNorm -> Dropout -> Dense -> Dropout -> Softmax)
- Top-layer warmup training + fine-tuning of top layers
- Adam optimizer, EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
- Export of best_model.keras, class_indices.json, training_history.csv, graphs
"""

import argparse
import os

from .dataset import prepare_datasets, load_and_clean_dataset
from .preprocess import get_data_augmentation
from .utils import (
    plot_training_history,
    save_class_indices,
    save_training_history_csv,
)


def build_model(model_type='efficientnetb0', num_classes=38, img_size=(224, 224)):
    """
    Construct model with EfficientNetB0 (primary) or MobileNetV2 (fallback)
    with custom classification head.
    """
    import tensorflow as tf
    from tensorflow.keras import applications, layers, models

    input_shape = (*img_size, 3)

    if model_type.lower() == 'efficientnetb0':
        base_model = applications.EfficientNetB0(
            input_shape=input_shape, include_top=False, weights='imagenet'
        )
    elif model_type.lower() == 'mobilenetv2':
        base_model = applications.MobileNetV2(
            input_shape=input_shape, include_top=False, weights='imagenet'
        )
    else:
        raise ValueError(f"Unsupported model_type: '{model_type}'. Choose 'efficientnetb0' or 'mobilenetv2'.")

    base_model.trainable = False  # Freeze base during warmup

    inputs = tf.keras.Input(shape=input_shape)
    
    # Preprocessing
    x = get_data_augmentation()(inputs)
    if model_type.lower() == 'mobilenetv2':
        x = applications.mobilenet_v2.preprocess_input(x)

    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(256, activation='relu')(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)

    model = models.Model(inputs, outputs, name=f"AgriVision_{model_type}")
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )
    return model, base_model


def train(data_dir: str, model_type='mobilenetv2', epochs=20, fine_tune_epochs=10, batch_size=32, save_dir='../model_store'):
    """Full production model training workflow."""
    import tensorflow as tf
    from tensorflow.keras import callbacks

    os.makedirs(save_dir, exist_ok=True)
    
    # 1. Clean dataset
    print("Step 1: Cleaning dataset...")
    load_and_clean_dataset(data_dir)
    
    # 2. Prepare train, val, test datasets
    print("Step 2: Preparing datasets...")
    train_ds, val_ds, test_ds, class_names = prepare_datasets(
        data_dir, batch_size=batch_size
    )
    num_classes = len(class_names)
    print(f"Loaded {num_classes} disease/healthy classes.")

    # Save class_indices.json
    save_class_indices(class_names, os.path.join(save_dir, 'class_indices.json'))

    # 3. Build model architecture
    model, base_model = build_model(model_type, num_classes)
    model.summary()

    # Setup callbacks
    checkpoint_path = os.path.join(save_dir, 'best_model.keras')
    checkpoint = callbacks.ModelCheckpoint(
        filepath=checkpoint_path,
        save_best_only=True,
        monitor='val_accuracy',
        mode='max',
        verbose=1,
    )
    early_stop = callbacks.EarlyStopping(
        monitor='val_loss', patience=5, restore_best_weights=True, verbose=1
    )
    reduce_lr = callbacks.ReduceLROnPlateau(
        monitor='val_loss', factor=0.2, patience=3, min_lr=1e-6, verbose=1
    )

    # 4. Warmup phase (Top-layer training)
    print("\n--- Phase 1: Training Classification Head ---")
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=epochs,
        callbacks=[checkpoint, early_stop, reduce_lr],
    )

    # 5. Fine-tuning phase
    print("\n--- Phase 2: Fine-Tuning Upper Layers ---")
    base_model.trainable = True
    fine_tune_at = 100
    for layer in base_model.layers[:fine_tune_at]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    total_epochs = epochs + fine_tune_epochs
    history_fine = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=total_epochs,
        initial_epoch=history.epoch[-1] if history.epoch else epochs,
        callbacks=[checkpoint, early_stop, reduce_lr],
    )

    # 6. Save artifacts and run evaluation
    print("\n--- Step 6: Exporting Artifacts ---")
    plot_training_history(history_fine, os.path.join(save_dir, 'training_history.png'))
    save_training_history_csv(history_fine, os.path.join(save_dir, 'training_history.csv'))
    
    model.save(os.path.join(save_dir, 'agrivision_model.keras'))
    print(f"Training completed successfully! Model exported to {save_dir}")

    # 7. Evaluate on test set
    print("\n--- Step 7: Evaluating Model on Test Dataset ---")
    try:
        from .evaluate import evaluate
        evaluate(data_dir=data_dir, model_path=checkpoint_path, save_dir=save_dir)
    except Exception as e:
        print(f"Evaluation skipped or failed: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train AgriVision AI Crop Disease Detection Model")
    parser.add_argument("--data_dir", type=str, required=True, help="Directory containing PlantVillage subfolders")
    parser.add_argument("--model", type=str, choices=['efficientnetb0', 'mobilenetv2'], default='efficientnetb0')
    parser.add_argument("--epochs", type=int, default=20, help="Initial top-layer epochs")
    parser.add_argument("--fine_tune_epochs", type=int, default=10, help="Fine-tuning epochs")
    parser.add_argument("--batch_size", type=int, default=32)
    parser.add_argument("--save_dir", type=str, default="../model_store")
    
    args = parser.parse_args()
    train(
        args.data_dir,
        model_type=args.model,
        epochs=args.epochs,
        fine_tune_epochs=args.fine_tune_epochs,
        batch_size=args.batch_size,
        save_dir=args.save_dir,
    )
