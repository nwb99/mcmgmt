# **MCMgmt**
### Yet another Paper server management tool.

These scripts are intended to run under anacron on Debian and
have not been tested on any other distribution.
I have only tested these scripts with bash, and as such I only
support bash.

*I can vet for these scripts. They have already saved my tail from an error on my part when moving to a new server. I ended up with data loss.*

Packages needed: pigz, screen, tar

>These scripts do not work properly with systemd timers. I look to fix this in the future. If you know of a fix, please file a bug with a full explanation of your proposed fix.

>This is my entry into learning bash scripting and automation, so please bear with me. Please file bug reports on anything that can be improved.

## backup.sh
>This script checks if players are online (not if -f flag is given) and performs a backup of the world directories listed in the WORLDS array at the top of the script. It also prunes old backups automatically using the find command. *Note: If you specify 2 days to keeps, for example, it won't delete until day 3.*

## fullbackup.sh
>This script checks if Paper is running. If it is, it will check if players are online. If there are players, it will start a 2 minute countdown, sending chat messages every 30 seconds to players of the impending shutdown of the server. It will then shutdown Paper and back up the entire server directory, including all plugins, logs, configuration files, etc. If Paper is not running, it will simply run the back up. *Note: This script does not automatically startup Paper after the backup. You must specify that in cron after an &&. For example: /home/minecraft/backup.sh && /home/minecraft/startpaper.sh
