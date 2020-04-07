#!/bin/bash

BASE_DIR="/atelier-photo/Archives/Raw"
NEW_DIR="/atelier-photo/Archives/Chronos"

EXTENSIONS_INPUT="rw2 nef dng raw"

EXTENSION_OUT=jpeg
UFRAW_OPTIONS=" --lensfun=none --out-type=jpeg " #"--out-depth=16 --compression=95 --out-type=jpeg"

for extension in $EXTENSIONS_INPUT; do

   lsource=$(find "$BASE_DIR" -iname \*.$extension)
   IR=0
   for stfile in ${lsource[@]}; do
      sfile=$(realpath $stfile)
      IR=$(($IR+1))
      bdir=$(echo `dirname "$sfile"` | sed -e 's,$BASE_DIR,$NEW_DIR,')
      bfile=$(basename "${sfile%.*}")
      ofile="$bdir/$bfile.$EXTENSION_OUT"
      if [ ! -f $ofile ]; then
         echo "($IR)  $sfile --> $ofile" 
         ufraw-batch --overwrite --silent --rotate=no $UFRAW_OPTIONS --output="$ofile" "$sfile" 
      fi
      
   done

done
exit
