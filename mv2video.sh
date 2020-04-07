#!/bin/bash

PHOTO_ROOT=/atelier-photo/Chronos
VIDEO_ROOT=/atelier-photo/Films

LVIDEOS=$(find "$PHOTO_ROOT" -type f \( -iname \*.mts -o -iname \*.mp4 -o -iname \*.avi -o -iname \*.mov \))
for video in $LVIDEOS; do
    fvideo=$(echo $video | sed -e 's,/atelier-photo/Chronos/,,' -e 's,/,_,g')
    echo "$video..."
    mv $video $VIDEO_ROOT/$fvideo
done
