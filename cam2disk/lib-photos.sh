[ -n "$DEBUG" ] && set -x

ATELIER="/atelier-photo"
GLIBDIR="$ATELIER/cam2disk"
export PHOTOBASE="$ATELIER/Chronos"
ARTIST="Txiki31 <marc.claverie+txiki31@gmail.com>"

#
# Gphoto2
#
GPHOTO="gphoto2"
HOOK_SCRIPT="$LIBDIR"/gphoto-hook.sh
GPHOTO_OPT="--quiet"



LOGFILE="$GLIBDIR"/cam2disk.log

type "$GPHOTO" > /dev/null 2>&1
[ $? -ne 0 ] && {
    trace "*" "$GPHOTO non trouvé comment voulez-vous que je travaille ?"
    exit 1
}

type exiftool > /dev/null 2>&1
[ $? -ne 0 ] && {
    trace "** exiftool non trouvé comment voulez-vous que je travaille ? "
    exit 1
}


GTMP=/tmp/lib-photo.$$
[ ! -d "$GTMP" ] && mkdir "$GTMP"
echo "lib-photo: Répertoire temporaire $GTMP"

function trace {
    if [ "$1" != "-" ] || [ -n "$VERBOSE" ]; then
	echo "$1 $2"
    fi
    logger -p local7.debug "[$1] $2"
}

function  getFileFromCam {
    $GPHOTO $GPHOTO_OPT -p $1
}

function gDetect {
    $GPHOTO $GPHOTO_OPT -l
    stat=$?
    [ $stat -ne 0 ] && {
	trace "ERR" "Appareil photo non dectecté... [$stat]"
	return 1
	}
    return 0
}

function gListFile {
    # nothing
    $GPHOTO $GPHOTO_OPT --list-files
}

function gGetPhoto {
    OP=`pwd`
    cd "$GTMP"
    [ ! -d stock ] && mkdir stock
    cd stock
    n=$( $GPHOTO $GPHOTO_OPT --list-files | wc -l )
    echo "lib-photo: Récupération de $n photos..."
    $GPHOTO $GPHOTO_OPT --get-all-files --hook-script="$GLIBDIR/gphoto-hook-retrieving.sh"
}
    
echo "gGetPhoto: récupération des photos"
echo "gListFile: liste les photos"
echo "gDetect: vérifie si l'appareil est detecté"
echo "getFileFromCam <FIC>: récupère le fichier <FIC> sur l'appareil"
