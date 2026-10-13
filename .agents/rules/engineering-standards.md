# Flutter & Backend Engineering Standards

## Flutter & Dart Standards
1. **Directory Boundaries**:
   - `core/`: Application-wide themes, constants, networking client (`dio`), database helper (`sqflite`), storage keys, and error types.
   - `features/<feature>/`: Feature isolation containing `screens/` and optional `widgets/` or `providers/`.
   - `shared/`: Cross-feature reusable widgets, domain models, and utility services.
2. **State Management**:
   - Use `flutter_riverpod` providers (e.g. `NotifierProvider`, `AsyncNotifierProvider`, or `StateNotifierProvider`).
   - Keep UI widgets free from direct business or data fetching logic.
3. **Networking & Serialization**:
   - Use `Dio` instance provided through network service.
   - Use `json_annotation` / `json_serializable` for model serialization.
4. **Code Quality**:
   - Run `dart format` on any modified file.
   - Run `flutter analyze` and resolve all warnings and lints (`use_super_parameters`, `prefer_const_constructors`, etc.).
   - Write or update tests in `mobile_app/test/` to cover new features or fixes.
   - Verify with `flutter test`.

## Backend Standards (FastAPI & SQLAlchemy)
1. **API Contracts**: Check `backend/schemas.py` and `backend/routers/` before updating frontend models.
2. **Database Integrity**: Respect SQLite constraints and Alembic migrations.
3. **Authentication**: Maintain JWT Bearer token headers via secure storage.
