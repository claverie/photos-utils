#!/bin/bash

RSYNC_DBG=""
[ ! -z "$DEBUG" ] && {
	set -x
	RSYNC_DBG="--dry-run"
}

LOGFILE="/tmp/rsync.$$.log"

function syncToNas {

    RSYNC_OPT="--verbose --archive --recursive --links --delete "
    RSYNC_SERVER=nas # define in ssh/config
    RSYNC_PATH=/mnt/HD/HD_a2/Backup

    [ -d "$1" ] && {

	rsync $RSYNC_DBG $RSYNC_OPT $2 $1  "$RSYNC_SERVER:$RSYNC_PATH" > $LOGFILE
	echo "--- rsync status = $?"

    }
    
}

syncToNas  /atelier-photo "--exclude lost+found --exclude SAVE"
echo "--- logfile in $LOGFILE"
