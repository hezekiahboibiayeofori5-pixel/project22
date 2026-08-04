# Project000

Detection engineering home lab: Wazuh custom rules, adversary emulation with Atomic Red Team, and incident-response playbooks, built around a small SOC test environment.

## Overview

Project000 is a self-contained detection engineering repository. It pairs custom SIEM detection logic with repeatable attack simulations so that every rule can be validated against a real (simulated) technique instead of theory alone.

```
Project000/
├── atomic-red-team/   # Atomic test mappings & execution notes (MITRE ATT&CK)
├── configs/           # Wazuh / agent / ingestion configuration
├── documentation/      # Architecture notes, data flow diagrams, ADRs
├── playbooks/          # Incident response runbooks
├── rules/              # Custom detection rules (local_rules.xml, Sigma, etc.)
├── scripts/             # Helper scripts (deployment, testing, log replay)
├── CONTRIBUTING.md
├── DEPLOYMENT.md
├── LICENSE
└── README.md
```

## Goals

- Build and tune detections against known-good adversary simulation (Atomic Red Team)
- Map every rule to a MITRE ATT&CK technique ID
- Keep detection logic version-controlled and peer-reviewable
- Document deployment steps so the lab is reproducible from scratch

## Getting Started

1. Clone the repo
2. Follow [DEPLOYMENT.md](DEPLOYMENT.md) to stand up the lab
3. Deploy rules from `rules/` to your SIEM/agent config
4. Run an atomic test from `atomic-red-team/` against a lab host
5. Confirm the corresponding rule fires, then log results in `documentation/`

## Tech Stack

- **Wazuh** — host-based detection / log analysis
- **Atomic Red Team** — adversary emulation mapped to MITRE ATT&CK
- **Sigma** — vendor-agnostic detection rule format

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Released under the [MIT License](LICENSE).
