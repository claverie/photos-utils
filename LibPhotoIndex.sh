#!/bin/bash 

source $(dirname $0)/LibPhoto.sh

PHOTOS_DB_FILE="$ARCHIVE_DATAS/photos.sqlite"

function createDatabase() {

    [ -f "$PHOTOS_DB_FILE" ] && {
        log "-W" "Database $PHOTOS_DB_FILE already exists"
        return 0
    }

    sqlite3 "$PHOTOS_DB_FILE" <<EOF
create table photoIndex (
    photo       text primary key,
    path        text,
    date        text,
    date_epoch  int,
    title       text,
    author      text,
    description text,
    tags        text
    );
EOF
    status=$?
    prefix="%%"
    [ $status -ne 0 ] && prefix="-I"
    log "$prefix" "Database $PHOTOS_DB_FILE created ($status)"
    return $status

}

function getPhotoInfos() {

    [ ! -n "$1" ] && return 1
    sql="SELECT * FROM photoIndex where photo='"$1"';"
    result=$(sqlite3 "$PHOTOS_DB_FILE" <<< "$sql")
    if [ ! -n "$result" ]; then
    echo -n ""
        return 1
    fi
    echo $(echo "$result" | awk -F'|' '{print "hash%"$1}')
    echo $(echo "$result" | awk -F'|' '{print "rpath%"$2}')
    echo $(echo "$result" | awk -F'|' '{print "date%"$3}')
    echo $(echo "$result" | awk -F'|' '{print "title%"$4}')
    echo $(echo "$result" | awk -F'|' '{print "author%"$5}')
    echo $(echo "$result" | awk -F'|' '{print "description%"$6}')
    echo $(echo "$result" | awk -F'|' '{print "tags%"$7}')
    return 0

}

function addPhoto() {

    local HASH="$1"
    local RPATH="$2"
    local DATE="$3"
    local TITLE="$4"
    local AUTHOR="$5"
    local DESCRIPTION="$6"
    local TAGS=""

    result=$(getPhotoInfos "$HASH")
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        return 1
    fi

    sql="INSERT INTO photoIndex(photo, path, date, date_epoch, title, author, description, tags) VALUES (
    '$HASH',
    '$RPATH',
    '$DATE',
    strftime('%s','$DATE'),
    '$TITLE',
    '$AUTHOR',
    '$DESCRIPTION',
    '$TAGS'
    );"
    sqlite3 "$PHOTOS_DB_FILE" <<< "$sql"
    status=$?
    prefix="--"
    [ $status -ne 0 ] && prefix="-I"
    log $prefix "Add photo [$HASH] $RPATH xxx ($status)"
    return $status

}