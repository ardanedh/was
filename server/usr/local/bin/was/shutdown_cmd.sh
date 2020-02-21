#!/bin/bash
SHUTDOWN_CMD="/sbin/shutdown -h now"

sudo service docker stop
eval $SHUTDOWN_CMD;
