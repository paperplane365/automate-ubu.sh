#!/bin/bash
# This script automates the process of updating and upgrading a Debian/Ubuntu based Linux system.
# It performs the following actions:
# 1. Updates the package lists.
# 2. Upgrades the installed packages to their newest versions.
# 3. (Optional) Removes obsolete packages.
# 4. (Optional) Checks for and installs available distribution upgrades.
# 5. Logs the output to a file.
#
# Intended Use:
# This script is designed to be run on Debian-based systems (e.g., Ubuntu, Mint).  It should be
# run with superuser (root) privileges, or by a user with sudo privileges.
#
# Modifications:
# You can customize the script by changing the variables below.  For example, you can
# change the log file location, add additional commands, or change the options
# passed to apt.

# --- Configuration Variables ---
LOG_FILE="/var/log/system_update_upgrade.log"  # Path to the log file
REMOVE_OBSOLETE_PACKAGES="true"             # Set to "true" to remove obsolete packages after upgrading, "false" to skip
RUN_DIST_UPGRADE="false"                   # Set to "true" to run a full distribution upgrade, "false" for a regular upgrade
# --- End Configuration Variables ---

# --- Helper Functions ---

# Function to log messages to the console and the log file
log_message() {
    local message="$1"
    echo "$(date) - $message" | tee -a "$LOG_FILE"
}

# Function to check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "Error: This script must be run as root or with sudo."
        exit 1
    fi
}

# --- Main Script ---

# 1. Check if the script is run with root privileges
check_root

# 2. Start logging
log_message "Starting system update and upgrade process..."

# 3. Update the package lists
log_message "Updating package lists..."
sudo apt-get update -y 2>&1 | tee -a "$LOG_FILE"  # Redirect both stdout and stderr to the log

# 4. Upgrade the installed packages
log_message "Upgrading packages..."
sudo apt-get upgrade -y 2>&1 | tee -a "$LOG_FILE"

# 5. Optionally remove obsolete packages
if [ "$REMOVE_OBSOLETE_PACKAGES" = "true" ]; then
    log_message "Removing obsolete packages..."
    sudo apt-get autoremove -y 2>&1 | tee -a "$LOG_FILE"
else
    log_message "Skipping removal of obsolete packages."
fi

# 6. Optionally perform a full distribution upgrade
if [ "$RUN_DIST_UPGRADE" = "true" ]; then
    log_message "Running distribution upgrade..."
    sudo apt-get dist-upgrade -y 2>&1 | tee -a "$LOG_FILE"
else
    log_message "Skipping distribution upgrade."
fi

# 7. Check for errors during the upgrade process.  Simple check.
if grep -q "Errors were encountered" "$LOG_FILE"; then
    log_message "Error: Errors were encountered during the update/upgrade process. Check $LOG_FILE for details."
    exit 1
fi

# 8. Finish
log_message "System update and upgrade process completed."
exit 0