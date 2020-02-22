#!/bin/bash

export WAS_BASE_DIR=${WAS_BASE_DIR:=/etc/shutdown_check}
export WAS_DEFAULT_CONF=${WAS_DEFAULT_CONF:=/etc/default/shutdown_check}

# Source logger functions
. $WAS_BASE_DIR/logger-functions

# Directory where shutdown check scripts are located
#   Each script in the directory is run and the exit code evaluated
#   Exit code = 0  : the check allows shutdown
#   Exit code <> 0 : the check does not allow shutdown
CHECK_SCRIPT_DIR="$WAS_BASE_DIR/scripts-enabled"

# Load user configuration
[ -f "$WAS_DEFAULT_CONF" ] && . $WAS_DEFAULT_CONF

[ "$DEBUG" == "on" ] && logDebug "Starting shutdown checks"
for script in `ls $CHECK_SCRIPT_DIR`; do
    $CHECK_SCRIPT_DIR/$script
    if [ $? -ne 0 ]; then
        logInfo "Script '`basename $script`' reports system still in usage. Not shutting down!"
        exit 0;
    fi
done

logInfo "Scripts gave clearance for shutdown"
logInfo "Shutting down system, no more activity reported!"

$SHUTDOWN_CMD;
