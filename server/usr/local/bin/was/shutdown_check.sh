#!/bin/bash

WAS_BASE_DIR=${WAS_BASE_DIR:=/etc/shutdown_check}
WAS_DEFAULT_CONF=${WAS_DEFAULT_CONF:=/etc/default/shutdown_check}

## Default values, can be changed via the WAS_DEFAULT_CONF file:

# Grace period after which the shutdown is initiated.
# Allows the active client count to reach zero for the number of times indicated.
GRACE_PERIOD=2

# Enable debug messages to syslog
DEBUG=on
## /Default values

setCount() {
    echo "COUNT=$1" > $GRACE_COUNT_FILE
}

# Source logger functions
. $WAS_BASE_DIR/logger-functions


# Filename with the current grace period count
GRACE_COUNT_FILE="/var/run/shutdown_check"

# Directory where shutdown check scripts are located
#   Each script in the directory is run and the exit code evaluated
#   Exit code = 0  : the check allows shutdown
#   Exit code <> 0 : the check does not allow shutdown
CHECK_SCRIPT_DIR="$WAS_BASE_DIR/scripts-enabled"

# Load user configuration
[ -f "$WAS_DEFAULT_CONF" ] && . $WAS_DEFAULT_CONF

if [ ! -f "$GRACE_COUNT_FILE" ]; then
    setCount $GRACE_PERIOD
    [ "$DEBUG" == "on" ] && logDebug "Gracefile does not exist. Setting initial value of $GRACE_PERIOD"
fi
. $GRACE_COUNT_FILE
if [ $COUNT -le 0 ]; then
    [ "$DEBUG" == "on" ] && logDebug "Starting shutdown checks"
    for script in `ls $CHECK_SCRIPT_DIR`; do
        $CHECK_SCRIPT_DIR/$script
        if [ $? -ne 0 ]; then
            logInfo "Script '`basename $script`' reports system still in usage. Not shutting down."
            exit 0;
        fi
    done
    logInfo "Shutting down system, no more activity reported!"
    rm -f $GRACE_COUNT_FILE
    $SHUTDOWN_CMD;
else
    let COUNT=$COUNT-1
    setCount $COUNT
    [ "$DEBUG" == "on" ] && logDebug "Decrease grace period count to $COUNT"
fi;