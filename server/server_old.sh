#!/bin/bash

##################################################################
# Minecraft Backup Script for Paper
# 2020 Nathan "nwb99"
# MIT
# version 0.1 initial release
##################################################################

# Ensure that the script is not running as root.
if [ $(id -u) -eq 0 ]
then
	echo "Do not run mcbackup as root!"
	exit 1
fi

# Checks for presence of function header to import
if [ -f "functions.sh" ]
then
	. functions.sh
else
	echo "Function header file not found in $PWD. Cannot continue."
	exit 1
fi

# Check that configuration file is present and create one if not.
if [ -f "server.conf" ]
then
	. server.conf
	echo $ENABLED # for debugging
else
	echo -e "No configuration file found. Creating one for you in $PWD.\nPlease edit server.conf to your relevant preferences and set ENABLED=1"
	create_config
	exit 1
fi

# Check if the script is enabled in config or not
if [ "$ENABLED" -eq 0 ]
then	
	echo "Backup script is not enabled in server.conf."
	exit 1
fi 

