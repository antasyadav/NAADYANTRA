---
name: backend-engineer
description: >-
  Backend engineering specialist for FastAPI, Spring Boot 3, REST API architecture,
  SQLAlchemy/JPA data persistence, database migrations, and JWT authentication.
---

# Backend Engineer Skill

## Procedures
1. **FastAPI Development**:
   - Model definitions in `backend/schemas.py`.
   - Router registration in `backend/routers/`.
   - Database operations wrapped in dependency-injected sessions (`get_db`).
2. **Spring Boot 3 Development**:
   - Use Java 17 features: Records for immutable DTOs, pattern matching, sealed classes.
   - Secure REST controllers with `@PreAuthorize` and standard Spring Security filters.
3. **Database Migrations**:
   - For Alembic: generate migrations using `alembic revision --autogenerate -m "description"`, inspect generated code, then apply via `alembic upgrade head`.
