#!/bin/bash

[ ! -z "$DEBUG" ] && set -x

_IEXTENSION=(jpg png)
_RECURSE=0
_OUTDIR=/var/cache/make-index
PUBDIR="$_OUTDIR"
_LOCALDIR=`pwd`

IDX_BACK="black"
IDX_FRONT="white"
IDX_FILE="index"
IDX_TITLE="Index"

THU_RATIO="3/2"
THU_DPY="300"
IMG_PATH="."
IMG_LIST=()

# Index layout dimension (cm)
LAY_WIDTH=20
LAY_HEIGHT=27

# Index line / row count
IDX_ROW_COUNT=5
IDX_LINE_COUNT=9
THUMB_COUNT=$(( IDX_ROW_COUNT * IDX_LINE_COUNT ))


# 35mm en 300 dpi =>  environ 400 px
RATIO=`bc -l <<< "scale=2; "$THU_RATIO `
RES=$THU_DPY
Wpx=`bc -l <<< "scale=0; ${RES} / 2.54 * 3.5"`
Hpx=`bc -l <<< "scale=0; ${Wpx} / ${RATIO} "`

function wlog() {
  logger -p info.notice $*
}


function makeDir() {
    [ ! -d "$1" ] && {
      mkdir -p "$1"
      [ $? -ne 0 ] && {
        echo "** I can't create directory $1/thumbs."
        exit
      }
    }
}

function cleanWorkDir() {
    (cd "$1" && rm -f *)
}

function makePseudoThumb() {
  Hc=`bc -l <<< "scale=0; ${Hpx} + 30 "`
  #convert -size ${Wpx}x${Hc} xc:${IDX_FRONT} $1
  convert -size ${Wpx}x${Hc} xc:'#DDD' $1
}

function makeLayout() {

  _lw=`bc -l <<< "scale=0; ${LAY_WIDTH} * ${THU_DPY} / 2.54"`
  _lh=`bc -l <<< "scale=0; ${LAY_HEIGHT} * ${THU_DPY} / 2.54"`

  echo "-- layout [${LAY_WIDTH}x${LAY_HEIGHT}] -> "[${_lw}x${_lh}]

  convert -size ${_lw}x${_lh} xc:${IDX_FRONT} \
  -stroke '#AAA' \
  -draw "line   250,200,2300,200"  \
  -draw "line   250,250,2300,250"  \
  -draw "line   250,300,2300,300"  \
  ${_OUTDIR}/thumbs/base.layout.jpg

}

function mergeLayoutIndex() {
  convert ${_OUTDIR}/thumbs/base.layout.jpg   \
    -fill ${IDX_BACK} \
    -pointsize 80 -gravity NorthEast -annotate +50+50 "$3" \
    -pointsize 40 -gravity NorthEast -annotate +50+150 "$4" \
    "${_OUTDIR}/thumbs/layout.jpg"
  convert "${_OUTDIR}/thumbs/layout.jpg" \
          -gravity SouthEast   "$1"  -compose Multiply -geometry +50+50 -composite \
          "$2"
  rm "${_OUTDIR}/thumbs/layout.jpg"
}

function cropImage() {

  f=$(basename "$1")
  e="${f##*.}"
  f="${f%.*}"

  idate=`identify -format "%[EXIF:DateTimeOriginal]" "$1"`
  Wdim=`identify -format "%[fx:w]" "$1"`
  Hdim=`identify -format "%[fx:h]" "$1"`

  SCALE="${Wpx}x"
  ROTATE=""
  RANGLE=""
  [ ${Wdim} -lt ${Hdim} ] && {
	   ROTATE=-rotate
     RANGLE=-90
  }
  Hc=`bc -l <<< "scale=0; ${Hpx} + 30 "`

  convert  "$1" \
	   $ROTATE $RANGLE\
	  -resize ${SCALE}  \
	  -size ${Wpx}x${Hc} xc:${IDX_BACK} +swap -gravity North -composite  \
	  -strip  \
	  "$_OUTDIR/thumbs/t.jpg"

  convert \
	   -background ${IDX_BACK} -fill white -size ${Wpx}x30 \
     -font "courier" -pointsize 24 \
     caption:"[$2]${f}"  \
     "$_OUTDIR/thumbs/t.jpg"  +swap -gravity SouthEast -composite \
     "$_OUTDIR/thumbs/c.$2.jpg"

  rm "$_OUTDIR/thumbs/t.jpg"

}

function makeIndex() {
    l=`ls $1/thumbs/c.*.jpg`
    #montage -background ${BACK} -geometry +4+4 $l $_OUTDIR/m.png
    rg=`printf "%05d" $2`
    tIFile="${_OUTDIR}/t.${IDX_FILE}-"$rg".jpg"
    IFile="${PUBDIR}/${IDX_FILE}-"$rg".jpg"
    echo -n " > building Index $2 / $3 ($IFile)"
    montage -tile 5x12 -background white -geometry +1+1 $l jpg:-  > "$tIFile"
    rm $1/thumbs/c.*.jpg
    mergeLayoutIndex "$tIFile" "$IFile" "$IDX_TITLE" "[Index $2 / $3 ]"
    rm "$tIFile"
    echo
}

function findImages() {
  _filter=""
  for e in ${_IEXTENSION[@]}; do
    if [ $_RECURSE == 1 ]; then
      _filter=$_filter'\|'$e'\|'${e^^}
    else
      _filter=$_filter' "'$IMG_PATH'/*.'$e'" "'$IMG_PATH'/*.'${e^^}'"'
    fi
  done
  if [ $_RECURSE == 1 ]; then
    IMG_LIST=(`find "$IMG_PATH" -regex  ".*\.\($_filter\)$" -print | sort`)
  else
    IMG_LIST=(`ls $_filter`)
  fi
}

function usage() {
  echo "Usage: $0 -p [path] -d resolution -r ratio "
  echo "         -p     : directory path that contains images [default .]"
  echo "         -I     : directory to publish indexes [default $_OUTDIR]"
  echo "         -r     : set thumbnails height/width ratio [3/2]"
  echo "         -d     : set thumbnails resolution [300]"
  echo "         -T     : set index title [Index]"
  echo "         -F     : set index base filename [index]"
  echo "         -R     : recurse"
  exit
}

while getopts ":r:p:d:F:I:T:R" o; do
    case "${o}" in
        r) THU_RATIO=${OPTARG} ;;
        d) THU_DPY=${OPTARG} ;;
        p) IMG_PATH=${OPTARG} ;;
        I) PUBDIR=${OPTARG} ;;
        T) IDX_TITLE=${OPTARG} ;;
        F) IDX_FILE=${OPTARG} ;;
        R) _RECURSE=1;;
        *)
            echo "** Unknown option ${o}."
            usage
        ;;
    esac
done
shift $((OPTIND-1))

makeDir "$_OUTDIR/thumbs"
cleanWorkDir "$_OUTDIR/thumbs"

makeDir "$PUBDIR"

[ ! -d "$IMG_PATH" ] && {
    echo "** I can't found directory ${IMG_PATH}."
    exit
}

echo "-- resolution     : $RES dpi "
echo "-- thumbnail size : ${Wpx}px × ${Hpx}px (ratio ${RATIO})"
echo "-- dir to scan    : $IMG_PATH"

makeLayout

OIFS="$IFS"
IFS=$'\n'
findImages "$IMG_PATH"
IMG_COUNT=${#IMG_LIST[@]}

Index=0
Count=0
NIndex=1
Start=1
IdxCount=`bc -l <<< "scale=0; $IMG_COUNT / $THUMB_COUNT + 1"`

echo "-- $IMG_COUNT images to process ($IdxCount index sheets)"

for img in ${IMG_LIST[@]}; do
  Index=$(( Index + 1 ))
  Count=$(( Count + 1 ))
  echo -ne \\r"-- processing image $Count / $IMG_COUNT [$img]"
  cropImage "$img" "$Count"
  if [ $Index -eq $THUMB_COUNT ]; then
	  makeIndex "$_OUTDIR" $NIndex $IdxCount
    Index=0
    NIndex=$(( NIndex + 1 ))
    Start=$NIndex
  fi
done

[ $Index -gt 0 ] && {
  PCount=$((THUMB_COUNT - Index))
  for ((a=1; a <= PCount ; a++)); do
    makePseudoThumb "$_OUTDIR/thumbs/c.zzzzzzzzzzz-$a.jpg"
  done
  makeIndex "$_OUTDIR" $NIndex $IdxCount
}

IFS="$OIFS"

cleanWorkDir "$_OUTDIR/thumbs"
