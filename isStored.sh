#!/bin/bash

source $(dirname $0)/LibPhotoIndex.sh
source $(dirname $0)/LibPhoto.sh

[ ! -f "$1" ] && {
    echo "** Can't read photo $1."
    exit 1
}


echo "-- Input photo file $1" 
hash=$(getHash "$1")
echo "-- Hash : $hash"
infos=$(getPhotoInfos "$hash")
[ $? -ne 0 ] && {
    echo "** Photo not found."
    return 1
}
echo "-- Photo infos : "
for info in "$infos"; do
    echo "$info" | awk -F% '{printf "    > %20.20s : %s\n", $1, $2 }'
done
exit