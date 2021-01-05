#!/bin/bash

#====================================================
# MCMgmt for Paper
# (c) Nathan "nwb99" Barnett, see LICENSE
# version 0.1.1
#
#
#
#
#
#====================================================

WORLDS=(world world_nether world_the_end)
STARTSCRIPT=startpaper.sh
PAPERDIR=paper
SERVERROOT=/mc
BACKUPDIR=/home/minecraft
SCREENNAME=mc
LOGFILE=${SERVERROOT}/${PAPERDIR}/logs/latest.log

if [ ! -d $SERVERROOT/$PAPERDIR/ ]
then
	echo "Server directory does not exist."
	exit 1
fi

# Check that backup directory has at least RWX permissions for the directory owner.
if [ "$(stat -c "%a" "$BACKUPDIR")" -lt "700" ]
then
	echo -e "Directory $BACKUPDIR does not have the proper permissions!\nEnsure that the directory has at least permissions of 700 or dwrx------"

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
	screen_command "say $1"
}

online_backup() {
	TARBALL="papermc-$(pgrep -a java | cut -d ' ' -f 6 | cut -c 7-9)-worlds-$(date +%d%b%Y-%H%M).tar.gz"
	tar -cf - -C $SERVERROOT/$PAPERDIR ${WORLDS[*]} | pigz -c6p 2 > $BACKUPDIR/$TARBALL
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

is_running
players_online

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
