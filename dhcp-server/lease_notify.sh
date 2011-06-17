#!/bin/bash

# Mandatory configuration:
# The Mac address of the server to wake
HOST_TO_WAKE_MAC="00:33:44:33:44"

# Optional configuration:
# The network interface from which to send the WOL packet 
SENDER_NETWORK_IFC="eth0"

# Which IPs trigger a WOL
IP_REGEX="192\.168\.1\.[0-9]+"

# Load user configuration
if [ -f /etc/default/was ]
then
	. /etc/default/was
fi

# If not using etherwake, set the WOL command to use
WOL_COMMAND="etherwake -i $SENDER_NETWORK_IFC -b $HOST_TO_WAKE_MAC"

COMMAND="$1"
shift
IP="$1"
shift
MAC="$1"

case $COMMAND in
commit)
	logger -p local5.info "commit for IP address $IP, MAC $MAC"

	if [[ $IP =~ $IP_REGEX ]]; then
		logger -p local5.info "Sending WOL paket"
	        `$WOL_COMMAND`
	fi
	;;
release)
	logger -p local5.info "release for IP address $IP, MAC $MAC"
	;;
expiry)
	logger -p local5.info "expiry for IP address $IP"
	;;
*)
	logger -p local5.err "Unknown command for $0!"
	logger -p local5.err "Valid commands are: commit|release|expiry"
	exit 1
esac

