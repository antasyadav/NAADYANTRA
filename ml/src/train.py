"""
Model Training Pipeline for HazGuard

Trains baseline models on extracted features.
Supports logistic regression and simple neural network models.

This is a synthetic-data prototype. Results do not represent real-world performance.
"""

import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, Tuple, Optional
import json
from datetime import datetime

# Scikit-learn
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    accuracy_score,
    precision_recall_fscore_support
)
import joblib

# TensorFlow for neural network (optional)
try:
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers
    TENSORFLOW_AVAILABLE = True
except ImportError:
    TENSORFLOW_AVAILABLE = False
    print("Warning: TensorFlow not available. Neural network training will be skipped.")


class ModelTrainer:
    """Train and evaluate models on extracted features."""

    def __init__(
        self,
        random_state: int = 42,
        output_dir: Optional[Path] = None
    ):
        self.random_state = random_state
        self.output_dir = output_dir or Path(__file__).parent.parent / "models"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.scaler = StandardScaler()
        self.label_encoder = LabelEncoder()
        self.model = None
        self.feature_names = None

    def prepare_data(
        self,
        train_path: Path,
        val_path: Path,
        test_path: Path
    ) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """
        Load and prepare training, validation, and test data.

        Args:
            train_path: Path to training features CSV
            val_path: Path to validation features CSV
            test_path: Path to test features CSV

        Returns:
            X_train, y_train, X_val, y_val, X_test, y_test
        """
        train_df = pd.read_csv(train_path)
        val_df = pd.read_csv(val_path)
        test_df = pd.read_csv(test_path)

        # Identify feature columns (exclude metadata)
        metadata_cols = ['sample_id', 'label', 'source_type', 'recording_id', 'split']
        self.feature_names = [col for col in train_df.columns if col not in metadata_cols]

        print(f"Feature columns ({len(self.feature_names)}): {self.feature_names}")

        # Extract features
        X_train = train_df[self.feature_names].values
        X_val = val_df[self.feature_names].values
        X_test = test_df[self.feature_names].values

        # Extract labels
        y_train = train_df['label'].values
        y_val = val_df['label'].values
        y_test = test_df['label'].values

        # Encode labels
        y_train_encoded = self.label_encoder.fit_transform(y_train)
        y_val_encoded = self.label_encoder.transform(y_val)
        y_test_encoded = self.label_encoder.transform(y_test)

        print(f"\nLabel mapping: {dict(zip(self.label_encoder.classes_, range(len(self.label_encoder.classes_))))}")

        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_val_scaled = self.scaler.transform(X_val)
        X_test_scaled = self.scaler.transform(X_test)

        print(f"\nData shapes:")
        print(f"  Train: {X_train_scaled.shape}")
        print(f"  Val:   {X_val_scaled.shape}")
        print(f"  Test:  {X_test_scaled.shape}")

        return X_train_scaled, y_train_encoded, X_val_scaled, y_val_encoded, X_test_scaled, y_test_encoded

    def train_logistic_regression(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray
    ) -> Dict:
        """
        Train logistic regression baseline model.

        Args:
            X_train, y_train: Training data
            X_val, y_val: Validation data

        Returns:
            Training metrics dictionary
        """
        print("\n" + "="*60)
        print("Training Logistic Regression Model")
        print("="*60)

        self.model = LogisticRegression(
            random_state=self.random_state,
            max_iter=1000,
            class_weight='balanced'
        )

        self.model.fit(X_train, y_train)

        # Evaluate on validation set
        val_pred = self.model.predict(X_val)
        val_acc = accuracy_score(y_val, val_pred)

        print(f"\nValidation Accuracy: {val_acc:.4f}")
        print("\nClassification Report (Validation):")
        # Get only classes present in validation set
        unique_labels = np.unique(np.concatenate([y_val, val_pred]))
        target_names = [self.label_encoder.classes_[i] for i in unique_labels]
        print(classification_report(
            y_val, val_pred,
            labels=unique_labels,
            target_names=target_names,
            zero_division=0
        ))

        metrics = {
            'model_type': 'logistic_regression',
            'validation_accuracy': val_acc,
            'feature_importance': dict(zip(self.feature_names, self.model.coef_[0]))
        }

        return metrics

    def train_random_forest(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray
    ) -> Dict:
        """
        Train random forest baseline model.

        Args:
            X_train, y_train: Training data
            X_val, y_val: Validation data

        Returns:
            Training metrics dictionary
        """
        print("\n" + "="*60)
        print("Training Random Forest Model")
        print("="*60)

        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=self.random_state,
            class_weight='balanced'
        )

        self.model.fit(X_train, y_train)

        # Evaluate on validation set
        val_pred = self.model.predict(X_val)
        val_acc = accuracy_score(y_val, val_pred)

        print(f"\nValidation Accuracy: {val_acc:.4f}")
        print("\nClassification Report (Validation):")
        # Get only classes present in validation set
        unique_labels = np.unique(np.concatenate([y_val, val_pred]))
        target_names = [self.label_encoder.classes_[i] for i in unique_labels]
        print(classification_report(
            y_val, val_pred,
            labels=unique_labels,
            target_names=target_names,
            zero_division=0
        ))

        # Feature importance
        feature_importance = dict(zip(self.feature_names, self.model.feature_importances_))

        metrics = {
            'model_type': 'random_forest',
            'validation_accuracy': val_acc,
            'feature_importance': feature_importance
        }

        return metrics

    def train_neural_network(
        self,
        X_train: np.ndarray,
        y_train: np.ndarray,
        X_val: np.ndarray,
        y_val: np.ndarray,
        epochs: int = 50,
        batch_size: int = 32
    ) -> Dict:
        """
        Train simple neural network model.

        Args:
            X_train, y_train: Training data
            X_val, y_val: Validation data
            epochs: Number of training epochs
            batch_size: Training batch size

        Returns:
            Training metrics dictionary
        """
        if not TENSORFLOW_AVAILABLE:
            raise ImportError("TensorFlow is not available. Cannot train neural network.")

        print("\n" + "="*60)
        print("Training Neural Network Model")
        print("="*60)

        n_classes = len(self.label_encoder.classes_)
        n_features = X_train.shape[1]

        # Build model
        self.model = keras.Sequential([
            layers.Input(shape=(n_features,)),
            layers.Dense(64, activation='relu'),
            layers.Dropout(0.3),
            layers.Dense(32, activation='relu'),
            layers.Dropout(0.3),
            layers.Dense(n_classes, activation='softmax')
        ])

        self.model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )

        self.model.summary()

        # Train
        history = self.model.fit(
            X_train, y_train,
            validation_data=(X_val, y_val),
            epochs=epochs,
            batch_size=batch_size,
            verbose=1
        )

        # Evaluate on validation set
        val_loss, val_acc = self.model.evaluate(X_val, y_val, verbose=0)

        print(f"\nValidation Accuracy: {val_acc:.4f}")

        metrics = {
            'model_type': 'neural_network',
            'validation_accuracy': val_acc,
            'training_history': {
                'loss': history.history['loss'],
                'val_loss': history.history['val_loss'],
                'accuracy': history.history['accuracy'],
                'val_accuracy': history.history['val_accuracy']
            }
        }

        return metrics

    def evaluate(
        self,
        X_test: np.ndarray,
        y_test: np.ndarray
    ) -> Dict:
        """
        Evaluate model on test set.

        Args:
            X_test, y_test: Test data

        Returns:
            Evaluation metrics dictionary
        """
        print("\n" + "="*60)
        print("Evaluating on Test Set")
        print("="*60)

        if TENSORFLOW_AVAILABLE and isinstance(self.model, keras.Model):
            # Neural network
            y_pred_proba = self.model.predict(X_test, verbose=0)
            y_pred = np.argmax(y_pred_proba, axis=1)
        else:
            # Scikit-learn model
            y_pred = self.model.predict(X_test)

        test_acc = accuracy_score(y_test, y_pred)

        print(f"\nTest Accuracy: {test_acc:.4f}")
        print("\nClassification Report (Test):")
        # Get only classes present in test set
        unique_labels = np.unique(np.concatenate([y_test, y_pred]))
        target_names = [self.label_encoder.classes_[i] for i in unique_labels]
        print(classification_report(
            y_test, y_pred,
            labels=unique_labels,
            target_names=target_names,
            zero_division=0
        ))

        # Confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        print("\nConfusion Matrix:")
        print(cm)

        # Per-class metrics
        precision, recall, f1, support = precision_recall_fscore_support(
            y_test, y_pred, labels=range(len(self.label_encoder.classes_)), zero_division=0
        )

        per_class_metrics = {}
        for i, label in enumerate(self.label_encoder.classes_):
            per_class_metrics[label] = {
                'precision': float(precision[i]) if i < len(precision) else 0.0,
                'recall': float(recall[i]) if i < len(recall) else 0.0,
                'f1': float(f1[i]) if i < len(f1) else 0.0,
                'support': int(support[i]) if i < len(support) else 0
            }

        metrics = {
            'test_accuracy': test_acc,
            'confusion_matrix': cm.tolist(),
            'per_class_metrics': per_class_metrics
        }

        return metrics

    def save_model(
        self,
        model_name: str,
        training_metrics: Dict,
        evaluation_metrics: Dict
    ):
        """
        Save model, scaler, and metadata.

        Args:
            model_name: Name for the saved model
            training_metrics: Training metrics dictionary
            evaluation_metrics: Evaluation metrics dictionary
        """
        model_dir = self.output_dir / model_name
        model_dir.mkdir(parents=True, exist_ok=True)

        # Save model
        if TENSORFLOW_AVAILABLE and isinstance(self.model, keras.Model):
            model_path = model_dir / "model.keras"
            self.model.save(model_path)
            print(f"\nModel saved to: {model_path}")
        else:
            model_path = model_dir / "model.joblib"
            joblib.dump(self.model, model_path)
            print(f"\nModel saved to: {model_path}")

        # Save scaler and label encoder
        scaler_path = model_dir / "scaler.joblib"
        encoder_path = model_dir / "label_encoder.joblib"
        joblib.dump(self.scaler, scaler_path)
        joblib.dump(self.label_encoder, encoder_path)
        print(f"Scaler saved to: {scaler_path}")
        print(f"Label encoder saved to: {encoder_path}")

        # Save metadata
        metadata = {
            'model_name': model_name,
            'model_type': training_metrics['model_type'],
            'feature_names': self.feature_names,
            'label_classes': self.label_encoder.classes_.tolist(),
            'n_features': len(self.feature_names),
            'n_classes': len(self.label_encoder.classes_),
            'random_state': self.random_state,
            'trained_at': datetime.utcnow().isoformat(),
            'training_metrics': training_metrics,
            'evaluation_metrics': evaluation_metrics,
            'data_source': 'synthetic',
            'note': 'This model was trained on synthetic data only. '
                   'It is a prototype for pipeline development and does not represent real-world performance.'
        }

        metadata_path = model_dir / "metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        print(f"Metadata saved to: {metadata_path}")

        return model_dir


def main():
    """Train baseline models on synthetic dataset."""
    # Paths
    dataset_dir = Path(__file__).parent.parent / "data" / "synthetic"
    train_path = dataset_dir / "features_train.csv"
    val_path = dataset_dir / "features_val.csv"
    test_path = dataset_dir / "features_test.csv"

    # Train logistic regression
    print("\n" + "="*60)
    print("LOGISTIC REGRESSION")
    print("="*60)
    trainer = ModelTrainer(random_state=42)
    X_train, y_train, X_val, y_val, X_test, y_test = trainer.prepare_data(
        train_path, val_path, test_path
    )
    lr_metrics = trainer.train_logistic_regression(X_train, y_train, X_val, y_val)
    lr_eval = trainer.evaluate(X_test, y_test)
    trainer.save_model("logistic_regression_baseline", lr_metrics, lr_eval)

    # Train random forest
    print("\n" + "="*60)
    print("RANDOM FOREST")
    print("="*60)
    trainer = ModelTrainer(random_state=42)
    X_train, y_train, X_val, y_val, X_test, y_test = trainer.prepare_data(
        train_path, val_path, test_path
    )
    rf_metrics = trainer.train_random_forest(X_train, y_train, X_val, y_val)
    rf_eval = trainer.evaluate(X_test, y_test)
    trainer.save_model("random_forest_baseline", rf_metrics, rf_eval)

    # Train neural network (if TensorFlow available)
    if TENSORFLOW_AVAILABLE:
        print("\n" + "="*60)
        print("NEURAL NETWORK")
        print("="*60)
        trainer = ModelTrainer(random_state=42)
        X_train, y_train, X_val, y_val, X_test, y_test = trainer.prepare_data(
            train_path, val_path, test_path
        )
        nn_metrics = trainer.train_neural_network(X_train, y_train, X_val, y_val, epochs=30)
        nn_eval = trainer.evaluate(X_test, y_test)
        trainer.save_model("neural_network_baseline", nn_metrics, nn_eval)
    else:
        print("\nSkipping neural network training (TensorFlow not available)")

    print("\n" + "="*60)
    print("TRAINING COMPLETE")
    print("="*60)
    print("\nNOTE: All models trained on synthetic data only.")
    print("These are prototypes for pipeline development.")
    print("Do not use these results as evidence of real-world performance.")


if __name__ == "__main__":
    main()
