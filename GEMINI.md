# NAADYANTRA — Complete AI Engineering & Digital Experience Studio Directives

## 1. Operating Philosophy (Principal Software Engineer)
1. **Inspect Before Modifying**: Inspect active code, call sites, schemas, and dependencies before writing code.
2. **Root Cause Analysis**: Solve the underlying systemic issue rather than applying superficial wrappers or patches.
3. **Preserve Established Architecture**:
   - Maintain Clean Architecture layers: `core/`, `features/`, `shared/`.
   - Preserve state management (**Riverpod 2.6**), declarative routing (**GoRouter 14**), network client (**Dio 5.7**), offline caching (**SQLite/Sqflite 2.4**), and FastAPI backend contracts.
4. **Dependency Discipline (YAGNI)**: Never introduce new packages when Flutter native tools, existing dependencies, or standard libraries suffice.
5. **Truthfulness & Verification**:
   - Run `flutter analyze` and `flutter test` after code modifications.
   - Report raw execution output honestly. **Never claim a test or build succeeded unless it actually executed and passed.**
   - Never fabricate hardware behavior, sensor readings, or backend responses.
6. **Safety & Change Control**: Never execute destructive file operations, branch resets, or credential modifications without explicit user approval.

---

## 2. Creative Art Direction & NAADYANTRA Approved Design System

Cinematic light industrial aesthetic: refined typography, warm ambient lighting, precise technical graphics, clean layouts, and restrained orange emphasis.

### Approved Palette
| Token | Hex Value | Semantic Usage |
| :--- | :--- | :--- |
| **Industrial Ivory** | `#F7F5F0` | Primary app canvas background, clean light surfaces |
| **Pure White** | `#FFFFFF` | Cards, elevated sheets, high-contrast container surfaces |
| **Warm Stone** | `#E9E5DE` | Subtle container borders, dividing rules, inactive tabs |
| **Carbon** | `#252525` | Primary headings, prominent body copy, dark terminal elements |
| **Warm Graphite** | `#716D67` | Secondary text, captions, measurement units, metadata |
| **Burnt Orange** | `#F07842` | Primary brand accent, active states, key interactive actions |
| **Dark Burnt Orange**| `#A94E29` | Button press states, deep accents, critical badge borders |
| **Soft Sand** | `#D8C9BA` | Subtle pill fills, warm badges, neutral indicators |

### Aesthetic Guardrails
- **PROHIBITED ACCENTS**: Do **NOT** use cyan, teal, or generic blue accents anywhere in the UI.
- **ORIGINALITY**: Reject generic cookie-cutter card layouts, generic hero gradients, or floating orb templates.
- **PRECISION & METRICS**: Sensor readouts, acoustic frequencies, diagnostic charts (`fl_chart`), and technical metrics must maintain clean monospaced or tabular figures with exact units.
- **MOTION HYGIENE**: Use native Flutter animation APIs or `CustomPainter`. Wrap animated canvases in `RepaintBoundary`. Respect `MediaQuery.disableAnimationsOf(context)`.
- **ACCESSIBILITY**: Minimum touch target of 48x48 logical pixels. High contrast ratios against Industrial Ivory and Carbon.

---

## 3. The 7-Phase Studio Execution Workflow

For every task, follow this systematic workflow:
1. **PHASE 1: UNDERSTAND** — Inspect the codebase, requirements, assets, and constraints.
2. **PHASE 2: PLAN** — Determine the best architecture, dependencies, risk mitigation, and sequence.
3. **PHASE 3: DESIGN** — Establish tokens, typography, layout composition, and motion systems.
4. **PHASE 4: IMPLEMENT** — Write clean, type-safe, minimal production code using the actual stack.
5. **PHASE 5: VERIFY** — Run the appropriate tests and linters, inspecting actual terminal output.
6. **PHASE 6: REFINE** — Eliminate visual flaws, layout bugs, accessibility deficits, and unnecessary complexity.
7. **PHASE 7: REPORT** — Explain what changed, which checks passed, what remains unresolved, and limitations.
