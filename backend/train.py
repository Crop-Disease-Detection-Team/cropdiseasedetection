import os
import json
import argparse
import tensorflow as tf
from tensorflow.keras import layers, models, applications, callbacks
import matplotlib.pyplot as plt
import numpy as np

def build_model(model_type='efficientnetb0', num_classes=38):
    input_shape = (224, 224, 3)
    
    if model_type == 'efficientnetb0':
        base_model = applications.EfficientNetB0(input_shape=input_shape, include_top=False, weights='imagenet')
    elif model_type == 'mobilenetv2':
        base_model = applications.MobileNetV2(input_shape=input_shape, include_top=False, weights='imagenet')
    else:
        raise ValueError("Unsupported model type. Choose 'efficientnetb0' or 'mobilenetv2'.")
    
    base_model.trainable = False  # Freeze the base model
    
    # Data Augmentation layer inside the model for faster GPU processing
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.2),
        layers.RandomZoom(0.2),
        layers.RandomContrast(0.2),
    ], name="data_augmentation")

    inputs = tf.keras.Input(shape=input_shape)
    x = data_augmentation(inputs)
    
    if model_type == 'mobilenetv2':
        # MobileNetV2 expects pixels in [-1, 1]
        x = applications.mobilenet_v2.preprocess_input(x)
    elif model_type == 'efficientnetb0':
        # EfficientNet expects pixels in [0, 255] which is default from dataset loading
        pass
    
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)
    
    model = models.Model(inputs, outputs)
    
    model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
                  loss='sparse_categorical_crossentropy',
                  metrics=['accuracy'])
    return model, base_model

def plot_history(history, save_path='training_history.png'):
    acc = history.history['accuracy']
    val_acc = history.history['val_accuracy']
    loss = history.history['loss']
    val_loss = history.history['val_loss']

    plt.figure(figsize=(12, 4))
    plt.subplot(1, 2, 1)
    plt.plot(acc, label='Training Accuracy')
    plt.plot(val_acc, label='Validation Accuracy')
    plt.legend(loc='lower right')
    plt.title('Training and Validation Accuracy')

    plt.subplot(1, 2, 2)
    plt.plot(loss, label='Training Loss')
    plt.plot(val_loss, label='Validation Loss')
    plt.legend(loc='upper right')
    plt.title('Training and Validation Loss')
    plt.savefig(save_path)
    print(f"Training history plot saved to {save_path}")

def train_model(data_dir, model_type='mobilenetv2', epochs=20, batch_size=32, save_dir='../model_store'):
    os.makedirs(save_dir, exist_ok=True)
    
    # Load dataset
    print(f"Loading dataset from {data_dir}...")
    train_dataset = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=(224, 224),
        batch_size=batch_size)

    val_dataset = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=(224, 224),
        batch_size=batch_size)

    class_names = train_dataset.class_names
    num_classes = len(class_names)
    print(f"Found {num_classes} classes.")
    
    # Save class indices
    with open(os.path.join(save_dir, 'class_indices.json'), 'w') as f:
        json.dump({i: name for i, name in enumerate(class_names)}, f)
    print(f"Saved class indices to {os.path.join(save_dir, 'class_indices.json')}")

    # Optimize dataset performance
    AUTOTUNE = tf.data.AUTOTUNE
    train_dataset = train_dataset.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_dataset = val_dataset.cache().prefetch(buffer_size=AUTOTUNE)

    model, base_model = build_model(model_type, num_classes)
    model.summary()

    # Callbacks
    model_checkpoint = callbacks.ModelCheckpoint(
        filepath=os.path.join(save_dir, 'agrivision_model.keras'),
        save_best_only=True,
        monitor='val_accuracy'
    )
    early_stopping = callbacks.EarlyStopping(
        monitor='val_loss',
        patience=5,
        restore_best_weights=True
    )
    reduce_lr = callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.2,
        patience=3,
        min_lr=1e-6
    )

    # Train top layer
    print("Training top layer...")
    history = model.fit(
        train_dataset,
        validation_data=val_dataset,
        epochs=epochs,
        callbacks=[model_checkpoint, early_stopping, reduce_lr]
    )
    
    plot_history(history, save_path=os.path.join(save_dir, 'training_history_top.png'))

    # Fine-tuning
    print("Fine-tuning base model...")
    base_model.trainable = True
    
    # Freeze the first 100 layers (heuristic for MobileNetV2)
    fine_tune_at = 100
    if len(base_model.layers) > fine_tune_at:
        for layer in base_model.layers[:fine_tune_at]:
            layer.trainable = False

    model.compile(loss='sparse_categorical_crossentropy',
                  optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
                  metrics=['accuracy'])
    
    total_epochs = epochs + 10 # 10 fine-tuning epochs
    history_fine = model.fit(
        train_dataset,
        epochs=total_epochs,
        initial_epoch=history.epoch[-1],
        validation_data=val_dataset,
        callbacks=[model_checkpoint, early_stopping, reduce_lr]
    )
    
    plot_history(history_fine, save_path=os.path.join(save_dir, 'training_history_finetune.png'))
    print("Training complete!")
    
    # Save final model just in case (though ModelCheckpoint saves the best one)
    final_model_path = os.path.join(save_dir, 'agrivision_model_final.keras')
    model.save(final_model_path)
    print(f"Final model saved to {final_model_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train AgriVision AI Model")
    parser.add_argument("--data_dir", type=str, required=True, help="Path to the PlantVillage dataset")
    parser.add_argument("--model", type=str, choices=['efficientnetb0', 'mobilenetv2'], default='efficientnetb0', help="Model architecture")
    parser.add_argument("--epochs", type=int, default=20, help="Number of initial training epochs")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    args = parser.parse_args()
    
    train_model(args.data_dir, args.model, args.epochs, args.batch_size)
