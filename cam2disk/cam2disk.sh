#!/usr/bin/env bash 
#set -x

ME=`realpath $0`
INSTALL_DIR=`dirname $ME`
. $INSTALL_DIR/lib-photos.sh

[ -n "$DEBUG" ] && set -x

function usage {
    echo " $0 [<files ids>]"
    echo "        Si <file ids> n'est pas positionné => toutes les photos"
    echo "        file = X : récupère la photo X (camera index => gphoto2 -L )"
    echo "        file = X-Y : récupère les photos de X à Y (camera index => gphoto2 -L )"
}

trace "--" "Checkinf for $GPHOTO"

if [ ! -n "$1" ]; then
    gGetPhoto 
else
    getFileFromCam "$1"
fi
