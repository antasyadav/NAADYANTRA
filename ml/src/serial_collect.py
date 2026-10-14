"""
Serial Data Collection Utility for HazGuard

Captures filtered piezo sensor samples from ESP32-S3 firmware in RUN_MODE_COLLECT mode.

Firmware Configuration (leak_detector.ino):
- Mode: RUN_MODE_COLLECT (set RUN_MODE = 1)
- Baud rate: 921600
- Output format: One ADC sample per line (decimal integer)
- Sampling rate: 4000 Hz
- Window duration: 1000 ms (4000 samples per window)

Usage:
1. Flash firmware with RUN_MODE = 1
2. Connect ESP32-S3 via USB
3. Run this script to capture data
4. Provide label and metadata for each recording
"""

import serial
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Optional, Dict
from datetime import datetime
import json
import sys


class SerialCollector:
    """Collect piezo sensor data from ESP32-S3 via serial."""

    def __init__(
        self,
        port: str,
        baud_rate: int = 921600,
        sample_rate: int = 4000,
        window_duration_ms: int = 1000
    ):
        self.port = port
        self.baud_rate = baud_rate
        self.sample_rate = sample_rate
        self.window_samples = int(sample_rate * window_duration_ms / 1000)
        self.serial_conn = None

    def connect(self) -> bool:
        """Open serial connection to ESP32-S3."""
        try:
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baud_rate,
                timeout=1.0
            )
            print(f"Connected to {self.port} at {self.baud_rate} baud")
            return True
        except serial.SerialException as e:
            print(f"Failed to connect to {self.port}: {e}")
            return False

    def disconnect(self):
        """Close serial connection."""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            print(f"Disconnected from {self.port}")

    def capture_window(self, timeout_ms: int = 2000) -> Optional[np.ndarray]:
        """
        Capture one window of samples.

        Args:
            timeout_ms: Maximum time to wait for complete window

        Returns:
            Array of ADC samples (int16), or None if timeout/error
        """
        if not self.serial_conn or not self.serial_conn.is_open:
            print("Error: Serial connection not open")
            return None

        samples = []
        start_time = datetime.now()

        while len(samples) < self.window_samples:
            # Check timeout
            elapsed = (datetime.now() - start_time).total_seconds() * 1000
            if elapsed > timeout_ms:
                print(f"Timeout: Only captured {len(samples)}/{self.window_samples} samples")
                return None

            # Read line
            try:
                line = self.serial_conn.readline().decode('utf-8').strip()
                if not line:
                    continue

                # Parse ADC value
                try:
                    value = int(line)
                    samples.append(value)
                except ValueError:
                    # Skip invalid lines
                    continue

            except UnicodeDecodeError:
                continue

        return np.array(samples, dtype=np.int16)

    def capture_recording(
        self,
        label: str,
        num_windows: int = 10,
        output_dir: Optional[Path] = None,
        metadata: Optional[Dict] = None
    ) -> Path:
        """
        Capture multiple windows as a recording.

        Args:
            label: Label for this recording (e.g., "normal", "leak", "noise")
            num_windows: Number of windows to capture
            output_dir: Directory to save recording
            metadata: Optional metadata dictionary

        Returns:
            Path to saved recording manifest
        """
        if output_dir is None:
            output_dir = Path(__file__).parent.parent / "data" / "raw"

        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        # Create recording ID
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        recording_id = f"{label}_{timestamp}"

        print(f"\n{'='*60}")
        print(f"Capturing Recording: {recording_id}")
        print(f"Label: {label}")
        print(f"Windows: {num_windows}")
        print(f"Samples per window: {self.window_samples}")
        print(f"{'='*60}\n")

        # Capture windows
        window_files = []
        for i in range(num_windows):
            print(f"Capturing window {i+1}/{num_windows}...", end=" ")

            samples = self.capture_window()

            if samples is None:
                print("FAILED")
                continue

            # Save window
            filename = f"{recording_id}_window_{i:03d}.npy"
            filepath = output_dir / filename
            np.save(filepath, samples)

            window_files.append(filename)
            print(f"OK (RMS: {np.sqrt(np.mean(samples**2)):.2f})")

        # Create manifest
        manifest = {
            "recording_id": recording_id,
            "label": label,
            "source_type": "real",
            "captured_at": datetime.utcnow().isoformat(),
            "device_port": self.port,
            "sample_rate": self.sample_rate,
            "window_duration_ms": 1000,
            "window_samples": self.window_samples,
            "num_windows": len(window_files),
            "window_files": window_files,
            "metadata": metadata or {}
        }

        # Save manifest
        manifest_path = output_dir / f"{recording_id}_manifest.json"
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)

        print(f"\nRecording saved: {manifest_path}")
        print(f"Captured {len(window_files)}/{num_windows} windows")

        return manifest_path


def list_available_ports():
    """List available serial ports."""
    import serial.tools.list_ports
    ports = serial.tools.list_ports.comports()
    print("\nAvailable serial ports:")
    for port in ports:
        print(f"  {port.device}: {port.description}")
    return [port.device for port in ports]


def interactive_session():
    """Run interactive collection session."""
    print("\n" + "="*60)
    print("HazGuard Serial Data Collection")
    print("="*60)

    # List ports
    available_ports = list_available_ports()

    if not available_ports:
        print("\nNo serial ports available. Connect ESP32-S3 and try again.")
        return

    # Select port
    port = input(f"\nEnter port (default: {available_ports[0]}): ").strip()
    if not port:
        port = available_ports[0]

    # Initialize collector
    collector = SerialCollector(port=port)

    # Connect
    if not collector.connect():
        return

    try:
        while True:
            print("\n" + "-"*60)
            print("Options:")
            print("  1. Capture recording")
            print("  2. Change label")
            print("  3. Change number of windows")
            print("  4. Quit")
            print("-"*60)

            choice = input("\nSelect option (1-4): ").strip()

            if choice == "1":
                # Capture recording
                label = input("Enter label (normal/leak/noise): ").strip()
                if not label:
                    print("Label required")
                    continue

                num_windows = input("Number of windows (default: 10): ").strip()
                try:
                    num_windows = int(num_windows) if num_windows else 10
                except ValueError:
                    print("Invalid number, using default 10")
                    num_windows = 10

                # Optional metadata
                notes = input("Notes (optional): ").strip()
                metadata = {"notes": notes} if notes else {}

                collector.capture_recording(
                    label=label,
                    num_windows=num_windows,
                    metadata=metadata
                )

            elif choice == "2":
                # Change label (handled in option 1)
                print("Label will be set when capturing")

            elif choice == "3":
                # Change windows (handled in option 1)
                print("Window count will be set when capturing")

            elif choice == "4":
                print("Exiting...")
                break

            else:
                print("Invalid option")

    finally:
        collector.disconnect()


def main():
    """Main entry point."""
    if len(sys.argv) > 1:
        # Command line mode
        port = sys.argv[1]
        label = sys.argv[2] if len(sys.argv) > 2 else "unknown"
        num_windows = int(sys.argv[3]) if len(sys.argv) > 3 else 10

        collector = SerialCollector(port=port)
        if collector.connect():
            collector.capture_recording(label=label, num_windows=num_windows)
            collector.disconnect()
    else:
        # Interactive mode
        interactive_session()


if __name__ == "__main__":
    main()
