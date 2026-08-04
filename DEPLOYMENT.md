# Deployment Guide

This guide walks through standing up the Project000 lab environment.

## Prerequisites

- A Wazuh manager (VM or container) — see [Wazuh docs](https://documentation.wazuh.com/)
- At least one endpoint with the Wazuh agent installed (Windows or Linux)
- Atomic Red Team installed on the test endpoint(s)
- Git

## 1. Deploy the Wazuh Manager

Follow the official Wazuh quickstart to bring up manager + indexer + dashboard.

## 2. Apply Custom Configuration

Copy the config templates from `configs/` to your manager, replacing placeholders:

```bash
cp configs/local_rules.xml /var/ossec/etc/rules/
cp configs/ossec.conf.template /var/ossec/etc/ossec.conf
# Edit ossec.conf and fill in <AGENT_IP>, <API_KEY>, etc.
```

Restart the manager:

```bash
systemctl restart wazuh-manager
```

## 3. Load Detection Rules

Copy rule files from `rules/` into the manager's custom rules directory, then restart the manager to load them.

## 4. Install Atomic Red Team on the Test Endpoint

```powershell
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics
```

## 5. Run a Validation Test

```powershell
Invoke-AtomicTest T1059.001 -TestNumbers 1
```

Confirm the matching rule fires in the Wazuh dashboard, and log the result in `documentation/`.

## Teardown

Stop and remove the manager/agent VMs or containers, and revoke any API keys issued for the lab.
