#!/bin/bash

[ ! -n "$LEVEL" ] && LEVEL=""

OLD_CHRONO="/atelier-photo/Chronos"
ARCHIVE_ROOT="/atelier-photo/Archives"
ARCHIVE_CHRONO="$ARCHIVE_ROOT/Chronos"
ARCHIVE_RAW="$ARCHIVE_ROOT/Raw"
ARCHIVE_DATAS="$ARCHIVE_ROOT/Datas"

[ ! -f "$ARCHIVE_ROOT" ] && mkdir -p "$ARCHIVE_ROOT"
[ ! -f "$ARCHIVE_DATAS" ] && mkdir -p "$ARCHIVE_DATAS"


LOG="${0%.*}.log"
[ -f "$LOG" ] && mv "$LOG" "$LOG.old"
echo "%% Start at $(date)" 1>&2 1>"$LOG"

function log() {
    prefix=" "
    [ -n "$RUN" ] && prefix=" TRY "
    echo "$1$prefix$2 " 1>&2 1>>"$LOG"
}

[ -n "$RUN" ] && echo "-- Try mode " 1>&2 1>>"$LOG"

function getFormattedDate() {
    [ -n "$DEBUG" ] && echo -n "exiftool -b -$2  \"$1 :" >>trace
    eDate=$(exiftool -b -$2 "$1" 2>/dev/null)
    status=$?
     [ -n "$DEBUG" ] && echo $eDate >>trace
     [[ $status -eq 0 && "$eDate" =~ ^(19|20)[0-9]{2}(:|-)[0-9]{2}(:|-)[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}.*$ ]] && {
        echo -n "$eDate" | sed -e's, ,:,g' | awk -F: '{print $1"-"$2"-"$3" "$4":"$5":"$6}'
        return 0
    }
    [ -n "$DEBUG" ] && echo "**no date**" >> trace
    return 1
}

function getExifDate() {
    [ -n "$DEBUG" ] && echo "--" >>trace
    getFormattedDate "$1" "DateTimeOriginal"
    [ $? -ne 0 ] && {
        getFormattedDate "$1" "createdate"
        [ $? -ne 0 ] && {
            getFormattedDate "$1" "FileModifyDate"
            return $?
        }
    }
    return 0
}

function getHash() {
    [ -f "$1" ] && {
        hash=$(md5sum -b "$1" | awk '{print $1}')
        echo -n "$hash"
        return 0
    }
    return 1
}
