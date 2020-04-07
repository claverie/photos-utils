#!/usr/bin/env bash
#set -x

echo ""

FLICKR_CLI=$(dirname $0)/../flickr-cli/bin/flickr-cli
FLICKR_PREFIX="Chrono/"

PHOTO_ROOT="/atelier-photo/Chronos"

function usage() {
	echo "usage: $0 -y YEAR [-s SUBDIR] [-e SUBDIR] [-r]"
	echo "      -y YEAR   : year directory to upload"
	echo "      -s SUBDIR : limit upload to year subdir YEAR/SUBDIR"
	echo "      -e SUBDIR : exclude subdir SUBDIR from year to upload"
	echo "      -r        : run, by default just try and count photos to upload"
	exit
}

#[ $# -lt 2 ] && usage;

YEAR=""
SUBD=""
EXCLD=""
RUN=0

while getopts "y:s:e:r" option; do
    case "${option}" in
        y)
            YEAR=${OPTARG}
            ;;
	  s)
            SUBD=${OPTARG}
            ;;
        e)
            EXCLD=${OPTARG}
            ;;
        r)
            RUN=1
            ;;
	  	*)
			usage
            ;;
    esac
done

SYNC_ROOT="$PHOTO_ROOT/$YEAR"
[ ! -n "$YEAR" ] || [ ! -d "$SYNC_ROOT" ] && {
	echo "** year $YEAR is invalid ($SYNC_ROOT)"
	echo ""
	usage
}

[ -n "$SUBD" ] && [ -n "$EXCLD" ] && {
	echo "** limit to subdir and exlude subdir are exclusive"
	echo ""
	usage
}
echo "-- Process year $YEAR : $SYNC_ROOT"
[ -n "$SUBD" ] && echo "-- only subdir $SUBD ($SYNC_ROOT/$SUBD)"
[ -n "$EXCLD" ] && echo "-- exclude subdir $EXCLD ($SYNC_ROOT/$EXCLD)"
[ $RUN -eq 0 ] && echo "-- mode test"

all=0
for dm in `ls -1 "$SYNC_ROOT/"`; do
   [ "$EXCD" = "$dm" ] && continue;
   [ "$SUBD" = "" ] || [ "$SUBD" = "$dm" ] && {
	if [ $RUN -eq 1 ]; then
		$FLICKR_CLI upload -s "$FLICKR_PREFIX$YEAR/$dm"  "$SYNC_ROOT/$dm"
	else
		ltotal=$( ls "/atelier-photo/Chronos/$YEAR/$dm" | wc -l )
		all=$(( all + ltotal ))
		echo "($ltotal) ./flickr-cli upload -s \"$FLICKR_PREFIX$YEAR/$dm\"  \"$SYNC_ROOT/$dm\""
	fi
   }
done
echo "-- Count processed : $all"
