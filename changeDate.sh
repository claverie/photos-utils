#!/bin/bash


#-D [/atelier-photo/Chronos/1999/1999-12-002.jpg] no date in exif, use year 1999 month 00
#-D [/atelier-photo/Chronos/1999/1999-12-001.jpg] no date in exif, use year 1999 month 00
COMMAND="./change-date-runme.sh"
echo "Filtering..."
processing=$(cat initNewArchive.log | grep '^-D' | grep -iv '.nef' | grep -iv '.raw' | sed -e 's,^.* \[\(.*\)\] .* year \(.*\) month \([0-9][0-9]\).*$,\1|\2|\3,')
ccp=0
echo "Processing..."
echo '#!/bin/bash' > "$COMMAND"
for datas in $processing; do

    file=$(echo "$datas" | awk -F'|' '{print $1}' )
    year=$(echo "$datas" | awk -F'|' '{print $2}' )
    month=$(echo "$datas" | awk -F'|' '{print $3}' )

    echo "exiftool -xmp:dateTimeOriginal=\"$year:$month:31 12:00:00\" $file" >> "$COMMAND"
    
    ccp=$(($ccp+1))
done
echo "Nombre > $ccp"
chmod +x "$COMMAND"
echo "Run $COMMAND to change dates"