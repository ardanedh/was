#!/bin/sh

#
# Configurable part
#

# The IP range to check. Any valid target range supported by nmap
RANGE="192.168.1.0/24"

# Hosts to exclude from counting. Comma separated list of ip addresses
#EXCLUDED_HOSTS="192.168.1.1"

# Grace period after which the shutdown is initiated.
# Allows the active client count to reach zero for the number of times indicated.
GRACE_PERIOD=2

#
# End of Configurable part
# No need to edit below
#

setCount() {
        echo "COUNT=$1" > $GRACE_COUNT_FILE
}

# Filename with the current grace period count
GRACE_COUNT_FILE="/var/run/shutdown_check"

if [ -n "$EXCLUDED_HOSTS" ]; then 
	EXCLUDE="--exclude $EXCLUDED_HOSTS"
fi

ACTIVE_CLIENTS=`nmap -nsP $RANGE $EXCLUDE -oN - | grep "^Host is up" | wc -l`

if [ $ACTIVE_CLIENTS -gt 0 ]; then
    if [ -f "$GRACE_COUNT_FILE" ]; then
        rm $GRACE_COUNT_FILE
    fi
else
    if [ ! -f "$GRACE_COUNT_FILE" ]; then
        setCount $GRACE_PERIOD
    fi
    . $GRACE_COUNT_FILE
    if [ $COUNT -le 0 ]; then
	
	#TODO check other scripts
	logger -p local5.info "Shutting down system, no active clients or services detected!"
	rm -f $GRACE_COUNT_FILE
        shutdown -h now;
    else
        let COUNT=$COUNT-1
        setCount $COUNT
    fi;
fi

