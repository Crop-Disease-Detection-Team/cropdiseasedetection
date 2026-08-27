"""
Dataset Cleaning, Validation, and Batch Preparation Module for AgriVision AI.
Handles PlantVillage dataset directory structure, removing corrupted images,
splitting into train/validation/test datasets, and optimizing input pipeline.
"""

import os
import hashlib
from pathlib import Path
from PIL import Image


def remove_corrupted_and_duplicates(data_dir: str, remove_duplicates: bool = True) -> dict:
    """
    Scans the dataset directory, removes unreadable/corrupted images,
    and optionally removes duplicate images based on MD5 checksum.
    
    Returns summary stats dict.
    """
    total_scanned = 0
    corrupted_removed = 0
    duplicates_removed = 0
    seen_hashes = set()
    
    path = Path(data_dir)
    if not path.exists():
        raise FileNotFoundError(f"Dataset path '{data_dir}' does not exist.")
        
    for file_path in path.rglob("*"):
        if file_path.is_file() and file_path.suffix.lower() in ('.jpg', '.jpeg', '.png', '.bmp', '.webp'):
            total_scanned += 1
            # Check for corruption
            try:
                with Image.open(file_path) as img:
                    img.verify()
            except Exception:
                os.remove(file_path)
                corrupted_removed += 1
                continue
                
            # Check for duplicates
            if remove_duplicates:
                try:
                    with open(file_path, 'rb') as f:
                        file_hash = hashlib.md5(f.read()).hexdigest()
                    if file_hash in seen_hashes:
                        os.remove(file_path)
                        duplicates_removed += 1
                    else:
                        seen_hashes.add(file_hash)
                except Exception:
                    pass
                    
    stats = {
        'total_scanned': total_scanned,
        'corrupted_removed': corrupted_removed,
        'duplicates_removed': duplicates_removed,
        'valid_images': total_scanned - corrupted_removed - duplicates_removed,
    }
    print(f"Dataset cleanup stats: {stats}")
    return stats


def load_and_clean_dataset(data_dir: str):
    """Clean the dataset directory before training."""
    return remove_corrupted_and_duplicates(data_dir)


def prepare_datasets(data_dir: str, img_size=(224, 224), batch_size=32, val_split=0.15, test_split=0.15, seed=123):
    """
    Load dataset from directory and split into train, validation, and test sets.
    Applies caching and prefetching for high throughput performance.
    """
    import tensorflow as tf

    total_val_test = val_split + test_split
    
    train_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=total_val_test,
        subset="training",
        seed=seed,
        image_size=img_size,
        batch_size=batch_size,
    )
    
    val_test_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=total_val_test,
        subset="validation",
        seed=seed,
        image_size=img_size,
        batch_size=batch_size,
    )
    
    class_names = train_ds.class_names
    
    # Split val_test_ds into val and test
    val_batches = int(len(val_test_ds) * (val_split / total_val_test))
    val_ds = val_test_ds.take(val_batches)
    test_ds = val_test_ds.skip(val_batches)
    
    # Optimize execution pipeline with autotuning
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)
    test_ds = test_ds.cache().prefetch(buffer_size=AUTOTUNE)
    
    return train_ds, val_ds, test_ds, class_names
