---
name: flutter-diagnostics
description: >-
  Procedures for Flutter runtime debugging, DevTools inspection, layout overflow
  diagnostics, and memory leak analysis.
---

# Flutter Runtime Debugging & Diagnostics

## Tooling
- **Dart Tooling Daemon (DTD)**: Connects running VM instances for hot reload, widget inspector, and app log retrieval.
- **Flutter DevTools**:
  ```powershell
  flutter run -d chrome # or attached device
  ```

## Layout Overflow Debugging
1. **Yellow and Black Striped Overflow Box**:
   - Inspect the render box constraints: find the unbounded ancestor (`Column`, `Row`, `ListView`).
   - Fix using `Expanded` inside flex containers, or wrap with `SingleChildScrollView`.
2. **Repaint Boundaries & Performance**:
   - Wrap animated or frequently updating widgets (like acoustic signal waveforms) in `RepaintBoundary` to prevent cascading repaints across parent scaffolds.
