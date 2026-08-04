# Blue Team SIEM & EDR Detection Lab — Complete Project Documentation

A cloud-native security monitoring lab built from scratch on AWS using Wazuh SIEM, Sysmon EDR telemetry, auditd, and custom detection rules mapped to MITRE ATT&CK. Built by a beginner, step by step, with real attack simulations and real detections.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Wazuh SIEM Installation](#wazuh-siem-installation)
4. [Endpoint Configuration](#endpoint-configuration)
5. [Sysmon Installation](#sysmon-installation)
6. [Auditd Configuration (Linux)](#auditd-configuration-linux)
7. [Custom Detection Rules](#custom-detection-rules)
8. [Attack Simulations](#attack-simulations)
9. [Detection Results](#detection-results)
10. [Detection Playbook](#detection-playbook)
11. [SOC Dashboard](#soc-dashboard)
12. [Repository Structure](#repository-structure)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│                                                             │
│  ┌─────────────────┐    ┌──────────────────┐               │
│  │  Wazuh Manager   │    │ Windows Server    │               │
│  │  (t3.micro)      │    │ Endpoint          │               │
│  │  Ubuntu 22.04    │◄───│ (t3.micro)        │               │
│  │  18.188.181.90   │    │ Windows 2022      │               │
│  │                  │    └──────────────────┘               │
│  │  - Wazuh Manager │    ┌──────────────────┐               │
│  │  - Wazuh Indexer │◄───│ Ubuntu Endpoint   │               │
│  │  - Dashboard     │    │ (t2.micro)        │               │
│  └────────┬─────────┘    │ Ubuntu 26.04      │               │
│           │              └──────────────────┘               │
└───────────┼─────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────┐
│  Windows Laptop      │
│  (Local Machine)     │
│  Wazuh Agent         │
│  + Sysmon            │
└─────────────────────┘
```

### Stack
| Component | Technology | Purpose |
|---|---|---|
| SIEM | Wazuh 4.7.5 | Central log collection, alerting, dashboards |
| EDR (Windows) | Sysmon v15.21 | Process, network, file telemetry |
| EDR (Linux) | auditd 4.1.2 | Command execution, file change monitoring |
| Attack Simulation | Atomic Red Team | Safe adversary technique simulation |
| Cloud | AWS EC2 | Hosting SIEM and endpoints |
| Detection Rules | Custom Wazuh XML | Original rules mapped to MITRE ATT&CK |

---

## Infrastructure Setup

### AWS EC2 Instances

| Instance | Type | OS | Role | IP |
|---|---|---|---|---|
| wazuh-manager | t3.micro | Ubuntu 22.04 | SIEM Manager | 18.188.181.90 |
| windows-endpoint | t3.micro | Windows Server 2022 | Monitored Endpoint | Dynamic |
| ubuntu-endpoint | t2.micro | Ubuntu 26.04 | Monitored Endpoint | 3.19.228.197 |
| windows-laptop | Local | Windows 10/11 | Monitored Endpoint | Local |

### Security Group Rules (Wazuh Manager)
| Port | Protocol | Purpose |
|---|---|---|
| 22 | TCP | SSH access |
| 443 | TCP | Wazuh Dashboard (HTTPS) |
| 1514 | TCP | Agent communication |
| 1515 | TCP | Agent enrollment |

---

## Wazuh SIEM Installation

### Prerequisites — Add Swap Space (for t3.micro with 1GB RAM)
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h  # Verify: Swap shows 2.0Gi
```

### Install Wazuh (All-in-One)
```bash
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh && sudo bash wazuh-install.sh -a -i
```

The `-i` flag bypasses the hardware requirement check (needed for free tier).

Installation takes 10-15 minutes. At the end it prints:
```
INFO: --- Summary ---
INFO: You can access the web interface https://<IP>:443
    User: admin
    Password: <generated-password>
```

**Save this password — it cannot be recovered.**

### Access Dashboard
```
URL:      https://18.188.181.90
Username: admin
Password: <your-generated-password>
```

Accept the self-signed certificate warning in your browser.

---

## Endpoint Configuration

### Windows Endpoint — Wazuh Agent Installation

Run in PowerShell (Administrator):
```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.5-1.msi -OutFile ${env:tmp}\wazuh-agent; msiexec.exe /i ${env:tmp}\wazuh-agent /q WAZUH_MANAGER='18.188.181.90' WAZUH_AGENT_NAME='windows-laptop' WAZUH_REGISTRATION_SERVER='18.188.181.90'
```

Start the agent:
```powershell
NET START WazuhSvc
```

Verify connection:
```powershell
Get-Service WazuhSvc
```

### Ubuntu Endpoint — Wazuh Agent Installation

```bash
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.5-1_amd64.deb && sudo WAZUH_MANAGER='18.188.181.90' WAZUH_AGENT_NAME='ubuntu-endpoint' dpkg -i ./wazuh-agent_4.7.5-1_amd64.deb

sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

---

## Sysmon Installation

Sysmon provides deep Windows telemetry: process creation, network connections, file creation, registry changes.

### Download and Install
```powershell
# Download Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Sysmon.zip"
Expand-Archive -Path "C:\Sysmon.zip" -DestinationPath "C:\Sysmon\"

# Download SwiftOnSecurity config (industry standard baseline)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "C:\Sysmon\sysmonconfig.xml"

# Install with config
C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml
```

### Configure Wazuh to Collect Sysmon Logs

Add to `C:\Program Files (x86)\ossec-agent\ossec.conf`:
```xml
<localfile>
    <location>Microsoft-Windows-Sysmon/Operational</location>
    <log_format>eventchannel</log_format>
</localfile>
```

Restart agent:
```powershell
NET STOP WazuhSvc
NET START WazuhSvc
```

### Key Sysmon Event IDs
| Event ID | Description |
|---|---|
| 1 | Process Create |
| 3 | Network Connection |
| 8 | CreateRemoteThread (process injection) |
| 10 | ProcessAccess (LSASS access) |
| 11 | File Create |
| 13 | Registry Value Set |

---

## Auditd Configuration (Linux)

### Install and Enable
```bash
sudo apt install auditd -y
sudo systemctl enable auditd
sudo systemctl start auditd
```

### Add Audit Rules
```bash
sudo bash -c 'cat >> /etc/audit/rules.d/audit.rules << EOF
# Monitor command execution
-a always,exit -F arch=b64 -S execve -k exec_commands
# Monitor privilege escalation
-w /etc/sudoers -p wa -k sudoers_change
# Monitor SSH config changes
-w /etc/ssh/sshd_config -p wa -k ssh_config_change
# Monitor user/group changes
-w /etc/passwd -p wa -k user_change
-w /etc/shadow -p wa -k shadow_change
EOF'

sudo systemctl restart auditd
```

### Configure Wazuh to Collect Auditd Logs

Add to `/var/ossec/etc/ossec.conf`:
```xml
<localfile>
    <log_format>audit</log_format>
    <location>/var/log/audit/audit.log</location>
</localfile>
```

---

## Custom Detection Rules

All custom rules are stored in `/var/ossec/etc/rules/local_rules.xml` on the Wazuh manager.

### Full Rules File

```xml
<!-- Local rules -->
<!-- Copyright (C) 2015, Wazuh Inc. -->

<group name="local,syslog,sshd,">
  <rule id="100001" level="5">
    <if_sid>5716</if_sid>
    <srcip>1.1.1.1</srcip>
    <description>sshd: authentication failed from IP 1.1.1.1.</description>
    <group>authentication_failed,pci_dss_10.2.4,pci_dss_10.2.5,</group>
  </rule>
</group>

<group name="local,sysmon,windows,">

  <rule id="100002" level="12">
    <if_group>sysmon</if_group>
    <field name="win.eventdata.image" type="pcre2">(?i)powershell\.exe</field>
    <field name="win.eventdata.commandLine" type="pcre2">(?i)(Get-WmiObject|systeminfo|ipconfig|whoami|net user|net localgroup)</field>
    <description>Possible System Discovery via PowerShell (T1082)</description>
    <mitre>
      <id>T1082</id>
    </mitre>
    <group>attack,discovery,</group>
  </rule>

  <rule id="100003" level="12">
    <if_group>sysmon</if_group>
    <field name="win.eventdata.image" type="pcre2">(?i)schtasks\.exe</field>
    <field name="win.eventdata.commandLine" type="pcre2">(?i)/create</field>
    <description>Scheduled Task Created - Possible Persistence (T1053.005)</description>
    <mitre>
      <id>T1053.005</id>
    </mitre>
    <group>attack,persistence,</group>
  </rule>

  <rule id="100004" level="12" frequency="5" timeframe="60">
    <if_matched_sid>60122</if_matched_sid>
    <description>Brute Force Attack - Multiple Windows Login Failures (T1110)</description>
    <mitre>
      <id>T1110</id>
    </mitre>
    <group>attack,authentication,</group>
  </rule>

  <rule id="100005" level="15">
    <if_group>sysmon</if_group>
    <field name="win.eventdata.commandLine" type="pcre2">(?i)(lsass|mimikatz|procdump|sekurlsa)</field>
    <description>Possible Credential Dumping Attempt (T1003)</description>
    <mitre>
      <id>T1003</id>
    </mitre>
    <group>attack,credential_access,</group>
  </rule>

  <rule id="100006" level="14">
    <if_group>sysmon</if_group>
    <field name="win.eventdata.sourceImage" type="pcre2">(?i)(powershell|cmd)\.exe</field>
    <field name="win.eventdata.targetImage" type="pcre2">(?i)(lsass|explorer|svchost)\.exe</field>
    <description>Possible Process Injection Detected (T1055)</description>
    <mitre>
      <id>T1055</id>
    </mitre>
    <group>attack,defense_evasion,</group>
  </rule>

</group>
```

### Deploy Rules
```bash
# Validate and restart Wazuh after any rule change
sudo /var/ossec/bin/wazuh-control restart
```

---

## Attack Simulations

### Install Atomic Red Team (Windows)
```powershell
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics -Force
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force
```

### Simulations Run

#### T1082 — System Information Discovery
```powershell
powershell.exe -Command "Get-WmiObject Win32_OperatingSystem"
Invoke-AtomicTest T1082 -TestNumbers 1
```
**Result:** Rule 100002 fired ✅

#### T1053.005 — Scheduled Task Persistence
```powershell
schtasks /create /tn "WindowsUpdateHelper" /tr "powershell.exe -WindowStyle Hidden -Command whoami" /sc onlogon /ru System /f
```
**Result:** Rule 100003 fired ✅

#### T1003 — Credential Dumping
```powershell
powershell.exe -Command "Get-Process lsass | Select-Object Id, Name"
```
**Result:** Rule 100005 fired ✅

#### Linux — Cron Persistence
```bash
(crontab -l 2>/dev/null; echo "* * * * * /tmp/backdoor.sh") | crontab -
```
**Result:** Wazuh built-in rule fired — "Crontab entry changed" ✅

#### Cleanup
```powershell
schtasks /delete /tn "WindowsUpdateHelper" /f
```

---

## Detection Results

### Overall Statistics
| Metric | Value |
|---|---|
| Total security events | 1,381+ |
| High severity alerts (level 12+) | 25+ |
| Authentication failures detected | 80+ |
| MITRE ATT&CK techniques mapped | 11 |
| Custom rules deployed | 5 |
| Active endpoints monitored | 3 |

### Custom Rules Performance
| Rule ID | Technique | Description | Level | Fired |
|---|---|---|---|---|
| 100002 | T1082 | System Discovery via PowerShell | 12 | ✅ |
| 100003 | T1053.005 | Scheduled Task Persistence | 12 | ✅ |
| 100004 | T1110 | Brute Force Login Attempts | 12 | ✅ |
| 100005 | T1003 | Credential Dumping Attempt | 15 | ✅ |
| 100006 | T1055 | Process Injection Detection | 14 | Configured |

### MITRE ATT&CK Techniques Detected
- Valid Accounts
- Password Guessing
- SSH
- Account Discovery
- Ingress Tool Transfer
- Brute Force
- Windows Command Execution
- Stored Data Manipulation
- Lateral Tool Transfer
- Command and Scripting
- OS Credential Dumping

---

## Detection Playbook

### Rule 100002 — System Discovery via PowerShell (T1082)
- **Log Source:** Sysmon Event ID 1 (Process Create)
- **Detection Logic:** PowerShell executing system enumeration commands (Get-WmiObject, systeminfo, ipconfig, whoami)
- **False Positive Sources:** IT admin scripts, software inventory tools
- **False Positive Mitigation:** Exclude known admin accounts and signed IT management tools by publisher certificate
- **Severity:** 12 (High)

### Rule 100003 — Scheduled Task Persistence (T1053.005)
- **Log Source:** Sysmon Event ID 1 (Process Create)
- **Detection Logic:** schtasks.exe executed with /create flag
- **False Positive Sources:** Legitimate software installers, Windows Update
- **False Positive Mitigation:** Exclude tasks created by SYSTEM during known patch windows, exclude signed installer processes
- **Severity:** 12 (High)

### Rule 100004 — Brute Force Login Attempts (T1110)
- **Log Source:** Windows Security Event ID 4625 (Failed Logon)
- **Detection Logic:** 5+ failed logins within 60 seconds from same source
- **False Positive Sources:** Users forgetting passwords, locked accounts, password managers
- **False Positive Mitigation:** Whitelist known IP ranges, tune threshold to 10 attempts for internal networks
- **Severity:** 12 (High)

### Rule 100005 — Credential Dumping Attempt (T1003)
- **Log Source:** Sysmon Event ID 1 (Process Create)
- **Detection Logic:** PowerShell command line referencing lsass, mimikatz, procdump, or sekurlsa
- **False Positive Sources:** Antivirus scans, legitimate diagnostic tools, IT security tools
- **False Positive Mitigation:** Exclude signed security vendor processes by certificate, not just process name
- **Severity:** 15 (Critical)

### Rule 100006 — Process Injection Detection (T1055)
- **Log Source:** Sysmon Event ID 8 (CreateRemoteThread)
- **Detection Logic:** PowerShell or cmd.exe attempting to inject into lsass, explorer, or svchost
- **False Positive Sources:** Legitimate software using remote threads for IPC
- **False Positive Mitigation:** Exclude known signed software by publisher certificate
- **Severity:** 14 (High)

---

## SOC Dashboard

Access at: `https://18.188.181.90`

### Key Dashboard Views
- **Security events → Dashboard:** Alert level evolution, Top MITRE ATT&CK techniques
- **Security events → Events:** Real-time event stream, filterable by agent/rule/technique
- **Threat Detection → MITRE ATT&CK:** Full ATT&CK matrix with coverage heatmap

### Useful Search Queries
```
# All Sysmon events
rule.groups: sysmon

# Events from specific agent
agent.name: windows-server

# Custom rules only
rule.id: 100002 OR rule.id: 100003 OR rule.id: 100005

# High severity only
rule.level: >= 12

# Specific MITRE technique
rule.mitre.id: T1082
```

---

## Repository Structure

```
blue-team-siem-lab/
├── README.md                          # This file
├── wazuh-rules/
│   └── local_rules.xml               # All 5 custom detection rules
├── playbook/
│   └── playbook.md                   # Detection playbook per rule
├── sigma-rules/                       # Sigma equivalents (coming soon)
└── dashboards/                        # SOC dashboard screenshots
```

---

## Key Lessons Learned

1. **Swap space is essential** for running Wazuh on a 1GB free-tier instance — without it the installer refuses to run
2. **Port 1515** (enrollment) must be open in addition to 1514 (agent comms) — agents will silently fail without it
3. **Rule syntax matters** — Wazuh rules must be inside `<group>` tags or the analysisd service won't start
4. **Sysmon config quality** determines detection quality — SwiftOnSecurity's config is a solid baseline
5. **MITRE ATT&CK mapping** happens automatically in Wazuh when you add `<mitre><id>` to rules

---

## Credits

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team)
- [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [SigmaHQ](https://github.com/SigmaHQ/sigma)

---

## License

MIT License — see LICENSE file.

