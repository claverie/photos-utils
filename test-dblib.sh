#!/bin/bash 

source $(dirname $0)/LibPhotoIndex.sh

PHOTOS_DB_FILE="$ARCHIVE_DATAS/test.photos.sqlite"
rm "$PHOTOS_DB_FILE"

createDatabase
echo "Create DB $PHOTOS_DB_FILE : $?"

addPhoto "87686Z8E8E6-$$" "2009/12/toto-$$.jpg" "2009-12-09 12:09:56" "Title for toto.jpg" "Marc C. <marc.claverie@gmail.com>" "" ""
echo "Add photo  : $?"
addPhoto "87686Z8E8E6-$$" "2009/12/toto-$$.jpg" "2009-12-09 12:09:56" "Title for toto.jpg" "Marc C. <marc.claverie@gmail.com>" "" ""
echo "Add photo  : $?"

result=$(getPhotoInfos "87686Z8E8E6-$$")
echo "getPhotoInfo("87686Z8E8E6-$$") : $? [$result]"

result=$(getPhotoInfos "nonexistant-$$")
echo "getPhotoInfo("nonexistant-$$") : $? [$result]"


