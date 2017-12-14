#!/bin/bash
# set -x;
# trap read debug

##
# Prepare data lists for feature extraction by scanning dataset subfolders
##


datadir=$1
ext=$2
outdir=$3

if [ -f path.sh ]; then . ./path.sh; fi

# directory for wav lists
listdir=$outdir/lists
mkdir -p $listdir || exit 1;

wavlist=$listdir/waves.list
scp=$listdir/waves.scp

# scan files with ext in current folder and all subfolders
find $datadir -type f -name "*.$ext" > $wavlist

if [ ! -f $wavlist ]; then
  echo "[error] there are no waves in $datadir" && exit 1;  
fi

# iterate waves list and prepare kaldi scp: [wavID] [file full path]
while read line; do
  full_name=$line
  # check file exist
  [ ! -f "$full_name" ] && echo "[error] no such audio file..." && exit 1;
  
  # parse file name only (without path and ext): utterance_id
  name=$(basename $full_name)  
  utterance_id=${name%.*}
  #echo $utterance_id "sox -r 8000 -t raw -e signed-integer -b 16 -c 1 " $full_name " -t wav - |"
  echo $utterance_id "sox $full_name -r 8000 -c 1 -t wav -b 16 - |"
done < $wavlist > $scp;

cat $scp | sort -u -k1,1 -o $scp

# check number of files
nf=`cat $wavlist | wc -l` 
nu=`cat $scp | wc -l` 
if [ $nf -ne $nu ]; then
  echo "[INFO] It seems not all the audio files exist ($nf != $nu);"
  echo "compare $wavlist and $scp"
  exit 1;
fi

echo "$0: data lists prepared successfully $scp: $nu utterances"
