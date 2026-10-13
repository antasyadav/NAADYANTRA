---
name: flutter-code-reviewer
description: >-
  Reviews Flutter and Dart code for architectural integrity, clean state management,
  Riverpod best practices, null safety, minimal complexity, and unnecessary dependencies.
---

# Flutter Code Reviewer

## Review Priorities
1. **Clean Architecture & Separation of Concerns**:
   - Ensure business logic is not written inside `build()` methods or UI widgets.
   - Verify Riverpod providers manage domain state and network interactions cleanly.
2. **Minimal Dependencies & YAGNI**:
   - Reject new package dependencies when existing dependencies (`dio`, `sqflite`, `flutter_riverpod`, `go_router`) or Flutter SDK primitives suffice.
3. **Null Safety & Robust Error Handling**:
   - Check null-aware operators and exhaustiveness of pattern matching / switch expressions.
   - Verify asynchronous futures are guarded by appropriate try/catch blocks and map exceptions to UI error banners.
4. **Dart Static Analysis Standards**:
   - Enforce `flutter_lints` standards: `use_super_parameters`, `prefer_const_constructors`, `avoid_print`.
5. **Memory & Performance**:
   - Ensure `TextEditingController`, `AnimationController`, and `StreamSubscription` objects are correctly disposed in `StatefulWidget` lifecycles or Riverpod `ref.onDispose`.
