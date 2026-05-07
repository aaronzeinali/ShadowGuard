# ShadowGuard User Guide

**Version:** 1.0
**Last Updated:** 2026-05-08
**License:** MIT

---

## Table of Contents

- [ShadowGuard User Guide](#shadowguard-user-guide)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
    - [Key Features](#key-features)
  - [System Requirements](#system-requirements)
    - [Windows](#windows)
    - [Linux](#linux)
  - [Installation](#installation)
    - [Windows](#windows-1)
    - [Linux](#linux-1)
    - [Configuration](#configuration)
    - [Linux — `config.conf`](#linux--configconf)
    - [Configuration Parameters](#configuration-parameters)
  - [Usage](#usage)
    - [Starting ShadowGuard](#starting-shadowguard)
    - [Stopping ShadowGuard](#stopping-shadowguard)
    - [First Run Behavior](#first-run-behavior)
    - [Viewing Alerts](#viewing-alerts)
  - [Alert System](#alert-system)
    - [Alert Levels](#alert-levels)
    - [Alert Triggers](#alert-triggers)
    - [Automated Response Actions](#automated-response-actions)
  - [Log Analysis](#log-analysis)
    - [Log File Locations](#log-file-locations)
    - [Log Entry Format](#log-entry-format)
    - [Useful Log Queries](#useful-log-queries)
  - [Troubleshooting](#troubleshooting)
    - [High CPU Usage](#high-cpu-usage)
    - [Too Many False Positives](#too-many-false-positives)
    - [Permission Denied Errors](#permission-denied-errors)
    - [Log Files Not Rotating](#log-files-not-rotating)
    - [Quarantine Directory Full](#quarantine-directory-full)
  - [Advanced Usage](#advanced-usage)
    - [Using SHA-512 for Stronger Integrity Checks](#using-sha-512-for-stronger-integrity-checks)
    - [Running in Stealth Mode](#running-in-stealth-mode)
    - [SIEM Integration](#siem-integration)
    - [Monitoring Multiple Servers Centrally](#monitoring-multiple-servers-centrally)
  - [Best Practices](#best-practices)
  - [Security Considerations](#security-considerations)
  - [Support](#support)

---

## Introduction

ShadowGuard is an open-source, cross-platform system integrity monitoring tool
designed to detect unauthorized changes, suspicious processes, and anomalous
network activity in real time. It combines File Integrity Monitoring (FIM),
process anomaly detection, and automated threat response into a single
lightweight solution that runs on both Windows and Linux.

### Key Features

- Real-time file integrity monitoring using cryptographic hashing
- Process anomaly detection and behavioral analysis
- Network traffic monitoring for suspicious connections
- Automated threat response including quarantine and blocking
- Detailed logging and alerting system
- Low resource footprint suitable for production environments

---

## System Requirements

### Windows

| Component   | Minimum             | Recommended          |
|-------------|---------------------|----------------------|
| OS          | Windows 10 / Server 2016 | Windows 11 / Server 2022 |
| RAM         | 512 MB              | 1 GB                 |
| Disk Space  | 200 MB              | 1 GB                 |
| Privileges  | Administrator       | Administrator        |

### Linux

| Component   | Minimum             | Recommended          |
|-------------|---------------------|----------------------|
| OS          | Ubuntu 18.04 / CentOS 7 | Ubuntu 22.04 / Debian 12 |
| RAM         | 256 MB              | 512 MB               |
| Disk Space  | 200 MB              | 1 GB                 |
| Privileges  | root                | root                 |

---

## Installation

### Windows

1. Download or clone the repository from GitHub.
2. Open Command Prompt as **Administrator**.
3. Navigate to the `windows` folder:
```cmd
   cd windows
   install.bat
```   
4. Run the installer:
   install.bat
5. The installer will:
   Copy files to C:\ProgramData\ShadowGuard\
   Create the default configuration file
   Set up log directories
   Register ShadowGuard as a scheduled task (optional)
   
### Linux
1. Download or clone the repository from GitHub.
2. Open a terminal and navigate to the linux folder:
   cd linux
3. Make the scripts executable:
    chmod +x install.sh shadowguard.sh
4. Run the installer with root privileges:
    sudo ./install.sh
5. The installer will:
    Copy files to /opt/shadowguard/
    Create the configuration file at /etc/shadowguard/config.conf
    Set up log rotation under /var/log/shadowguard/
    Optionally register a systemd service    

### Configuration
Windows — config.ini
Located at: C:\ProgramData\ShadowGuard\config.ini
[MONITORING]
WATCH_DIRS=C:\Windows\System32,C:\Program Files
SCAN_INTERVAL=300
HASH_ALGORITHM=SHA256

[ALERTS]
ALERT_LEVEL=MEDIUM
EMAIL_ALERTS=false
EMAIL_TO=admin@example.com
LOG_FILE=C:\ProgramData\ShadowGuard\logs\alerts.log

[RESPONSE]
AUTO_QUARANTINE=true
QUARANTINE_DIR=C:\ProgramData\ShadowGuard\quarantine
BLOCK_SUSPICIOUS=true

[NETWORK]
MONITOR_NETWORK=true
SUSPICIOUS_PORTS=4444,5555,6666,31337

### Linux — `config.conf`

Located at: `/etc/shadowguard/config.conf`

bash
WATCH_DIRS="/etc /usr/bin /var/www"
SCAN_INTERVAL=300
HASH_ALGORITHM="sha256sum"

ALERT_LEVEL="MEDIUM"
EMAIL_ALERTS=false
EMAIL_TO="admin@example.com"
LOG_FILE="/var/log/shadowguard/alerts.log"

AUTO_QUARANTINE=true
QUARANTINE_DIR="/var/quarantine/shadowguard"
BLOCK_SUSPICIOUS=true

MONITOR_NETWORK=true
SUSPICIOUS_PORTS="4444 5555 6666 31337"

### Configuration Parameters

| Parameter          | Description                                      | Accepted Values              |
|--------------------|--------------------------------------------------|------------------------------|
| `WATCH_DIRS`       | Directories to monitor (comma-separated)         | Any valid path               |
| `SCAN_INTERVAL`    | Time between scans in seconds                    | 60 – 3600                    |
| `HASH_ALGORITHM`   | Hashing algorithm for file integrity checks      | SHA256, SHA512, MD5          |
| `ALERT_LEVEL`      | Minimum severity level to trigger an alert       | LOW, MEDIUM, HIGH, CRITICAL  |
| `EMAIL_ALERTS`     | Enable or disable email notifications            | true / false                 |
| `EMAIL_TO`         | Recipient address for alert emails               | Valid email address          |
| `AUTO_QUARANTINE`  | Automatically quarantine suspicious files        | true / false                 |
| `QUARANTINE_DIR`   | Directory where quarantined files are stored     | Any valid path               |
| `BLOCK_SUSPICIOUS` | Block execution of suspicious files              | true / false                 |
| `MONITOR_NETWORK`  | Enable network connection monitoring             | true / false                 |
| `SUSPICIOUS_PORTS` | Ports flagged as suspicious                      | Comma-separated port numbers |

---

## Usage

### Starting ShadowGuard

**Windows:**
cmd
cd C:\ProgramData\ShadowGuard
shadowguard.bat

Run in the background:
cmd
start /B shadowguard.bat

**Linux:**
bash
sudo /opt/shadowguard/shadowguard.sh

Run in the background:
bash
sudo nohup /opt/shadowguard/shadowguard.sh &

### Stopping ShadowGuard

**Windows:**
cmd
taskkill /F /IM shadowguard.bat

**Linux:**
bash
sudo pkill -f shadowguard.sh

### First Run Behavior

On the first run, ShadowGuard performs an initial baseline scan:

1. It calculates cryptographic hashes for all files in `WATCH_DIRS`.
2. It stores the results in a local hash database.
3. After the baseline is complete, it enters real-time monitoring mode.

> **Note:** The initial scan may take 5 to 30 minutes depending on the number
> of files being monitored. Do not interrupt this process.

### Viewing Alerts

**Windows:**
cmd
type C:\ProgramData\ShadowGuard\logs\alerts.log

**Linux:**
bash
sudo tail -f /var/log/shadowguard/alerts.log

---

## Alert System

### Alert Levels

| Level        | Description                                      | Example                          |
|--------------|--------------------------------------------------|----------------------------------|
| **LOW**      | Minor or expected changes                        | Temporary files, cache updates   |
| **MEDIUM**   | Notable changes that warrant review              | Configuration file modifications |
| **HIGH**     | Suspicious changes requiring prompt attention    | System binary modifications      |
| **CRITICAL** | Immediate threat detected                        | Core OS executable tampered      |

### Alert Triggers

ShadowGuard generates alerts when any of the following are detected:

- A monitored file's hash does not match the stored baseline
- A new file appears in a protected directory
- A critical system file is deleted
- A process exhibits anomalous behavior (unexpected parent, unusual memory usage)
- An outbound connection is made to a suspicious port
- CPU or memory usage spikes beyond normal thresholds

### Automated Response Actions

When a threat is detected, ShadowGuard can take the following actions
automatically based on your configuration:

1. **Log** — Records full details of the event including file path, original
   hash, new hash, timestamp, and process information.
2. **Alert** — Sends an email notification if `EMAIL_ALERTS` is enabled.
3. **Quarantine** — Moves the suspicious file to `QUARANTINE_DIR` with a
   timestamped filename.
4. **Block** — Prevents execution of the suspicious file (CRITICAL level only).

---

## Log Analysis

### Log File Locations

**Windows:**

| File                                                    | Contents                  |
|---------------------------------------------------------|---------------------------|
| `C:\ProgramData\ShadowGuard\logs\alerts.log`            | Security alerts           |
| `C:\ProgramData\ShadowGuard\logs\system.log`            | System operations         |
| `C:\ProgramData\ShadowGuard\baseline\hashes.db`         | Baseline hash database    |

**Linux:**

| File                                      | Contents                  |
|-------------------------------------------|---------------------------|
| `/var/log/shadowguard/alerts.log`         | Security alerts           |
| `/var/log/shadowguard/system.log`         | System operations         |
| `/var/lib/shadowguard/hashes.db`          | Baseline hash database    |

### Log Entry Format


[YYYY-MM-DD HH:MM:SS] [LEVEL] Event description
  Detail key: Detail value
  Action: Action taken

**Example:**

[2026-05-08 14:23:45] [CRITICAL] File modified: /usr/bin/sudo
  Original Hash: a1b2c3d4e5f67890abcdef1234567890
  Current Hash:  f09e8d7c6b5a4321fedcba0987654321
  Action: QUARANTINED -> /var/quarantine/shadowguard/sudo.20260508_142345

### Useful Log Queries

Count alerts from today (Linux):
bash
grep "$(date +%Y-%m-%d)" /var/log/shadowguard/alerts.log | wc -l

Show only CRITICAL alerts:
bash
grep "\[CRITICAL\]" /var/log/shadowguard/alerts.log

Show alerts from the last hour:
bash
awk -v d="$(date -d '1 hour ago' '+%Y-%m-%d %H:%M')" '$0 >= d' \
  /var/log/shadowguard/alerts.log

---

## Troubleshooting

### High CPU Usage

**Cause:** Scanning a large number of files too frequently.

**Solution:**
- Increase `SCAN_INTERVAL` to 600 or higher.
- Reduce the number of paths in `WATCH_DIRS`.
- Switch to a faster hash algorithm such as MD5 (less secure but faster).

---

### Too Many False Positives

**Cause:** Legitimate system updates or application changes triggering alerts.

**Solution:**
- After a system update, rebuild the baseline by deleting `hashes.db` and
  restarting ShadowGuard.
- Remove frequently changing directories (temp folders, cache) from `WATCH_DIRS`.
- Lower `ALERT_LEVEL` to HIGH so minor changes are ignored.

---

### Permission Denied Errors

**Windows:** Right-click Command Prompt and select **Run as Administrator**.

**Linux:** Ensure you are running with `sudo` or as the root user.

---

### Log Files Not Rotating

Manually trigger log rotation on Linux:
bash
sudo logrotate -f /etc/logrotate.d/shadowguard

---

### Quarantine Directory Full

Remove quarantined files older than 30 days:

**Windows:**
cmd
forfiles /P "C:\ProgramData\ShadowGuard\quarantine" /D -30 /C "cmd /c del @path"

**Linux:**
bash
find /var/quarantine/shadowguard -type f -mtime +30 -delete

---

## Advanced Usage

### Using SHA-512 for Stronger Integrity Checks

**Windows (`config.ini`):**
ini
HASH_ALGORITHM=SHA512

**Linux (`config.conf`):**
bash
HASH_ALGORITHM="sha512sum"

SHA-512 provides stronger collision resistance at the cost of slightly higher
CPU usage.

---

### Running in Stealth Mode

To reduce ShadowGuard's visibility to other monitoring tools:

**Linux:**
bash
sudo nice -n 19 ionice -c 3 /opt/shadowguard/shadowguard.sh &

This runs the process at the lowest CPU and I/O priority.

---

### SIEM Integration

ShadowGuard logs are plain text and can be forwarded to any SIEM platform
such as Splunk, Elastic Stack, or Graylog using a log shipper.

**Example using Filebeat (Elastic):**

Add the following to your `filebeat.yml`:
yaml
filebeat.inputs:
  - type: log
enabled: true
paths:
- /var/log/shadowguard/alerts.log
fields:
source: shadowguard

---

### Monitoring Multiple Servers Centrally

Use SSH to collect alerts from multiple hosts:

bash
#!/bin/bash
SERVERS="server1 server2 server3"
for server in $SERVERS; do
echo "=== $server ==="
ssh "$server" "sudo tail -n 50 /var/log/shadowguard/alerts.log"
done

---

## Best Practices

- **Rebuild the baseline** after every planned system update or software
  installation to avoid false positives.
- **Back up your logs** daily to an external or centralized location.
- **Test in a staging environment** before deploying to production systems.
- **Review quarantined files** regularly rather than deleting them immediately,
  as they may be needed for forensic analysis.
- **Keep ShadowGuard updated** by pulling the latest version from GitHub every
  few months.
- **Restrict access** to configuration files and log directories to
  administrative users only.

---

## Security Considerations

> ⚠️ The following points are critical for maintaining the integrity of
> ShadowGuard itself.

- **Protect the hash database.** If an attacker can modify `hashes.db`, they
  can bypass detection entirely. Store it on a read-only or access-controlled
  partition.
- **Secure the configuration file.** It may contain email credentials or
  sensitive paths. Set file permissions to restrict read access.
- **Monitor ShadowGuard's own files.** Add the ShadowGuard installation
  directory to `WATCH_DIRS` so any tampering with the tool itself is detected.
- **Use a dedicated quarantine partition.** This prevents a full quarantine
  directory from filling the system disk and causing a denial of service.
- **Do not run ShadowGuard on untrusted systems.** The tool assumes the initial
  baseline state is clean. If the system is already compromised at install time,
  the baseline will reflect the compromised state.

---

## Support

- **GitHub Issues:** https://github.com/aaronzeinali/ShadowGuard/issues
- **GitHub Discussions:** https://github.com/aaronzeinali/ShadowGuard/discussions
- **Email:** aaronzeinali@blackrose.company

When reporting a bug, please include:
- Your operating system and version
- The ShadowGuard version
- The relevant section of your configuration file (remove any sensitive values)
- The full log output around the time the issue occurred

---

*ShadowGuard is provided as-is under the MIT License. Use it responsibly and
only on systems you own or have explicit permission to monitor.*



   
