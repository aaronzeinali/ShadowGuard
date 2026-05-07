# 🛡️ ShadowGuard - Advanced System Integrity Monitor

A cross-platform security monitoring tool that provides real-time file integrity monitoring, process anomaly detection, and automated threat response.

##Features

- **File Integrity Monitoring (FIM)**: Real-time cryptographic hash verification
- **Process Anomaly Detection**: Baseline behavior analysis and suspicious process detection
- **Network Monitoring**: Track active connections and detect unusual network activity
- **Automated Response**: Quarantine suspicious files and kill malicious processes
- **Encrypted Logging**: Tamper-proof audit trail with hash verification
- **Zero Dependencies**: Pure batch/bash implementation

## Supported Platforms

- Windows (7/8/10/11) - Batch script
- Linux (Ubuntu/Debian/CentOS/RHEL) - Bash script

## Installation

### Windows
```cmd
cd windows
install.bat

### Linux
bash
cd linux
chmod +x install.sh
sudo ./install.sh

## Usage

### Windows
cmd
shadowguard.bat [start|stop|status|scan]

### Linux
bash
sudo ./shadowguard.sh [start|stop|status|scan]

## Configuration

Edit `config.ini` (Windows) or `config.conf` (Linux) to customize:
- Monitored directories
- Alert thresholds
- Response actions
- Log retention

## Security Notice

This tool requires administrative/root privileges to function properly.

## Licenses

MIT License - See LICENSE file
BSV License - Powered by BOOKINGO SECURITY 
