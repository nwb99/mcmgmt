#!/bin/bash

#====================================================
# MCMgmt for Paper
# (c) Nathan "nwb99" Barnett, see LICENSE
# version 0.2.0
# Full Backup
#
# This script stops Paper and runs a backup
#
#
#====================================================

STARTSCRIPT=startpaper.sh
SCREENNAME=mc
PAPERDIR=
SERVERROOT=
DAYSDELETE=
PIGZCORES=
LOGFILE=${SERVERROOT}/${PAPERDIR}/logs/latest.log
BACKUPDIR=

# Check if the script is being run as root
if [ $(id -u) -eq 0 ]
then
	echo "Do not run this script as root!"
	exit 1
fi

# Check that the backup directory exists and has write permissions, else create it.
if [ ! -d "$BACKUPDIR" ]
then
	if mkdir -p "$BACKUPDIR"
	then
		echo "$BACKUPDIR has been created for you."
	else
		echo "Insufficient permissions or another error occurred when attempting to create $BACKUPDIR."
		exit 1
	fi
fi

if ! [ -w "$BACKUPDIR" ]
then
	echo "MCMgmt Backup has insufficient permissions to write to $BACKUPDIR."
	exit 1
fi

#####################################################
read_log() {											#come up with a better way to check logs
	tail -F -n0 -s 0.1 $LOGFILE | grep -q -m1 "$1"		# This does not return any strings. It only returns an error code.
}

screen_say() {
	screen_command "say §c[$(date +%H:%M:%S)] §7$1"
}

screen_command() {
	screen -S $SCREENNAME -p 0 -X stuff "$1^M"
}

screen_saveall() {
	screen_command "save-all flush"
	if read_log "Saved the game"
	then
		echo "Flushed save data to disk."
		return 0
	else
		echo "Game couldn't be saved. Aborting."
		screen_say "Aborting."
		exit 1
	fi
}

stoppaper() {
	screen_command "stop"
	if read_log "INFO]: Closing Server"	
	then
		sleep 5
		echo "Paper has been stopped."
		return 0
	fi
}

fullbackup() {
	local TARBALL="papermc-full-$(date +%d%b%Y-%H%M).tar.gz"
	tar -cf - -C $SERVERROOT $PAPERDIR/ | pigz -c${COMPRESSION}p $PIGZCORES > $BACKUPDIR/$TARBALL
}

countdown() {
	declare -a COUNTTIME=("120" "90" "60" "30")		# think about why this has to be 30 second intervals. change as you please.
	for i in "${COUNTTIME[@]}"
	do
		screen_say "Server will shutdown in $i seconds for full backup."
		sleep 30
	done
}

players_online() {
	screen_command "list"
	if [ $(tail -F -n0 -s 0.1 $LOGFILE | grep -m1 "INFO]: There are" | cut -d ' ' -f 6) -ge 1 ]
	then
		countdown
	fi
}

prune_backups() {
	echo "Pruning any backups older than $DAYSDELETE days old."
	find $BACKUPDIR -maxdepth 1 -name "papermc-*.tar.gz" -mtime +$DAYSDELETE -delete
}

#####################################################
# Check to see if Paper is running.

prune_backups

if ! pgrep -x $STARTSCRIPT > /dev/null
then
	echo "Paper isn't running."
	if fullbackup
	then
		echo "Archiving was successful."
		echo "Backup complete."
		exit 0
	else
		echo "Backup failed."
		exit 1
	fi
else
	players_online
	screen_say "Server is stopping."
	sleep 2
	screen_saveall
	sleep 5	
	stoppaper
	if fullbackup
	then
		echo "Archiving was successful."
		echo "Backup complete."
		exit 0
	else
		echo "Backup failed."
		exit 1
	fi
	exit 0
fi
