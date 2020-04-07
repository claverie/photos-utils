#!/bin/bash

source `dirname $0`/LibPhoto.sh

echo -n "$1 : "
[ -f "$1" ] && {
    echo $(getExifDate "$1")
    exit 0
}
echo " No file"
exit 1

