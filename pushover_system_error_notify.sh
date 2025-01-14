#!/bin/sh

# This script performs the following actions on pfsense:

# 1. Monitors a Log File: It continuously monitors the specified log file (/var/log/system.log by default) for lines containing a specific search string (error by default).
# 2. Sends Notifications: When a line containing the search string is found, it sends a notification using the PushOver API. The notification includes the logline that triggered the alert.
# 3. Outputs to Terminal: It also outputs the logline to the terminal for immediate visibility.

# Key Components:
# -Log File: The file being monitored is defined by the LOG_FILE variable.
# -Search String: The string being searched for in the log file is defined by the SEARCH_STRING variable.
# -PushOver Credentials: USER_KEY and API_TOKEN hold the credentials for PushOver API.
# -Notification Function: send_notification sends the notification through PushOver.
# -Output Function: output_to_screen outputs the logline to the terminal.
# -Monitoring Function: monitor_log uses tail -F to monitor the log file and trigger notifications and outputs when the search string is found.

# Workflow:
# The script starts monitoring the log file in the background.
# When a line containing the search string is found, it sends a notification and outputs the line to the terminal.
# It checks the response from PushOver to confirm if the notification was sent successfully and logs the result.

# Log file to monitor (adjust as needed)
LOG_FILE="/var/log/system.log"  # You can change this to any service log file you want to monitor (e.g., OpenVPN, DNS)

# Log string to search for (adjust as needed)
SEARCH_STRING="error"   # You can modify the string or allow it to be passed as a parameter

# Pushover credentials
USER_KEY="XXXXXXXXXXXXXXXXXXXXXXXXX"      # Your Pushover User Key
API_TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXX"    # Your Pushover API Token

# PushOver notification details
TITLE="pfSense System Error Monitoring"

# Function to send PushOver notification
send_notification() {
    # Make the PushOver API request and capture the response
    response=$(curl -s --form-string "token=$API_TOKEN" \
        --form-string "user=$USER_KEY" \
        --form-string "message=$1" \
        --form-string "title=$TITLE" \
        https://api.pushover.net/1/messages.json)

    # Check if the response contains "status": "ok" to confirm success
    if echo "$response" | grep -q '"status":"ok"'; then
        echo "[INFO] PushOver notification sent successfully."
    else
        echo "[ERROR] Failed to send PushOver notification."
    fi
}

# Function to output the log line to the terminal
output_to_screen() {
    echo "pfSense Log Event: $1"
}

# Monitor the log file for the search string in the background
monitor_log() {
    tail -F "$LOG_FILE" | while read line
    do
        # If the search string is found in the log line
        if echo "$line" | grep -q "$SEARCH_STRING"; then
            # Send PushOver notification with the full log line
            send_notification "$line"
            # Output the entire log line to the screen
            output_to_screen "$line"

            # Check if the PushOver request was successful and output the result
            if [ $? -eq 0 ]; then
                echo "[INFO] PushOver notification sent successfully."
            else
                echo "[ERROR] Failed to send PushOver notification."
            fi
        fi
    done
}

# Run the log monitoring in the background
monitor_log &
