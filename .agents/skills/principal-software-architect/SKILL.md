---
name: principal-software-architect
description: >-
  Principal software architect guidance for system boundaries, technical trade-offs,
  dependency governance, and architectural integrity across mobile, backend, and web systems.
---

# Principal Software Architect Skill

## Procedures
1. **Architecture Discovery**:
   - Trace the end-to-end data flow: Client UI -> Network Client -> Backend Router/Controller -> Service Layer -> Database / Firmware.
   - Map existing contracts, interfaces, and state stores before proposing changes.
2. **Dependency Discipline**:
   - Check if an existing package or language standard library already solves the problem.
   - Enforce YAGNI: reject speculative abstractions and "future-proofing" wrappers.
3. **Execution Guardrails**:
   - Plan every major refactor in advance.
   - Preserve existing working functionality and API contracts.
