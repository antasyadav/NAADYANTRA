"""
Synthetic Acoustic Data Generator for HazGuard

Generates synthetic piezo sensor signals for preliminary pipeline development.
IMPORTANT: These signals are APPROXIMATIONS for pipeline development only.
They are NOT validated real-world leak signatures and must not be used
as evidence of real-world detection performance.

Classes:
- normal: Background noise, ambient conditions
- leak_like: Periodic high-frequency components simulating leak signatures
- noise: High-noise environments (machinery, interference)

Note: Firmware sampling rate is 4000 Hz, Nyquist frequency is 2000 Hz.
This generator respects these constraints and does not generate >2000 Hz content.
"""

import numpy as np
import pandas as pd
from pathlib import Path
from typing import Dict, List, Tuple
import json
from datetime import datetime


class SyntheticSignalGenerator:
    """
    Generates synthetic piezo sensor signals matching firmware constraints.

    Firmware Parameters (verified from leak_detector.ino):
    - Sampling rate: 4000 Hz
    - Window duration: 1000 ms (4000 samples)
    - ADC resolution: 12-bit (0-4095)
    - DC-block filter: First-order IIR with coefficient 0.995
    - Nyquist frequency: 2000 Hz
    """

    def __init__(
        self,
        sample_rate: int = 4000,
        window_duration_ms: int = 1000,
        adc_resolution: int = 12,
        dc_block_coeff: float = 0.995,
        random_seed: int = 42
    ):
        self.sample_rate = sample_rate
        self.window_samples = int(sample_rate * window_duration_ms / 1000)
        self.adc_max = 2 ** adc_resolution - 1  # 4095 for 12-bit
        self.dc_block_coeff = dc_block_coeff
        self.nyquist = sample_rate / 2  # 2000 Hz

        np.random.seed(random_seed)

    def dc_block_filter(self, signal: np.ndarray) -> np.ndarray:
        """
        First-order IIR DC-blocking filter matching firmware implementation.

        Firmware: leak_detector.ino lines 278-286
        y[n] = x[n] - x[n-1] + R * y[n-1]
        where R = DC_BLOCK_R = 0.995
        """
        output = np.zeros_like(signal)
        x1 = 0.0
        y1 = 0.0

        for i, x in enumerate(signal):
            y = x - x1 + self.dc_block_coeff * y1
            output[i] = y
            x1 = x
            y1 = y

        return output

    def quantize_to_adc(self, signal: np.ndarray) -> np.ndarray:
        """
        Quantize floating-point signal to 12-bit ADC range (0-4095).
        Simulates ADC quantization noise.
        """
        # Center around 2048 (virtual ground at 1.65V)
        centered = signal + 2048
        quantized = np.clip(centered, 0, self.adc_max)
        return quantized.astype(np.int16)

    def generate_normal(
        self,
        duration_ms: int = 1000,
        noise_amplitude: float = 5.0,
        low_freq_amplitude: float = 2.0
    ) -> np.ndarray:
        """
        Generate normal background noise signal.

        Simulates ambient conditions with:
        - Low-frequency drift (< 10 Hz)
        - Broadband noise
        - Occasional minor transients
        """
        samples = int(self.sample_rate * duration_ms / 1000)
        t = np.linspace(0, duration_ms / 1000, samples)

        # Low-frequency drift (simulating thermal drift, background)
        drift = low_freq_amplitude * np.sin(2 * np.pi * 2 * t)

        # Broadband noise
        noise = noise_amplitude * np.random.randn(samples)

        # Minor high-frequency content (normal environmental sounds)
        # Limited to < 500 Hz for normal conditions
        hf = 0.5 * np.sin(2 * np.pi * 50 * t) * np.random.randn(samples)

        signal = drift + noise + hf

        return self.quantize_to_adc(self.dc_block_filter(signal))

    def generate_leak_like(
        self,
        duration_ms: int = 1000,
        base_amplitude: float = 8.0,
        leak_amplitude: float = 15.0,
        leak_freq: float = 800.0,
        noise_amplitude: float = 5.0
    ) -> np.ndarray:
        """
        Generate leak-like signal with periodic high-frequency components.

        SIMULATION APPROXIMATION:
        Real pipe leaks produce complex ultrasonic signatures that are
        downconverted by the piezo sensor. This simulation uses simplified
        periodic components within the Nyquist bandwidth (0-2000 Hz).

        Do NOT treat this as a validated leak signature.
        """
        samples = int(self.sample_rate * duration_ms / 1000)
        t = np.linspace(0, duration_ms / 1000, samples)

        # Base noise floor
        base_noise = noise_amplitude * np.random.randn(samples)

        # Periodic leak signature (simplified approximation)
        # Real leaks have complex harmonics; this is a simplified model
        leak_sig = leak_amplitude * np.sin(2 * np.pi * leak_freq * t)

        # Add harmonics (simulating complex signature)
        if leak_freq * 2 < self.nyquist:
            leak_sig += (leak_amplitude * 0.5) * np.sin(2 * np.pi * leak_freq * 2 * t)
        if leak_freq * 3 < self.nyquist:
            leak_sig += (leak_amplitude * 0.3) * np.sin(2 * np.pi * leak_freq * 3 * t)

        # Amplitude modulation (simulating varying leak intensity)
        modulation = 0.8 + 0.2 * np.sin(2 * np.pi * 2 * t)
        leak_sig *= modulation

        signal = base_noise + leak_sig

        return self.quantize_to_adc(self.dc_block_filter(signal))

    def generate_noise(
        self,
        duration_ms: int = 1000,
        noise_amplitude: float = 20.0,
        interference_freq: float = 120.0,
        interference_amplitude: float = 10.0
    ) -> np.ndarray:
        """
        Generate high-noise environment signal.

        Simulates:
        - High background noise
        - Periodic interference (machinery, electrical)
        - Impulsive transients
        """
        samples = int(self.sample_rate * duration_ms / 1000)
        t = np.linspace(0, duration_ms / 1000, samples)

        # High-amplitude broadband noise
        noise = noise_amplitude * np.random.randn(samples)

        # Periodic interference (e.g., 60 Hz mains harmonics)
        interference = interference_amplitude * np.sin(2 * np.pi * interference_freq * t)

        # Occasional impulsive transients
        impulses = np.zeros(samples)
        num_impulses = np.random.poisson(5)
        for _ in range(num_impulses):
            idx = np.random.randint(0, samples)
            width = np.random.randint(10, 50)
            impulses[idx:idx+width] += np.random.randn(min(width, samples-idx)) * 30

        signal = noise + interference + impulses

        return self.quantize_to_adc(self.dc_block_filter(signal))

    def generate_dataset(
        self,
        class_counts: Dict[str, int],
        output_dir: Path,
        samples_per_recording: int = 20,
        dataset_name: str = "synthetic_dataset_v1"
    ) -> Tuple[pd.DataFrame, Path]:
        """
        Generate a complete synthetic dataset with manifest.

        Args:
            class_counts: Dict mapping class names to number of samples
                         e.g., {"normal": 100, "leak_like": 50, "noise": 50}
            output_dir: Directory to save dataset
            samples_per_recording: Number of samples per recording group
            dataset_name: Name for this dataset

        Returns:
            manifest_df: DataFrame with dataset metadata
            manifest_path: Path to saved manifest CSV
        """
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        data_dir = output_dir / "data"
        data_dir.mkdir(exist_ok=True)

        manifest_records = []
        sample_id = 0

        for class_name, count in class_counts.items():
            print(f"Generating {count} samples for class '{class_name}'...")

            # Calculate number of recording groups for this class
            num_recordings = max(1, count // samples_per_recording)

            for i in range(count):
                # Determine recording group
                recording_idx = i // samples_per_recording
                recording_id = f"synthetic_{class_name}_rec{recording_idx:03d}"

                # Generate signal based on class
                if class_name == "normal":
                    signal = self.generate_normal()
                elif class_name == "leak_like":
                    # Vary leak frequency slightly for diversity
                    freq = np.random.uniform(600, 1000)
                    signal = self.generate_leak_like(leak_freq=freq)
                elif class_name == "noise":
                    # Vary interference frequency
                    freq = np.random.uniform(50, 200)
                    signal = self.generate_noise(interference_freq=freq)
                else:
                    raise ValueError(f"Unknown class: {class_name}")

                # Save signal
                filename = f"{class_name}_{sample_id:06d}.npy"
                filepath = data_dir / filename
                np.save(filepath, signal)

                # Record metadata
                record = {
                    "sample_id": sample_id,
                    "filename": filename,
                    "label": class_name,
                    "source_type": "synthetic",
                    "sampling_rate": self.sample_rate,
                    "num_samples": len(signal),
                    "window_duration_ms": 1000,
                    "device_metadata": json.dumps({"simulated": True}),
                    "recording_id": recording_id,
                    "processing_version": "1.0",
                    "train_val_test": "unassigned",
                    "generated_at": datetime.utcnow().isoformat()
                }
                manifest_records.append(record)
                sample_id += 1

        # Create manifest DataFrame
        manifest_df = pd.DataFrame(manifest_records)

        # Save manifest
        manifest_path = output_dir / "manifest.csv"
        manifest_df.to_csv(manifest_path, index=False)

        # Save dataset metadata
        metadata = {
            "dataset_name": dataset_name,
            "source_type": "synthetic",
            "generated_at": datetime.utcnow().isoformat(),
            "total_samples": sample_id,
            "class_counts": class_counts,
            "sampling_rate": self.sample_rate,
            "window_duration_ms": 1000,
            "adc_resolution": 12,
            "nyquist_frequency": self.nyquist,
            "note": "This is synthetic data for pipeline development only. "
                   "It is NOT validated real-world leak signatures."
        }

        metadata_path = output_dir / "metadata.json"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f, indent=2)

        print(f"\nDataset generated: {sample_id} samples")
        print(f"Manifest saved to: {manifest_path}")
        print(f"Data saved to: {data_dir}")

        return manifest_df, manifest_path


def main():
    """Generate synthetic dataset for initial pipeline development."""
    output_dir = Path(__file__).parent.parent / "data" / "synthetic"

    generator = SyntheticSignalGenerator(
        sample_rate=4000,
        window_duration_ms=1000,
        random_seed=42
    )

    # Generate balanced dataset
    class_counts = {
        "normal": 200,
        "leak_like": 200,
        "noise": 100
    }

    manifest_df, manifest_path = generator.generate_dataset(
        class_counts=class_counts,
        output_dir=output_dir,
        dataset_name="naadyantra_synthetic_v1"
    )

    print("\nDataset summary:")
    print(manifest_df.groupby('label').size())


if __name__ == "__main__":
    main()
