#!/bin/bash

# Contains functions sourced into server.sh
# MIT

create_config () {
	cat > server.conf <<-EOF
	# Paper Configuration File for The Rice Fields
	# MIT
	
	ENABLED=0
	SERVER_DIR=""
	SERVER_JAR=""
	
	CONFDIR=""

	TMUXSESN=""
	
	LOGFILE=""

	JRE="java"
	JVM_ARGS="-Xms1024M -Xmx2560M"


	WORLDS=(world world_nether world_the_end)	 # array of world directories
	CO_DB="database.db"
	EOF
}

log () {
	CURTIME="[$(date +%Y-%m-%d.%H:%M:%S)]"
	echo -e "$CURTIME $1" | tee -a $LOGFILE		
}
	
