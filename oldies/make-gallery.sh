#!/bin/bash 

SOURCE_ROOT_DIR="/atelier-photo/Chronos"
GALLERY_CACHE="/var/cache/txiker-gallery"
GALLERY_OWNER="apache."

DIR_THUMBNAIL=T
DIR_NORMAL=N
DIR_EXIF=E
DIR_ORIGINAL=O


[ `id -u` -ne 0 ] && {
    echo "%% Please run me under root account";
    exit 1;
}

[ ! -r "$SOURCE_ROOT_DIR/." ] && {
    echo "%% Can't access source directory [$SOURCE_ROOT_DIR] ";
    exit 1;
}

[ ! -r "$GALLERY_CACHE/." ] && {
    echo "%% Can't access gallery cache directory [$GALLERY_CACHE] ";
    exit 1;
}

YEAR=""
MONTH=""

[ $# -eq 2 ] && MONTH=$2
[ $# -gt 1 ] && YEAR=$1


function make_thumbnail {

	echo "              > thumbnail"
	[ ! -f "$2" ] && convert -define jpeg:size=400x400 "$1" -thumbnail 200x200^ -gravity center -extent 200x200 "$2"

}

function make_normal {

	echo "              > normal"
	[ ! -f "$2" ] && convert "$1" -resize x800 -strip -interlace line "$2"

}

function make_exif {

	echo "              > exif"
	if [ ! -f "$2" ]; then
 		if [ -f "$1" ]; then
	    		cp "$1" "$2"
		else
	   		exiftool -a -u -json -g1 "$3" > "$2"
		fi
	fi
}

function make_original_link {
        echo "              > original link"
        [ ! -f "$2" ] && ln -s "$1" "$2"
}


function make_cache_content {

    ip=0
    for photo in `ls -1 "$1"`; do
 
        filename="${photo%.*}"

	echo "   -- processing $photo --> $filename.jpg"
	make_thumbnail "$1/$photo" "$2/$DIR_THUMBNAIL/$filename.jpg"
	make_normal "$1/$photo" "$2/$DIR_NORMAL/$filename.jpg"
	make_exif "$1/.exif/$photo.json" "$2/$DIR_EXIF/$filename.jpg.exif" "$1/$photo"
	make_original_link "$1/$photo" "$2/$DIR_ORIGINAL/$photo"
        ip=$[ip + 1]
	
    done
    echo "# $ip photos traitées" > /dev/stderr

}

function make_year_cache {

    echo "$YEAR -- $MONTH"
    [ ! -d "$SOURCE_ROOT_DIR/$YEAR" ] && {
	echo "%% Can't access year directory [$SOURCE_ROOT_DIR/$YEAR] ";
	exit 1
    }
    echo "-- making year cache $GALLERY_CACHE/$YEAR"
    [ ! -d "$GALLERY_CACHE/$YEAR" ] && {
      mkdir "$GALLERY_CACHE/$YEAR"
      chown "$GALLERY_OWNER" "$GALLERY_CACHE/$YEAR"
    }

    mlist="$MONTH"
    [ "$MONTH" = "" ] && mlist=`ls -1  "$SOURCE_ROOT_DIR/$YEAR"`
    
    for month in "$mlist"; do

	if [ ! -d "$SOURCE_ROOT_DIR/$YEAR/$month" ]; then
	    echo "%% skip $SOURCE_ROOT_DIR/$YEAR/$month, not found"
	else 
	    echo "-- making month cache $GALLERY_CACHE/$YEAR/$month"
	    [ ! -d "$GALLERY_CACHE/$YEAR/$month" ] && mkdir "$GALLERY_CACHE/$YEAR/$month"
	    [ ! -d "$GALLERY_CACHE/$YEAR/$month/$DIR_THUMBNAIL" ] && mkdir "$GALLERY_CACHE/$YEAR/$month/$DIR_THUMBNAIL"
	    [ ! -d "$GALLERY_CACHE/$YEAR/$month/$DIR_NORMAL" ] && mkdir "$GALLERY_CACHE/$YEAR/$month/$DIR_NORMAL"
	    [ ! -d "$GALLERY_CACHE/$YEAR/$month/$DIR_EXIF" ] && mkdir "$GALLERY_CACHE/$YEAR/$month/$DIR_EXIF"
	    [ ! -d "$GALLERY_CACHE/$YEAR/$month/$DIR_ORIGINAL" ] && mkdir "$GALLERY_CACHE/$YEAR/$month/$DIR_ORIGINAL"


	    make_cache_content "$SOURCE_ROOT_DIR/$YEAR/$month" "$GALLERY_CACHE/$YEAR/$month"

	    chown -R "$GALLERY_OWNER" "$GALLERY_CACHE/$YEAR/$month"

	fi

    done
    
}

echo "# Traitement de $YEAR $MONTH" > /dev/stderr
make_year_cache $YEAR $MONTH




exit 0

