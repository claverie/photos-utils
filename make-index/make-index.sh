#!/bin/bash

[ ! -z "$DEBUG" ] && set -x

_IEXTENSION=(jpg png)
_RECURSE=0
_OUTDIR=/tmp/0imgIndex
_LOCALDIR=`pwd`

IDX_BACK="black"
IDX_FRONT="white"
IDX_FILE="index"
IDX_TITLE="Index"

THU_RATIO="3/2"
THU_DPY="300"
IMG_PATH="."
IMG_LIST=()



function usage() {
  echo "Usage: $0 -p [path] -d resolution -r ratio "
  echo "         -p     : directory path that contains images [default .]"
  echo "         -r     : set thumbnails height/width ratio [3/2]"
  echo "         -d     : set thumbnails resolution [300]"
  echo "         -T     : set index title [Index]"
  echo "         -F     : set index base filename [index]"
  echo "         -R     : recurse"
  exit
}


function mkWorkDir() {
    [ ! -d "$1/thumbs" ] && mkdir -p "$1/thumbs"
    cleanWorkDir "$1"
}
function cleanWorkDir() {
    (cd "$1" && rm -f thumbs/*)
}

function makePseudoThumb() {
  Hc=`bc -l <<< "scale=0; ${Hpx} + 30 "`
  convert -size ${Wpx}x${Hc} xc:${IDX_FRONT} $1
}

LAY_WIDTH=20
LAY_HEIGHT=27

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

  idate=`identify -format "%[EXIF:DateTimeOriginal]" $1`
  dim=`identify -format "%[fx:w]:%[fx:h]" $1`
  Adim=(${dim//:/ })

  SCALE="${Wpx}x"
  ROTATE=""
  [ ${Adim[0]} -lt ${Adim[1]} ] && {
	   ROTATE="-rotate -90"
  }
  Hc=`bc -l <<< "scale=0; ${Hpx} + 30 "`

  BOX="-size ${Wpx}x${Hc} xc:${IDX_BACK} +swap -gravity North -composite "
  convert  "$1" \
	   ${ROTATE} \
	  -resize ${SCALE}  \
	   ${BOX} \
	    -strip  \
	     "$_OUTDIR/thumbs/t.$f.jpg"

  convert \
	   -background ${IDX_BACK} -fill white -size ${Wpx}x30 \
     -font "courier" -pointsize 24 \
     caption:"[$2]_${f}"  \
     "$_OUTDIR/thumbs/t.$f.jpg"  +swap -gravity SouthEast -composite \
     "$_OUTDIR/thumbs/c.$f.jpg"

  rm "$_OUTDIR/thumbs/t.$f.jpg"

}
function makeIndex() {
    l=`ls $1/thumbs/c.*.jpg`
    #montage -background ${BACK} -geometry +4+4 $l $_OUTDIR/m.png
    rg=`printf "%05d" $2`
    tIFile="${_OUTDIR}/t.${IDX_FILE}-"$rg".jpg"
    IFile="${_OUTDIR}/${IDX_FILE}-"$rg".jpg"
    echo -n " > building Index $IFile"
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
      _filter=$_filter' '$IMG_PATH'/*.'$e' '$IMG_PATH'/*.'${e^^}
    fi
  done
  if [ $_RECURSE == 1 ]; then
    IMG_LIST=(`find $IMG_PATH -regex  ".*\.\($_filter\)$" -print | sort `)
  else
    IMG_LIST=(`ls $_filter`)
  fi
}

while getopts ":r:p:d:F:T:R" o; do
    case "${o}" in
        r) THU_RATIO=${OPTARG} ;;
        d) THU_DPY=${OPTARG} ;;
        p) IMG_PATH=${OPTARG} ;;
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

LCOUNT=5
RCOUNT=9
CIMG=$(( LCOUNT * RCOUNT ))


mkWorkDir "$_OUTDIR"

[ ! -d "$IMG_PATH" ] && {
    echo "** I can't found directory ${IMG_PATH}."
    exit
}

# 35mm en 300 dpi =>  environ 400 px
RATIO=`bc -l <<< "scale=2; "$THU_RATIO `
RES=$THU_DPY
Wpx=`bc -l <<< "scale=0; ${RES} / 2.54 * 3.5"`
Hpx=`bc -l <<< "scale=0; ${Wpx} / ${RATIO} "`
echo "-- resolution     : $RES dpi "
echo "-- thumbnail size : ${Wpx}px × ${Hpx}px (ratio ${RATIO})"
echo "-- dir to scan    : $IMG_PATH"

makeLayout

findImages "$IMG_PATH"
IMG_COUNT=${#IMG_LIST[@]}

Index=0
Count=0
NIndex=1
Start=1
IdxCount=`bc -l <<< "scale=0; $IMG_COUNT / $CIMG + 1"`

echo "-- $IMG_COUNT images to process ($IdxCount index sheets)"

for img in ${IMG_LIST[@]}; do
  Index=$(( Index + 1 ))
  Count=$(( Count + 1 ))
  echo -ne \\r"-- processing image $Count [$img]"
  cropImage "$img" "$Count"
  if [ $Index -eq $CIMG ]; then
	  makeIndex "$_OUTDIR" $NIndex $IdxCount
    Index=0
    NIndex=$(( NIndex + 1 ))
    Start=$NIndex
  fi
done
[ $Index -gt 0 ] && {
  PCount=$((CIMG - Index))
  for ((a=1; a <= PCount ; a++)); do
    makePseudoThumb "$_OUTDIR/thumbs/c.zzzzzzzzzzz-$a.jpg"
  done
  makeIndex "$_OUTDIR" $NIndex $IdxCount
}


cleanWorkDir "$_OUTDIR"
