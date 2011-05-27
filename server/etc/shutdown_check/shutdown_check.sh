#!/bin/bash

setCount() {
    echo "COUNT=$1" > $GRACE_COUNT_FILE
}

logInfo() {
    logger -t "Shutdown Check" -p local5.info $1
}

logError() {
    logger -t "Shutdown Check" -p local5.err $1
}

logDebug() {
    logger -t "Shutdown Check" -p local5.debug $1
}

# The IP range to check. Any valid target range supported by nmap
RANGE="192.168.1.0/24"

# Hosts to exclude from counting. Comma separated list of ip addresses
#EXCLUDED_HOSTS="192.168.1.1"

# Grace period after which the shutdown is initiated.
# Allows the active client count to reach zero for the number of times indicated.
GRACE_PERIOD=2

# Enable debug messages to syslog
DEBUG=off

# Filename with the current grace period count
GRACE_COUNT_FILE="/var/run/shutdown_check"

# Directory where shutdown check scripts are located
#   Each script in the directory is run and the exit code evaluated
#   Exit code = 0  : the check allows shutdown
#   Exit code <> 0 : the check does not allow shutdown
CHECK_SCRIPT_DIR="/etc/shutdown_check/scripts-enabled"

# Load user configuration
[ -f "/etc/default/shutdown_check" ] && . /etc/default/shutdown_check

[ -n "$EXCLUDED_HOSTS" ] && EXCLUDE="--exclude $EXCLUDED_HOSTS"


ACTIVE_CLIENTS=`nmap -nsP $RANGE $EXCLUDE -oN - | grep "^Host is up" | wc -l`
[ "$DEBUG" == "on" ] && logDebug "Active clients = $ACTIVE_CLIENTS"

if [ $ACTIVE_CLIENTS -gt 0 ]; then
    [ "$DEBUG" == "on" ] && logDebug "Active clients > 0"
    if [ -f "$GRACE_COUNT_FILE" ]; then
        [ "$DEBUG" == "on" ] && logDebug "Gracefile exists, removing it"
        rm $GRACE_COUNT_FILE
    fi
else
    if [ ! -f "$GRACE_COUNT_FILE" ]; then
        setCount $GRACE_PERIOD
        [ "$DEBUG" == "on" ] && logDebug "Gracefile does not exist. Setting initial value"
    fi
    . $GRACE_COUNT_FILE
    if [ $COUNT -le 0 ]; then
        [ "$DEBUG" == "on" ] && logDebug "Active clients have reached zero, starting shutdown checks"
        for script in `ls $CHECK_SCRIPT_DIR`; do
            $CHECK_SCRIPT_DIR/$script
            if [ $? -ne 0 ]; then
                logInfo "Script '`basename $script`' reports system still in usage. Not shutting down."
                exit 0;
            fi
	done

	logInfo "Shutting down system, no active clients or services detected!"
	rm -f $GRACE_COUNT_FILE
        shutdown -h now;
    else
        let COUNT=$COUNT-1
        setCount $COUNT
        [ "$DEBUG" == "on" ] && logDebug "Decrease grace period count to $COUNT"
    fi;
fi

