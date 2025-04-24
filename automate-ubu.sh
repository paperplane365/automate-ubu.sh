#!/bin/bash
#
# Script to automate system update and upgrade, with rsnapshot backup and error checking.
#
# Intended to be run as root (e.g., via cron).
#
# Configuration:
#
#  * This script assumes rsnapshot is already configured and working.
#  * Specifically, it assumes you have a backup level named 'alpha' for daily backups.
#  * Modify the RSNAPSHOT_CONFIG_FILE and RSNAPSHOT_BACKUP_BASE if needed.
#  * Log file location is defined within the script.
#
# Variables
RSNAPSHOT_CONFIG_FILE="/etc/rsnapshot.conf" # Default rsnapshot configuration file location.
RSNAPSHOT_BACKUP_BASE="/var/cache/snapshots/" # Default backup location.  Make sure this matches your rsnapshot.conf
LOG_FILE="/var/log/system_update_upgrade.log" # Log file to store script output.
# Ensure the log file exists and is writable
touch "$LOG_FILE"
# Function to log messages with timestamps
log_message() {
  TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
  echo "$TIMESTAMP: $1" >> "$LOG_FILE"
}

# Function to perform the rsnapshot backup
rsnapshot_backup() {
  log_message "Starting rsnapshot backup (alpha)..."
  # Use the config file.
  rsnapshot -c "$RSNAPSHOT_CONFIG_FILE" alpha
  if [ $? -eq 0 ]; then
    log_message "rsnapshot backup (alpha) completed successfully."
  else
    log_message "ERROR: rsnapshot backup (alpha) failed!"
    # Continue even if backup fails, but set overall error status.
    ERROR_OCCURRED=1
  fi
}

# Function to update and upgrade the system
update_upgrade_system() {
  log_message "Starting system update and upgrade..."

  # Update the package lists
  apt update
  if [ $? -ne 0 ]; then
    log_message "ERROR: apt update failed!"
    ERROR_OCCURRED=1
    return # Stop if update fails
  else
    log_message "apt update completed."
  fi

  # Upgrade the packages
  apt upgrade -y
  if [ $? -ne 0 ]; then
    log_message "ERROR: apt upgrade failed!"
    ERROR_OCCURRED=1
    return # Stop if upgrade fails
  else
    log_message "apt upgrade completed."
  fi
   # Dist-upgrade
  apt dist-upgrade -y
  if [ $? -ne 0 ]; then
    log_message "ERROR: apt dist-upgrade failed!"
    ERROR_OCCURRED=1
    return # Stop if dist-upgrade fails
  else
    log_message "apt dist-upgrade completed."
  fi

  # Autoremove
  apt autoremove -y
  if [ $? -ne 0 ]; then
    log_message "ERROR: apt autoremove failed!"
    ERROR_OCCURRED=1
    return
  else
    log_message "apt autoremove completed."
  fi

  #If you want to automatically reboot
  # reboot
  # if [ $? -ne 0 ]; then
  #   log_message "ERROR: reboot failed!"
  #   ERROR_OCCURRED=1
  # else
  #  log_message "Rebooted System"
  # fi
}

# Main script logic
ERROR_OCCURRED=0 # Initialize error flag

# Perform the rsnapshot backup
rsnapshot_backup

# Perform the system update and upgrade
update_upgrade_system

# Check for errors and log the final status
if [ $ERROR_OCCURRED -eq 0 ]; then
  log_message "System update and upgrade process completed successfully."
else
  log_message "System update and upgrade process completed with errors.  Check $LOG_FILE for details."
fi

exit 0
