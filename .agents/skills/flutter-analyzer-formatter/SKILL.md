---
name: flutter-analyzer-formatter
description: >-
  Standardized instructions for Dart static analysis, automated lint fixing,
  and formatting compliance using flutter analyze and dart format.
---

# Dart Static Analysis and Formatting

## Workflows
1. **Format All Files**:
   ```powershell
   dart format lib test
   ```
2. **Run Static Analysis**:
   ```powershell
   flutter analyze
   ```
3. **Automated Fixes**:
   ```powershell
   dart fix --apply
   ```

## Common Lint Resolutions
- `use_super_parameters`: Use `super.key` and `super.parameter` constructors instead of manually passing to `super(key: key)`.
- `prefer_const_constructors`: Prepend `const` to widgets with immutable arguments to reduce unnecessary widget rebuilds.
- `avoid_print`: Use logger services or `debugPrint()` instead of naked `print()`.
