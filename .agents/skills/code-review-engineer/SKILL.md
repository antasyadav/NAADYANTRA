---
name: code-review-engineer
description: >-
  Comprehensive code review engineer evaluating correctness, edge cases, caller impact,
  null safety, test coverage, code bloat, and YAGNI compliance.
---

# Code Review Engineer Skill

## Review Checklist
1. **Correctness**: Does the change completely solve the problem without breaking existing features?
2. **Safety**: Are inputs validated at system boundaries? Are error states handled gracefully?
3. **Lean Architecture**: Is this the smallest change that fully works? Can redundant helpers be removed?
4. **Testing**: Does any non-trivial logic include a corresponding test?
5. **Technical Debt**: If a shortcut was taken, is it formatted as `shortcut: <the limit>, <when to upgrade>`?
