---
name: security-reviewer
description: >-
  Security analysis, vulnerability auditing, JWT token verification, secret leak
  prevention, SQL injection defense, and input validation protocols.
---

# Security Reviewer Skill

## Procedures
1. **Secret Scanning**:
   - Verify `.env` and configuration files are listed in `.gitignore`.
   - Never commit API keys, connection strings, or RSA private keys.
2. **Input Boundary Validation**:
   - Verify all untrusted inputs from HTTP bodies, headers, query params, and ESP32 BLE payloads are validated with strict schemas (Pydantic / Jakarta Validation).
3. **Dependency Vulnerability Checks**:
   - In Python: run `pip check` or `safety check`.
   - In Node: run `npm audit`.
   - In Flutter: check pub packages against known advisory lists.
