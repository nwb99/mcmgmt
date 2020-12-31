#!/bin/bash

# Define functions
create_config () {
	cat > server.conf <<-EOF
	# Configuration for MCMgmt
	
	ENABLED=0
	SERVER_DIR=""
	SERVER_JAR=""
	
	TMUXSESN=""
	
	LOGFILE="mcmgmt.log"

	JVM_MINMEM="1024M"
	JVM_MAXMEM="6144M"

	WORLDS=(world world_nether world_the_end)	 # array of world directories
	EOF
}

log () {
	CURTIME="[$(date +%Y-%m-%d.%H:%M:%S)]"
	echo -e "$CURTIME $1" | tee -a $LOGFILE		
}

is_server_running () {
	

#################################################

# Check for existence of configuration
if [ -f "server.conf" ]
then
	. server.conf
else
	echo -e "Could not find a configuration. Creating one for you.\nEdit the generated configuration with appropriate values and set ENABLED=1" 
	create_config
	exit 1
fi


