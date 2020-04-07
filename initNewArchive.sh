#!/bin/bash

source $(dirname $0)/LibPhotoIndex.sh
source $(dirname $0)/LibPhoto.sh

ANALYSE="${ANALYSE:-}"

photo_processed=0
photo_already_processed=0
photo_count=0
declare -A photos_by_year
declare -A extensions
photo_current=""

function error() {
    local parent_lineno="$1"
    local message="$2"
    local code="${3:-1}"
    if [[ -n "$message" ]]; then
        echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
    else
        echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
    fi
    set +x
    exit "${code}"
}
trap 'error ${LINENO}' ERR

function on_abort() {
    set +x
    echo ""
    [ "$photo_current" != "" ] && {
        echo "Aborting on $photo_current...."
        echo ""
    }
    echo "Bilan "
    echo " - traitée            : $photo_processed"
    echo " - déjà traité        : $photo_already_processed"
    echo " - total              : $photo_count"
    echo ""
    echo "Photos par année : "
    for year in "${!photos_by_year[@]}"; do
        echo " - $year : ${photos_by_year[$year]} "
    done
    echo ""
    echo "Par extensions : "
    for extension in "${!extensions[@]}"; do
        echo " - $extension : ${extensions[$extension]} "
    done
    echo ""
    echo "See log $LOG"
    echo ""
    exit
}

trap on_abort SIGINT

createDatabase

for current_year in $(ls -1 "$OLD_CHRONO"); do
    if [ "$current_year" != "$YEAR" ] && [ "$YEAR" != "" ]; then
        continue
    fi
    year_count=0
    rg=0
    echo "Searching photos on $OLD_CHRONO/$current_year ..."
    PHOTO_LIST=$(find "$OLD_CHRONO/$current_year/" -type f -print0 | xargs -0 ls)
    echo -n "Processing : x"
    for pfilename in $PHOTO_LIST; do
        year_count=$((year_count + 1))
        case $rg in
        1)
            prefix='\'
            rg=2
            ;;
        2)
            prefix='|'
            rg=3
            ;;
        3)
            prefix='/'
            rg=0
            ;;
        *)
            prefix='-'
            rg=1
            ;;
        esac
        echo -n -e "\033[2K\r[$prefix] ($year_count) Processing ${pfilename}"

        photo_current="$pfilename"
        pfilename_proc=$(echo "$pfilename" | sed -e 's/ /_/g')
        extension=$(echo "${pfilename_proc##*.}" | tr '[:upper:]' '[:lower:]')

        if [[ "$extension" =~ ^(zou|jpg|jpeg|png|dng)$ ]]; then
            base_dir="$ARCHIVE_CHRONO"
        else
            base_dir="$ARCHIVE_RAW"
        fi

        # Get EXIF date
        year="$current_year"
        month=""
        trap '' ERR
        date=$(getExifDate "$pfilename")
        fulltime="$date"
        status=$?
        log "%%" "${LINENO} status=$status date=$date"
        if [[ $status -ne 0 || "$date" =~ ^(19|20)[0-9]{2}(:|-)[0-9]{2}(:|-)[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}.*$ ]]; then
            year=$(date +%Y -d "$date")
            month=$(date +%m -d "$date")
        fi
        trap 'error ${LINENO}' ERR
        if [ "$month" == "" ]; then
            year=$(echo "$pfilename_proc" | awk -F/ '{print $4'})
            tmp=$(echo "$pfilename_proc" | awk -F/ '{print $5'})
            if [ "$tmp" != "$(basename "$pfilename_proc")" ]; then
                month="$tmp"
            else
                month="12"
            fi
            fulltime="$year-$month-31 12:00:00"
            log "-D" "[$pfilename] invalid exif date ($date), use year $year month $month"
        fi
        hash=$(getHash "$pfilename")
        new_dir="$base_dir/$year/$month"
        new_file="$new_dir/$hash.$extension"
        str="$pfilename [$fulltime] [$hash] [$extension] > $new_file : "
        if [ "${photos_by_year["$year"]}" == "" ]; then
            photos_by_year["$year"]=1
        else
            photos_by_year["$year"]=$((${photos_by_year["$year"]} + 1))
        fi

        # Photo processing
        if [ -f "$new_file" ]; then
            log "-=" "$str already published."
            photo_already_processed=$(($photo_already_processed + 1))
        else
            [ -n "$RUN" ] && {
                [ ! -d "$new_dir" ] && mkdir -p "$new_dir"
                cp -p "$pfilename" "$new_file"
            }
            photo_processed=$(($photo_processed + 1))
            log "--" "$str OK."
        fi

        # Add to index
        trap '' ERR
        addPhoto "$hash" "$year/$month/$hash.$extension" "$fulltime" "(empty) title for $hash" "Marc C. <marc.claverie@gmail.com>" "" ""
        trap 'error ${LINENO}' ERR

        # Count extensions
        if [ "${extensions["$extension"]}" != "" ]; then
            extensions["$extension"]=$((${extensions["$extension"]} + 1))
        else
            extensions["$extension"]=1
        fi
        photo_count=$(($photo_count + 1))
    done
    echo -n -e "\033[2K\rYear count : $year_count"
    echo ""
    echo "--"
done
photo_current=""
on_abort
