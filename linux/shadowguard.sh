#!/bin/bash

# ShadowGuard - Linux Security Monitor
# Version: 1.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_DIR="$SCRIPT_DIR/logs"
BASELINE_DIR="$SCRIPT_DIR/baseline"
QUARANTINE_DIR="$SCRIPT_DIR/quarantine"
LOCK_FILE="$SCRIPT_DIR/.shadowguard.lock"
PID_FILE="$SCRIPT_DIR/.shadowguard.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This script must be run as root"
   exit 1
fi

# Create directories
mkdir -p "$LOG_DIR" "$BASELINE_DIR" "$QUARANTINE_DIR"

# Load configuration
load_config() {
    MONITOR_PATHS="/etc /usr/bin /home"
    SCAN_INTERVAL=300
    ALERT_LEVEL=2
    AUTO_QUARANTINE=1
    
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Create baseline
create_baseline() {
    local baseline_file="$BASELINE_DIR/file_hashes.txt"
    echo -e "${GREEN}[INFO]${NC} Creating baseline..."
    
    echo "# ShadowGuard Baseline - $(date)" > "$baseline_file"
    
    for path in $MONITOR_PATHS; do
        if [[ -d "$path" ]]; then
            find "$path" -type f 2>/dev/null | while read -r file; do
                hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
                if [[ -n "$hash" ]]; then
                    echo "$file|$hash" >> "$baseline_file"
                fi
            done
        fi
    done
    
    echo -e "${GREEN}[INFO]${NC} Baseline created"
}

# File integrity check
file_integrity_check() {
    local log_file="$LOG_DIR/fim_$(date +%Y%m%d).log"
    local baseline_file="$BASELINE_DIR/file_hashes.txt"
    
    [[ ! -f "$baseline_file" ]] && return
    
    echo "[$(date)] File Integrity Check Started" >> "$log_file"
    
    while IFS='|' read -r file_path expected_hash; do
        [[ "$file_path" =~ ^# ]] && continue
        
        if [[ -f "$file_path" ]]; then
            current_hash=$(sha256sum "$file_path" 2>/dev/null | awk '{print $1}')
            if [[ "$current_hash" != "$expected_hash" ]]; then
                echo -e "${RED}[ALERT]${NC} File modified: $file_path"
                echo "[$(date)] [ALERT] File modified: $file_path" >> "$log_file"
                alert_handler "FILE_MODIFIED" "$file_path"
            fi
        else
            echo -e "${YELLOW}[ALERT]${NC} File deleted: $file_path"
            echo "[$(date)] [ALERT] File deleted: $file_path" >> "$log_file"
            alert_handler "FILE_DELETED" "$file_path"
        fi
    done < "$baseline_file"
}

# Process anomaly detection
process_anomaly_check() {
    local log_file="$LOG_DIR/process_$(date +%Y%m%d).log"
    echo "[$(date)] Process Check Started" >> "$log_file"
    
    # Check for suspicious process names
    ps aux | grep -iE "mimikatz|keylogger|backdoor|trojan|netcat.*-e" | grep -v grep | while read -r line; do
        pid=$(echo "$line" | awk '{print $2}')
        proc=$(echo "$line" | awk '{print $11}')
        echo -e "${RED}[ALERT]${NC} Suspicious process: $proc (PID: $pid)"
        echo "[$(date)] [ALERT] Suspicious process: $proc (PID: $pid)" >> "$log_file"
        alert_handler "SUSPICIOUS_PROCESS" "$pid:$proc"
    done
    
    # Check for processes listening on unusual ports
    netstat -tulpn 2>/dev/null | grep -E ":(4444|5555|6666|31337|1337)" | while read -r line; do
        echo -e "${YELLOW}[ALERT]${NC} Suspicious port: $line"
        echo "[$(date)] [ALERT] Suspicious port: $line" >> "$log_file"
    done
}

# Network monitoring
network_check() {
    local log_file="$LOG_DIR/network_$(date +%Y%m%d).log"
    echo "[$(date)] Network Check Started" >> "$log_file"
    
    # Check for suspicious connections
    netstat -antp 2>/dev/null | grep ESTABLISHED | grep -E ":(4444|5555|6666|31337)" | while read -r line; do
        echo -e "${RED}[ALERT]${NC} Suspicious connection: $line"
        echo "[$(date)] [ALERT] Suspicious connection: $line" >> "$log_file"
        alert_handler "SUSPICIOUS_CONNECTION" "$line"
    done
}

# Alert handler
alert_handler() {
    local alert_type="$1"
    local alert_data="$2"
    local alert_log="$LOG_DIR/alerts.log"
    
    echo "[$(date)] [$alert_type] $alert_data" >> "$alert_log"
    
    if [[ "$AUTO_QUARANTINE" == "1" ]]; then
        case "$alert_type" in
            FILE_MODIFIED)
                quarantine_file "$alert_data"
                ;;
            SUSPICIOUS_PROCESS)
                pid=$(echo "$alert_data" | cut -d: -f1)
                kill -9 "$pid" 2>/dev/null
                echo "[$(date)] [ACTION] Killed process PID: $pid" >> "$alert_log"
                ;;
        esac
    fi
}

# Quarantine file
quarantine_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    local quarantine_path="$QUARANTINE_DIR/${file_name}.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file_path" ]]; then
        mv "$file_path" "$quarantine_path" 2>/dev/null
        echo "[$(date)] [ACTION] Quarantined: $file_path" >> "$LOG_DIR/alerts.log"
    fi
}

# Monitoring loop
monitor_loop() {
    echo -e "${GREEN}[INFO]${NC} Monitoring started. Press Ctrl+C to stop."
    
    while [[ -f "$LOCK_FILE" ]]; do
        file_integrity_check
        process_anomaly_check
        network_check
        sleep "$SCAN_INTERVAL"
    done
}

# Start service
start_service() {
    echo -e "${GREEN}[INFO]${NC} Starting ShadowGuard..."
    
    if [[ -f "$LOCK_FILE" ]]; then
        echo -e "${YELLOW}[WARN]${NC} ShadowGuard is already running"
        exit 0
    fi
    
    date > "$LOCK_FILE"
    echo $$ > "$PID_FILE"
    
    load_config
    
    if [[ ! -f "$BASELINE_DIR/file_hashes.txt" ]]; then
        create_baseline
    fi
    
    monitor_loop &
    echo -e "${GREEN}[INFO]${NC} ShadowGuard started successfully (PID: $$)"
}

# Stop service
stop_service() {
    echo -e "${GREEN}[INFO]${NC} Stopping ShadowGuard..."
    
    if [[ ! -f "$LOCK_FILE" ]]; then
        echo -e "${YELLOW}[WARN]${NC} ShadowGuard is not running"
        exit 0
    fi
    
    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null
        rm -f "$PID_FILE"
    fi
    
    rm -f "$LOCK_FILE"
    echo -e "${GREEN}[INFO]${NC} ShadowGuard stopped"
}

# Check status
check_status() {
    if [[ -f "$LOCK_FILE" ]]; then
        echo -e "${GREEN}[STATUS]${NC} ShadowGuard is RUNNING"
        cat "$LOCK_FILE"
    else
        echo -e "${YELLOW}[STATUS]${NC} ShadowGuard is STOPPED"
    fi
}

# Manual scan
manual_scan() {
    echo -e "${GREEN}[INFO]${NC} Running manual security scan..."
    load_config
    file_integrity_check
    process_anomaly_check
    network_check
    echo -e "${GREEN}[INFO]${NC} Scan completed. Check logs for details."
}

# Show help
show_help() {
    echo "ShadowGuard - Advanced System Integrity Monitor"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start   - Start monitoring service"
    echo "  stop    - Stop monitoring service"
    echo "  status  - Check service status"
    echo "  scan    - Run manual security scan"
    echo "  help    - Show this help message"
}

# Main
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    status)
        check_status
        ;;
    scan)
        manual_scan
        ;;
    help|*)
        show_help
        ;;
esac
