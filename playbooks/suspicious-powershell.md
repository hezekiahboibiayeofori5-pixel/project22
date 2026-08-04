# Playbook: Suspicious PowerShell Execution

**Maps to rule:** `100010` (rules/local_rules.xml)
**MITRE ATT&CK:** T1059.001 — Command and Scripting Interpreter: PowerShell

## Trigger

Alert fires when an encoded (`-enc`/`-EncodedCommand`) or obfuscated
(`IEX`, `Invoke-Expression`, `FromBase64String`) PowerShell command line is
observed on a monitored endpoint.

## Triage

1. Pull the full command line and parent process from the Wazuh alert.
2. Decode any Base64 payload to inspect the actual command being run.
3. Check the parent process — is this a user-initiated action, a scheduled
   task, or a spawned child of an unusual process (e.g. `winword.exe`,
   `outlook.exe`)?
4. Check the logged-on user and whether this matches expected behavior for
   that account/role.

## Containment (if malicious)

1. Isolate the host from the network (Wazuh active response or manual).
2. Kill the offending PowerShell process.
3. Collect a memory/process snapshot if tooling allows.
4. Identify and remove any dropped persistence (scheduled tasks, run keys).

## Escalation Criteria

- Escalate to IR lead if the decoded command references credential
  dumping tools, C2 domains/IPs, or lateral movement (e.g. `psexec`,
  `wmic`, `Invoke-Command` against other hosts).
- Escalate immediately if this endpoint holds privileged/admin access.

## Closure

- Document root cause in `documentation/`.
- If false positive, note the legitimate use case and consider a rule
  exception rather than disabling the rule outright.
