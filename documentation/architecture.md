# Architecture

## Components

- **Wazuh Manager** — central log ingestion, rule evaluation, alerting
- **Wazuh Agents** — deployed on lab endpoints (Windows/Linux), forward
  Sysmon/Windows Event Log / auditd data to the manager
- **Wazuh Indexer + Dashboard** — storage and visualization of alerts
- **Atomic Red Team** — runs on lab endpoints to simulate ATT&CK techniques

## Data Flow

```
Endpoint (Sysmon/Event Log)
      │
      ▼
 Wazuh Agent  ──(1514/tcp, encrypted)──►  Wazuh Manager
                                              │
                                    rules/local_rules.xml
                                              │
                                              ▼
                                   Wazuh Indexer + Dashboard
                                              │
                                              ▼
                                   Analyst triage (playbooks/)
```

## Rule Lifecycle

1. Identify a technique to detect (MITRE ATT&CK ID)
2. Write/adjust rule in `rules/`
3. Validate with matching atomic test in `atomic-red-team/`
4. Tune for false positives
5. Document behavior + triage steps in `playbooks/`

## Validation Log Index

| Rule ID | Technique | Atomic Test | Status |
|---------|-----------|--------------|--------|
| 100010  | T1059.001 | T1059.001-1  | Documented, pending live validation |
| 100011  | T1003     | _TBD_        | Rule drafted, no atomic mapped yet |
| 100012  | T1053.005 | _TBD_        | Rule drafted, no atomic mapped yet |
