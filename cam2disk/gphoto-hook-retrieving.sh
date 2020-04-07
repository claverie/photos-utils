#!/usr/bin/env bash

BASEDIR=`dirname $0`
#_LIB=`basename $0`
_LIB='(hook)'

case "$ACTION" in

  init)
	;;

  start)
	;;

  download)
  [ -n "$DEBUG" ]  &&  echo "${_LIB}% ARGUMENT      :   $ARGUMENT"
  EXT=${ARGUMENT##*.}
  #exiftool -s -S -d '%Y %m %d %H %M %S' -DateTimeOriginal $ARGUMENT
	read YEA MON DAY HOU MIN SEC <<< `exiftool -s -S -d '%Y %m %d %H %M %S' -DateTimeOriginal $ARGUMENT`
  [ "$YEA" == "" ] && read YEA MON DAY HOU MIN SEC <<< `exiftool -s -S -d '%Y %m %d %H %M %S' -FileModifyDate $ARGUMENT`
	AllExif=`exiftool -EXIF:All "$ARGUMENT"`
  [ "$AllExif" == "" ] && AllExif=`exiftool "$ARGUMENT"`
  HASH=`echo "$AllExif" | md5sum | sed -e "s/  -//"`
	NFILE="${YEA}${MON}${DAY}${HOU}${MIN}${SEC}-$HASH.$EXT"
  _lname="${YEA}${MON}${DAY}${HOU}${MIN}${SEC}....$EXT"

	TARGET_DIR="$PHOTOBASE/$YEA/$MON"
  [ -n "$DEBUG" ]  && {
      echo "${_LIB}% NFILE      :   $NFILE"
      echo "${_LIB}% TARGET_DIR : $NFILE"
  }
	if [ -f "$TARGET_DIR/$NFILE" ]; then
	    state="PASSED"
	    echo "${_LIB}: $ARGUMENT ($YEA-$MON-$DAY $HOU:$MIN.$SEC) déjà récupérée."
      rm "$ARGUMENT"
	else
	    state="OK"
	    echo "${_LIB}: $ARGUMENT ($EXT) -> $_lname"
	    [  ! -d "$TARGET_DIR" ] && {
		      echo "${_LIB}: création du dossier $TARGET_DIR/.exif"
		      [ ! -n "$DEBUG" ]  && mkdir -p "$TARGET_DIR/.exif"
	    }
      [ -n "$DEBUG" ]  && echo "${_LIB}% mv $ARGUMENT" "$TARGET_DIR/$NFILE"
	    [ ! -n "$DEBUG" ]  && mv "$ARGUMENT" "$TARGET_DIR/$NFILE"
	    # Update Owner
	    if [ "$EXT" != "MOV" ] &&  [ "$EXT" != "MTS"  ]; then
		      [ -n "$DEBUG" ] && echo "${_LIB}% exiftool -q -overwrite_original -Exif:Artist=$ARTIST  $TARGET_DIR/$NFILE"
    		  [ ! -n "$DEBUG" ] && exiftool -q -overwrite_original -Exif:Artist="$ARTIST"  "$TARGET_DIR/$NFILE"
          [ -n "$DEBUG" ] && echo "${_LIB}% exiftool -q -g1 -j $TARGET_DIR/$NFILE > $TARGET_DIR/.exif/.$NFILE.exif.json"
          [ ! -n "$DEBUG" ] && exiftool -q -g1 -j "$TARGET_DIR/$NFILE" > "$TARGET_DIR/.exif/.$NFILE.exif.json"
	    fi
	fi

	;;
    stop)
    ;;
    *)
esac

exit 0
