# Contributing to Project000

Thanks for your interest in improving this detection engineering lab.

## Ground Rules

- Every new detection rule must map to a MITRE ATT&CK technique ID.
- Every new rule should be paired with (or reference) an Atomic Red Team test that validates it fires correctly.
- Keep configs generic — no real hostnames, IPs, credentials, or API keys. Use placeholders (`<AGENT_IP>`, `<API_KEY>`, etc.).
- One logical change per pull request (one new rule, one new playbook, one config fix).

## Adding a Detection Rule

1. Add the rule under `rules/` in the appropriate format (Wazuh XML, Sigma YAML, etc.)
2. Note the MITRE ATT&CK technique ID in a comment at the top of the rule
3. Link the atomic test used to validate it (add to `atomic-red-team/`)
4. Update `documentation/` with any tuning notes or false-positive considerations

## Adding a Playbook

1. Use the existing playbook template format in `playbooks/`
2. Include: trigger condition, triage steps, containment steps, escalation criteria

## Commit Messages

Use short, imperative commit messages, e.g.:
- `Add rule for suspicious PowerShell encoded command`
- `Fix false positive in T1059.001 detection`

## Pull Requests

- Describe what technique/scenario the change addresses
- Include test evidence (screenshot or log excerpt) where possible
