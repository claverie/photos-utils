#!/usr/bin/env bash

BASEDIR=`dirname $0`

case "$ACTION" in
    init)
	;;
    start)
	;;
    download)
	EXT=${ARGUMENT##*.}
	read YEA MON DAY HOU MIN SEC <<< `exiftool -s -S -d '%Y %m %d %H %M %S' -DateTimeOriginal $ARGUMENT`
	HASH=`exiftool -EXIF:All "$ARGUMENT" | md5sum | sed -e "s/  -//"`
	NFILE="${YEA}${MON}${DAY}${HOU}${MIN}${SEC}-$HASH.$EXT"	
	TARGET_DIR="$PHOTOBASE/$YEA/$MON"
	if [ -f "$TARGET_DIR/$NFILE" ]; then
	    state="PASSED"
	    echo "lib-photo: $ARGUMENT ($YEA-$MON-$DAY $HOU:$MIN.$SEC) déjà récupérée."
	    rm $ARGUMENT
	else
	    state="OK"
	    echo "lib-photo: récupération de $ARGUMENT ($EXT) -> $TARGET_DIR/$NFILE"	    
	    [  ! -d "$TARGET_DIR" ] && {
		echo "lib-photo: création du dossier $TARGET_DIR"
		mkdir -p "$TARGET_DIR"
		[  ! -d "$TARGET_DIR/.exif" ] && mkdir -p "$TARGET_DIR/.exif"
	    }
	    mv "$ARGUMENT" "$TARGET_DIR/$NFILE"
	    # Update Owner
	    if [ "$EXT" != "MOV" ] &&  [ "$EXT" != "MTS"  ]; then
		exiftool -q -overwrite_original -Exif:Artist="$ARTIST" "$TARGET_DIR/$NFILE"
		exiftool -q -g1 -j "$TARGET_DIR/$NFILE" > "$TARGET_DIR/.exif/.$NFILE.exif.json"
	    fi
	fi

	;;
    stop)
    ;;
    *)
esac

exit 0
