"""
Signal Preprocessing Pipeline for HazGuard

Implements signal preprocessing matching the firmware implementation.
Features are extracted from raw ADC samples to prepare data for ML training.

Firmware Reference: leak_detector.ino
- Sampling rate: 4000 Hz
- Window duration: 1000 ms (4000 samples)
- DC-block filter: First-order IIR with coefficient 0.995
- ADC resolution: 12-bit (0-4095)
"""

import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from sklearn.model_selection import GroupShuffleSplit
import json


class SignalPreprocessor:
    """
    Signal preprocessing matching firmware implementation.

    Firmware Parameters (verified from leak_detector.ino):
    - SAMPLE_RATE_HZ: 4000
    - WINDOW_MS: 1000
    - DC_BLOCK_R: 0.995
    - ADC resolution: 12-bit
    """

    def __init__(
        self,
        sample_rate: int = 4000,
        window_duration_ms: int = 1000,
        dc_block_coeff: float = 0.995,
        adc_resolution: int = 12
    ):
        self.sample_rate = sample_rate
        self.window_samples = int(sample_rate * window_duration_ms / 1000)
        self.dc_block_coeff = dc_block_coeff
        self.adc_max = 2 ** adc_resolution - 1  # 4095 for 12-bit
        self.nyquist = sample_rate / 2  # 2000 Hz

    def dc_block_filter(self, signal: np.ndarray) -> np.ndarray:
        """
        First-order IIR DC-blocking filter matching firmware implementation.

        Firmware: leak_detector.ino lines 278-286
        y[n] = x[n] - x[n-1] + R * y[n-1]
        where R = DC_BLOCK_R = 0.995

        Args:
            signal: Input signal (ADC counts)

        Returns:
            DC-blocked signal
        """
        output = np.zeros_like(signal, dtype=np.float32)
        x1 = 0.0
        y1 = 0.0

        for i, x in enumerate(signal):
            y = x - x1 + self.dc_block_coeff * y1
            output[i] = y
            x1 = x
            y1 = y

        return output

    def compute_rms(self, signal: np.ndarray) -> float:
        """
        Compute RMS (Root Mean Square) of signal.

        Firmware: leak_detector.ino lines 448-457

        Args:
            signal: Input signal

        Returns:
            RMS value
        """
        return np.sqrt(np.mean(signal ** 2))

    def compute_std(self, signal: np.ndarray) -> float:
        """Compute standard deviation of signal."""
        return np.std(signal)

    def compute_peak_amplitude(self, signal: np.ndarray) -> float:
        """Compute peak amplitude (max absolute value)."""
        return np.max(np.abs(signal))

    def compute_crest_factor(self, signal: np.ndarray) -> float:
        """
        Compute crest factor (peak / RMS).

        Crest factor indicates the ratio of peak amplitude to RMS.
        High crest factor indicates impulsive signals.
        """
        rms = self.compute_rms(signal)
        peak = self.compute_peak_amplitude(signal)
        return peak / rms if rms > 1e-6 else 0.0

    def compute_zero_crossing_rate(self, signal: np.ndarray) -> float:
        """
        Compute zero-crossing rate.

        ZCR indicates the rate at which the signal changes sign.
        Higher ZCR indicates higher frequency content.
        """
        zero_crossings = np.sum(np.diff(np.sign(signal)) != 0)
        return zero_crossings / len(signal)

    def compute_band_energy(
        self,
        signal: np.ndarray,
        freq_low: float,
        freq_high: float
    ) -> float:
        """
        Compute energy in a frequency band using FFT.

        Note: Firmware Nyquist frequency is 2000 Hz (4000 Hz / 2).
        This function respects that constraint.

        Args:
            signal: Input signal
            freq_low: Lower frequency bound (Hz)
            freq_high: Upper frequency bound (Hz)

        Returns:
            Energy in the frequency band
        """
        # Validate frequency bounds
        if freq_low >= self.nyquist:
            return 0.0
        if freq_high > self.nyquist:
            freq_high = self.nyquist

        # Compute FFT
        fft = np.fft.fft(signal)
        fft_freq = np.fft.fftfreq(len(signal), 1.0 / self.sample_rate)

        # Get magnitude spectrum
        magnitude = np.abs(fft)

        # Extract energy in band
        mask = (np.abs(fft_freq) >= freq_low) & (np.abs(fft_freq) < freq_high)
        band_energy = np.sum(magnitude[mask] ** 2)

        return band_energy

    def extract_features(self, signal: np.ndarray) -> Dict[str, float]:
        """
        Extract comprehensive features from signal window.

        Features match signal characteristics usable at 4000 Hz sampling:
        - Time-domain: RMS, std, peak, crest factor, ZCR
        - Frequency-domain: Band energy below Nyquist (2000 Hz)

        Args:
            signal: Input signal (ADC counts, typically 4000 samples)

        Returns:
            Dictionary of feature names to values
        """
        # Apply DC-block filter (matching firmware)
        filtered = self.dc_block_filter(signal)

        # Time-domain features
        features = {
            'rms': self.compute_rms(filtered),
            'std': self.compute_std(filtered),
            'peak_amplitude': self.compute_peak_amplitude(filtered),
            'crest_factor': self.compute_crest_factor(filtered),
            'zero_crossing_rate': self.compute_zero_crossing_rate(filtered),
        }

        # Frequency-domain band energies (below Nyquist)
        # Low band: 0-500 Hz
        features['band_energy_0_500'] = self.compute_band_energy(filtered, 0, 500)

        # Mid band: 500-1000 Hz
        features['band_energy_500_1000'] = self.compute_band_energy(filtered, 500, 1000)

        # High band: 1000-2000 Hz (up to Nyquist)
        features['band_energy_1000_2000'] = self.compute_band_energy(filtered, 1000, 2000)

        # Total energy (all bands)
        features['total_energy'] = features['band_energy_0_500'] + \
                                    features['band_energy_500_1000'] + \
                                    features['band_energy_1000_2000']

        return features

    def process_dataset(
        self,
        manifest_path: Path,
        data_dir: Path,
        output_path: Path
    ) -> pd.DataFrame:
        """
        Process entire dataset and extract features.

        Args:
            manifest_path: Path to manifest CSV
            data_dir: Directory containing .npy data files
            output_path: Path to save features CSV

        Returns:
            DataFrame with features and labels
        """
        manifest = pd.read_csv(manifest_path)
        features_list = []

        print(f"Processing {len(manifest)} samples...")

        for idx, row in manifest.iterrows():
            # Load signal
            filepath = data_dir / row['filename']
            signal = np.load(filepath)

            # Extract features
            features = self.extract_features(signal)

            # Add metadata
            features['sample_id'] = row['sample_id']
            features['label'] = row['label']
            features['source_type'] = row['source_type']
            features['recording_id'] = row.get('recording_id', 'unknown')

            features_list.append(features)

            if (idx + 1) % 50 == 0:
                print(f"  Processed {idx + 1}/{len(manifest)} samples")

        features_df = pd.DataFrame(features_list)

        # Save features
        output_path.parent.mkdir(parents=True, exist_ok=True)
        features_df.to_csv(output_path, index=False)

        print(f"Features saved to: {output_path}")
        print(f"Feature shape: {features_df.shape}")

        return features_df


class DataSplitter:
    """
    Split dataset into train/validation/test sets with recording-level grouping.

    Prevents data leakage by ensuring samples from the same recording
    are not distributed across different splits.
    """

    def __init__(self, test_size: float = 0.2, val_size: float = 0.1):
        self.test_size = test_size
        self.val_size = val_size

    def split_by_recording(
        self,
        features_df: pd.DataFrame,
        group_column: str = 'recording_id',
        random_state: int = 42
    ) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
        """
        Split dataset by recording group to prevent data leakage.

        Args:
            features_df: DataFrame with features and labels
            group_column: Column to group by (e.g., 'recording_id')
            random_state: Random seed for reproducibility

        Returns:
            train_df, val_df, test_df
        """
        # Get unique groups
        groups = features_df[group_column].unique().tolist()
        np.random.seed(random_state)
        np.random.shuffle(groups)

        # Calculate split sizes
        n_groups = len(groups)
        n_test = int(n_groups * self.test_size)
        n_val = int(n_groups * self.val_size)
        n_train = n_groups - n_test - n_val

        # Split groups
        train_groups = groups[:n_train]
        val_groups = groups[n_train:n_train + n_val]
        test_groups = groups[n_train + n_val:]

        # Assign splits
        train_df = features_df[features_df[group_column].isin(train_groups)].copy()
        val_df = features_df[features_df[group_column].isin(val_groups)].copy()
        test_df = features_df[features_df[group_column].isin(test_groups)].copy()

        # Assign split labels
        train_df['split'] = 'train'
        val_df['split'] = 'val'
        test_df['split'] = 'test'

        print(f"\nData split by {group_column}:")
        print(f"  Train: {len(train_df)} samples ({len(train_groups)} groups)")
        print(f"  Val:   {len(val_df)} samples ({len(val_groups)} groups)")
        print(f"  Test:  {len(test_df)} samples ({len(test_groups)} groups)")

        # Report class distribution per split
        print("\nClass distribution per split:")
        for split_name, split_df in [('train', train_df), ('val', val_df), ('test', test_df)]:
            print(f"  {split_name}:")
            for label, count in split_df['label'].value_counts().items():
                print(f"    {label}: {count}")

        return train_df, val_df, test_df

    def update_manifest_with_splits(
        self,
        manifest_path: Path,
        train_df: pd.DataFrame,
        val_df: pd.DataFrame,
        test_df: pd.DataFrame
    ):
        """
        Update original manifest with split assignments.

        Args:
            manifest_path: Path to original manifest CSV
            train_df, val_df, test_df: Split DataFrames
        """
        manifest = pd.read_csv(manifest_path)

        # Create mapping from sample_id to split
        split_map = {}
        for df, split_name in [(train_df, 'train'), (val_df, 'val'), (test_df, 'test')]:
            for sample_id in df['sample_id']:
                split_map[sample_id] = split_name

        # Update manifest
        manifest['train_val_test'] = manifest['sample_id'].map(split_map)

        # Save updated manifest
        manifest.to_csv(manifest_path, index=False)
        print(f"\nUpdated manifest with split assignments: {manifest_path}")


def main():
    """Process synthetic dataset and extract features."""
    # Paths
    dataset_dir = Path(__file__).parent.parent / "data" / "synthetic"
    manifest_path = dataset_dir / "manifest.csv"
    data_dir = dataset_dir / "data"
    output_path = dataset_dir / "features.csv"

    # Initialize preprocessor
    preprocessor = SignalPreprocessor(
        sample_rate=4000,
        window_duration_ms=1000,
        dc_block_coeff=0.995
    )

    # Process dataset
    features_df = preprocessor.process_dataset(
        manifest_path=manifest_path,
        data_dir=data_dir,
        output_path=output_path
    )

    # Split data
    splitter = DataSplitter(test_size=0.2, val_size=0.1)
    train_df, val_df, test_df = splitter.split_by_recording(features_df)

    # Update manifest
    splitter.update_manifest_with_splits(manifest_path, train_df, val_df, test_df)

    # Save split features
    train_path = dataset_dir / "features_train.csv"
    val_path = dataset_dir / "features_val.csv"
    test_path = dataset_dir / "features_test.csv"

    train_df.to_csv(train_path, index=False)
    val_df.to_csv(val_path, index=False)
    test_df.to_csv(test_path, index=False)

    print(f"\nSplit features saved:")
    print(f"  Train: {train_path}")
    print(f"  Val:   {val_path}")
    print(f"  Test:  {test_path}")


if __name__ == "__main__":
    main()
