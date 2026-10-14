"""
Dataset Inspection and Validation Tool

Inspects datasets, validates manifests, and reports statistics.
Used for understanding dataset composition, quality, and provenance.
"""

import pandas as pd
import numpy as np
from pathlib import Path
import json
from typing import Dict, List, Optional
import sys


class DatasetInspector:
    """Inspect and validate datasets with manifests."""

    def __init__(self, dataset_path: Path):
        self.dataset_path = Path(dataset_path)
        self.manifest_path = self.dataset_path / "manifest.csv"
        self.metadata_path = self.dataset_path / "metadata.json"
        self.data_dir = self.dataset_path / "data"

        self.manifest = None
        self.metadata = None

    def load_manifest(self) -> pd.DataFrame:
        """Load dataset manifest."""
        if not self.manifest_path.exists():
            raise FileNotFoundError(f"Manifest not found: {self.manifest_path}")

        self.manifest = pd.read_csv(self.manifest_path)
        print(f"Loaded manifest with {len(self.manifest)} records")
        return self.manifest

    def load_metadata(self) -> Dict:
        """Load dataset metadata."""
        if not self.metadata_path.exists():
            print(f"Warning: Metadata not found: {self.metadata_path}")
            return {}

        with open(self.metadata_path, 'r') as f:
            self.metadata = json.load(f)
        print(f"Loaded metadata: {self.metadata.get('dataset_name', 'unknown')}")
        return self.metadata

    def validate_manifest(self) -> Dict[str, List[str]]:
        """Validate manifest integrity and completeness."""
        issues = {
            "missing_files": [],
            "invalid_labels": [],
            "missing_fields": [],
            "invalid_sampling_rates": [],
            "duplicate_ids": []
        }

        if self.manifest is None:
            self.load_manifest()

        # Check for missing required fields
        required_fields = [
            "sample_id", "filename", "label", "source_type",
            "sampling_rate", "num_samples", "window_duration_ms"
        ]
        for field in required_fields:
            if field not in self.manifest.columns:
                issues["missing_fields"].append(field)

        # Check for duplicate sample IDs
        if "sample_id" in self.manifest.columns:
            duplicates = self.manifest[self.manifest.duplicated(subset=["sample_id"], keep=False)]
            if not duplicates.empty:
                issues["duplicate_ids"] = duplicates["sample_id"].tolist()

        # Check for invalid labels
        if "label" in self.manifest.columns:
            valid_labels = ["normal", "leak_like", "noise", "leak", "background"]
            invalid = self.manifest[~self.manifest["label"].isin(valid_labels)]
            if not invalid.empty:
                issues["invalid_labels"] = invalid["label"].unique().tolist()

        # Check for invalid sampling rates
        if "sampling_rate" in self.manifest.columns:
            invalid_sr = self.manifest[
                (self.manifest["sampling_rate"] < 1000) |
                (self.manifest["sampling_rate"] > 100000)
            ]
            if not invalid_sr.empty:
                issues["invalid_sampling_rates"] = invalid_sr["sampling_rate"].unique().tolist()

        # Check for missing data files
        if "filename" in self.manifest.columns and self.data_dir.exists():
            for filename in self.manifest["filename"]:
                filepath = self.data_dir / filename
                if not filepath.exists():
                    issues["missing_files"].append(filename)

        return issues

    def report_class_distribution(self):
        """Report class distribution and balance."""
        if self.manifest is None:
            self.load_manifest()

        if "label" not in self.manifest.columns:
            print("No 'label' column in manifest")
            return

        print("\n" + "="*60)
        print("CLASS DISTRIBUTION")
        print("="*60)

        label_counts = self.manifest["label"].value_counts()
        total = len(self.manifest)

        for label, count in label_counts.items():
            percentage = (count / total) * 100
            print(f"{label:20s}: {count:6d} ({percentage:5.1f}%)")

        print(f"\nTotal samples: {total}")

        # Check for imbalance
        max_count = label_counts.max()
        min_count = label_counts.min()
        imbalance_ratio = max_count / min_count if min_count > 0 else float('inf')

        if imbalance_ratio > 3:
            print(f"WARNING: Dataset is imbalanced (ratio: {imbalance_ratio:.1f}:1)")
        else:
            print(f"Dataset is reasonably balanced (ratio: {imbalance_ratio:.1f}:1)")

    def report_sampling_rates(self):
        """Report sampling rate statistics."""
        if self.manifest is None:
            self.load_manifest()

        if "sampling_rate" not in self.manifest.columns:
            print("No 'sampling_rate' column in manifest")
            return

        print("\n" + "="*60)
        print("SAMPLING RATE STATISTICS")
        print("="*60)

        sr_stats = self.manifest["sampling_rate"].describe()
        print(sr_stats)

        unique_sr = self.manifest["sampling_rate"].unique()
        print(f"\nUnique sampling rates: {unique_sr}")

        if len(unique_sr) > 1:
            print("WARNING: Multiple sampling rates detected - resampling may be required")

    def report_source_types(self):
        """Report data source types (real, public, synthetic)."""
        if self.manifest is None:
            self.load_manifest()

        if "source_type" not in self.manifest.columns:
            print("No 'source_type' column in manifest")
            return

        print("\n" + "="*60)
        print("SOURCE TYPE DISTRIBUTION")
        print("="*60)

        source_counts = self.manifest["source_type"].value_counts()
        for source, count in source_counts.items():
            print(f"{source:20s}: {count:6d}")

        if "synthetic" in source_counts.index:
            print("\nNOTE: Dataset contains synthetic data.")
            print("Synthetic data is for pipeline development only.")
            print("Do not use synthetic-only results as evidence of real-world performance.")

    def report_train_val_test_split(self):
        """Report train/validation/test split status."""
        if self.manifest is None:
            self.load_manifest()

        if "train_val_test" not in self.manifest.columns:
            print("\nNo train/validation/test split assigned yet.")
            return

        print("\n" + "="*60)
        print("TRAIN/VALIDATION/TEST SPLIT")
        print("="*60)

        split_counts = self.manifest["train_val_test"].value_counts()
        for split, count in split_counts.items():
            print(f"{split:20s}: {count:6d}")

        unassigned = (self.manifest["train_val_test"] == "unassigned").sum()
        if unassigned > 0:
            print(f"\nWARNING: {unassigned} samples are unassigned to split")

    def validate_data_files(self, sample_size: int = 10):
        """Validate a sample of data files for integrity."""
        if not self.data_dir.exists():
            print(f"Data directory not found: {self.data_dir}")
            return

        print("\n" + "="*60)
        print("DATA FILE VALIDATION (sample)")
        print("="*60)

        if self.manifest is None:
            self.load_manifest()

        # Sample a few files to validate
        sample_files = self.manifest["filename"].sample(min(sample_size, len(self.manifest)))

        valid_count = 0
        invalid_count = 0

        for filename in sample_files:
            filepath = self.data_dir / filename
            try:
                data = np.load(filepath)
                print(f"[OK] {filename}: shape={data.shape}, dtype={data.dtype}")
                valid_count += 1
            except Exception as e:
                print(f"[FAIL] {filename}: ERROR - {e}")
                invalid_count += 1

        print(f"\nValid: {valid_count}, Invalid: {invalid_count}")

    def full_report(self):
        """Generate comprehensive inspection report."""
        print("\n" + "="*60)
        print("DATASET INSPECTION REPORT")
        print("="*60)
        print(f"Dataset path: {self.dataset_path}")

        # Load metadata
        self.load_metadata()
        if self.metadata:
            print(f"Dataset name: {self.metadata.get('dataset_name', 'unknown')}")
            print(f"Source type: {self.metadata.get('source_type', 'unknown')}")
            print(f"Generated at: {self.metadata.get('generated_at', 'unknown')}")

        # Load and validate manifest
        self.load_manifest()
        issues = self.validate_manifest()

        # Report issues
        if any(issues.values()):
            print("\n" + "="*60)
            print("VALIDATION ISSUES")
            print("="*60)
            for issue_type, issue_list in issues.items():
                if issue_list:
                    print(f"\n{issue_type}:")
                    for item in issue_list[:10]:  # Limit to first 10
                        print(f"  - {item}")
                    if len(issue_list) > 10:
                        print(f"  ... and {len(issue_list) - 10} more")
        else:
            print("\n[OK] No validation issues found")

        # Generate detailed reports
        self.report_class_distribution()
        self.report_sampling_rates()
        self.report_source_types()
        self.report_train_val_test_split()
        self.validate_data_files()

        print("\n" + "="*60)
        print("INSPECTION COMPLETE")
        print("="*60)


def main():
    """Run dataset inspection."""
    if len(sys.argv) < 2:
        print("Usage: python inspect_dataset.py <dataset_path>")
        print("Example: python inspect_dataset.py ml/data/synthetic")
        sys.exit(1)

    dataset_path = Path(sys.argv[1])

    inspector = DatasetInspector(dataset_path)
    inspector.full_report()


if __name__ == "__main__":
    main()
