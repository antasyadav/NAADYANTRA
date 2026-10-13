# Safety, Security, and Verification Directives

## Grounding & Non-Fabrication
1. **Never Fabricate Hardware Behavior**: Do not invent ESP32 sensor responses, acoustic signal values, serial protocols, or false telemetry.
2. **Never Fabricate Test or Build Success**: Only report that tests or builds succeeded if the tool command was executed and produced an exit code of 0.
3. **Report Execution Details**: Always provide genuine command outputs and failure traces when errors arise.

## Safe File Operations
1. **Never Delete Working Code Without Backup**: Keep edits targeted.
2. **Respect Git Status**: Never execute `git reset --hard` or unstage uncommitted changes without explicit approval.
3. **No Secret Exposure**: Do not hardcode API keys, passwords, or credentials into repository files or commits.
