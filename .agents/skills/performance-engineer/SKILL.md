---
name: performance-engineer
description: >-
  Performance engineering specialist for Flutter frame profiling, repaint boundary
  isolation, Web 60fps frame budgeting, database query optimization, and memory leak elimination.
---

# Performance Engineer Skill

## Procedures
1. **Flutter Profiling**:
   - Inspect rebuild scope using Flutter DevTools.
   - Guard high-throughput streams (e.g. sensor charts) so only the specific visual node repaints.
2. **Web Frame Budgeting**:
   - Limit animation frame tasks to < 16ms (for 60fps) or < 8ms (for 120fps).
   - Offload complex computations to Web Workers where applicable.
3. **Database Performance**:
   - Run `EXPLAIN QUERY PLAN` on heavy SQL queries in SQLite or PostgreSQL.
   - Add targeted indexes on foreign keys and filter columns.
