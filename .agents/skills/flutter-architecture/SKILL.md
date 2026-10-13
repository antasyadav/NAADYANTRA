---
name: flutter-architecture
description: >-
  Standard Clean Architecture patterns, Riverpod state lifecycle, GoRouter navigation,
  and repository patterns tailored for Flutter applications.
---

# Flutter Architecture Best Practices

## Directory Structure
```
mobile_app/lib/
├── app/          # App initialization, main router configuration (GoRouter)
├── core/         # Core singletons: network (Dio), database (Sqflite), theme, constants
├── features/     # Feature vertical slices (auth, home, devices, sessions, inspection, etc.)
│   └── <feature>/
│       ├── screens/
│       ├── widgets/
│       └── providers/
└── shared/       # Cross-cutting data models, services, and reusable design widgets
```

## State Management with Riverpod 2.6
- Prefer code-generation or `Notifier` / `AsyncNotifier` patterns.
- Read providers inside `ConsumerWidget` or `ConsumerStatefulWidget` using `ref.watch` for reactive UI and `ref.read` in event callbacks.
- Separate UI from side effects: delegate async mutations to notifier methods.

## Data & Caching Strategy
- Network calls handled through `Dio` client in `core/network`.
- Local offline persistence handled through `sqflite` in `core/storage`.
- Secure tokens stored using `flutter_secure_storage`.
