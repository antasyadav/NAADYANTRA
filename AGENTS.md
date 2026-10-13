# NAADYANTRA — Studio Workspace Directives for Autonomous & Pair Agents

Refer to [GEMINI.md](file:///d:/NAADYANTRA/GEMINI.md) for full context and visual tokens.

## Directives Summary
1. **Inspection First**: Always view existing code before refactoring or extending.
2. **Architecture Retention**:
   - Flutter 3.47+ / Dart 3.13+
   - Riverpod (`flutter_riverpod`) for reactive state.
   - GoRouter for declarative routing.
   - Dio for API requests.
   - Sqflite for local offline-first persistent caching.
   - FastAPI for backend contract compliance.
3. **NAADYANTRA Visual Identity**:
   - Palette: Industrial Ivory (`#F7F5F0`), Pure White (`#FFFFFF`), Warm Stone (`#E9E5DE`), Carbon (`#252525`), Warm Graphite (`#716D67`), Burnt Orange (`#F07842`), Dark Burnt Orange (`#A94E29`), Soft Sand (`#D8C9BA`).
   - Strictly avoid cyan, teal, or generic blue.
   - Cinematic light industrial aesthetic with restrained orange accents.
4. **Validation & Truthfulness**:
   - Always run `flutter analyze` and `flutter test` in `mobile_app` after modifying Dart files.
   - Report raw execution output honestly.
   - Never simulate or fabricate hardware sensor behavior or backend responses.
5. **Execution Workflow**: Follow the 7-Phase Studio Lifecycle (Understand → Plan → Design → Implement → Verify → Refine → Report).
