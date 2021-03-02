#!/bin/bash

#====================================================
# MCMgmt for Paper
# (c) Nathan "nwb99" Barnett, see LICENSE
# version 0.1.3dev3
#
#
#
#
#
#====================================================

WORLDS=(world world_nether world_the_end)	# Array of world directories to back up.
STARTSCRIPT=startpaper.sh				# Paper start script. Used to check if Paper is running.
PAPERDIR=paper							# No trailing /
SERVERROOT=/mc							# No trailing /
BACKUPDIR=/hdd/paper_backup				# No trailing /
SCREENNAME=mc
DAYSDELETE=3							# Number of days to keep backups. (Ex: 3 keeps until day 4!)
PIGZCORES=4								# Set the number of CPU cores to use for compression
LOGFILE=${SERVERROOT}/${PAPERDIR}/logs/latest.log

VER='0.1.3dev3'

if [ $(id -u) -eq 0 ]					# check that we aren't running as root.	
then
	echo "Do not run this script as root!"
	exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
	cat<<-EOF
	MCMgmt for Paper Online Backup $VER
	
	-h, --help		Displays this help
	-f			Forces backup even if no players are online
	EOF
	exit 0
fi

if [ ! -d $SERVERROOT/$PAPERDIR/ ]
then
	echo "Server directory does not exist."
	exit 1
fi

if ! [ -w "$BACKUPDIR" ]
then
	echo "MCMgmt Backup has insufficient permissions to write to $BACKUPDIR."
fi


is_running() {
	if ! pgrep -x $STARTSCRIPT > /dev/null
	then
		echo "Paper isn't running."
		exit 1
	fi
}

screen_command() {
	screen -S $SCREENNAME -p 0 -X stuff "$1^M"
}

read_log() {
	tail -F -n0 -s 0.1 $LOGFILE | grep -q -m1 "$1"		# This does not return any strings. It only returns an error code.
}


screen_saveoff() {
	screen_command "save-off"
	read_log "Automatic saving is now disabled"
}

screen_saveall() {
	screen_command "save-all flush"
	if read_log "Saved the game"
	then
		sleep 5
		return 0
	else
		return 1
	fi
}

screen_saveon() {
	screen_command "save-on"
	read_log "Automatic saving is now enabled"
}

screen_say() {
	screen_command "say §c[$(date +%H:%M:%S)] §7$1"
}

online_backup() {
	TARBALL="papermc-$(pgrep -a java | egrep -o 'paper-[0-9]+' | egrep -o '[0-9]+')-worlds-$(date +%d%b%Y-%H%M).tar.gz"
	tar -cf - -C $SERVERROOT/$PAPERDIR ${WORLDS[*]} | pigz -c6p $PIGZCORES > $BACKUPDIR/$TARBALL
}

players_online() {
	screen_command "list"
	if [ $(tail -F -n0 -s 0.1 $LOGFILE | grep -m1 "INFO]: There are" | cut -d ' ' -f 6) -ge 1 ]
	then
		return 0
	else
		echo "No players are online. No backup will be made."
		exit 1
	fi
}

prune_backups() {
	echo "Pruning any backups older than $DAYSDELETE days old."
	find $BACKUPDIR -maxdepth 1 -name "papermc-*.tar.gz" -mtime +$DAYSDELETE -delete
}

is_running
if ! [ "$1" = "-f" ]
then
	players_online
fi
prune_backups

screen_command "save-on"	# keeps tail from hanging if save was already off.

if screen_saveoff
then
	echo "Automatic saving disabled."
	screen_say "Preparing to backup worlds..."
	if read_log "Preparing to backup worlds..."
	then
		:
	fi
else
	echo "Automatic saving could not be disabled. Aborting."
	screen_saveon
	exit 1
fi

if screen_saveall
then
	echo "Flushed save data to disk."
	screen_say "Running backup. Please excuse any lag."
	read_log "Running backup. Please excuse any lag."
	echo "Archiving and compressing worlds to tarball in $BACKUPDIR/"
fi

if online_backup
then
	echo "Archiving was successful."	
else
	echo "Backup failed."
	screen_saveon
	[ -f $BACKUPDIR/$TARBALL ] && rm $BACKUPDIR/$TARBALL
	exit 1
fi

if screen_saveon
then
	echo "Automatic saving enabled."
	screen_say "Backup complete."
	if read_log "Backup complete."
	then
		exit 0
	fi
fi
