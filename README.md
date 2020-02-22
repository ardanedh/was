# WakeAndSleep

Wake up a specific client using WOL whenever another client requests an IP
address from the DHCP server.

A set of bash scripts, combined with WOL and the ISC DHCP server, to
automatically start a server (providing for example NFS and PVR services)
whenever a client pc is started or a PVR recording is imminent. Shuts down the
server after client disconnects and no immediate recordings are scheduled.

Provides wakeup-/shutdown support for VDR and Tvheadend via ACPI.

## Installation

### Installing DHCP Daemon Hooks

The directory 'dhcp-server' contains all necessary configurations and scripts for the DHCP
Server.

Runtime dependencies:
- etherwake

1. Install 'dhcp-server/dhcpd.conf.local' to the dhcpd configuration directory and include 
   the configuration in the dhcpd.conf or copy the contents of the file directly to the
   dhcpd.conf (not recommended)
2. Install 'dhcp-server/lease_notify.sh' to '/usr/local/sbin/lease_notify.sh'. Check that 
   file is executable.
4. Configure '/etc/default/was', setting 'HOST_TO_WAKE_MAC', 'SENDER_NETWORK_IFC',
   and optionally 'WOL_COMMAND'. (See lease_notify.sh for reference)
3. Restart the dhcp daemon


### Installing shutdown_check.sh

Runtime dependencies:
- nmap
- bash
- cron
- curl (for tvheadend script)

1. Copy `server/etc/shutdown_create` to `/etc/`
2. Enable additional shutdown checks by symlinking available scripts to the 
    enabled directory (example: `cd /etc/shutdown_check/scripts-enabled ; ln -s ../scripts-available/vdr . `)
3. Copy `server/etc/default/shutdown_create` to `/etc/default`
4. Copy contents of directory `server/usr/local/bin/` to `/usr/local/bin/`
5. Configure `shutdown_check` under `/etc/default/shutdown_check`
6. Add `shutdown_check.sh` to cron (Running every x minutes)
7. Optional: configure scripts under `/etc/shutdown_check/<scriptname>.conf`

## Scripts

Available scripts are under `/etc/shutdown_check/scripts-available` and
can be symlinked to the `/etc/shutdown_check/scripts-enabled`

To priorize scripts, the links can be prefixed, for instance:
```
/etc/shutdown_check/scripts-enabled/1_not_between
/etc/shutdown_check/scripts-enabled/2_active_clients
```

### active_clients

Checks for active leases (IP addresses) in a specific net.

### logged_on_users

Checks for logged on users

### rtorrent

Checks if any active downloads remain in the download directory of rtorrent.
If no active downloads are found, rtorrent is terminated.
This script is useful when rtorrent finishes downloads after 
a certain criteria is met (download ratio, file downloaded, ...)

### running_procs

List processes by name in 'running_procs.conf' which prevent shutdown

### screen

Returns the number of active or detached screen sessions, preventing 
shutdown if any sessions exist

### tvheadend

Checks the status of Tvheadend via the status.xml webui.
The script needs a user with web interface and vr access rights defined
in Tvheadend. The username and password must be set in 'tvheadend.conf'

### vdr

Checks the status of the VDR (Video Disk Recorder).
The script needs the path to the svdrpsend script set in 'vdr.conf'
