#!/bin/bash
if [ -z $1 ]; then
  echo "No file size indicated"
  echo "Usage: ./genfile.sh <megabytes> <filename>, ex: ./genfile 10 file.txt"
  exit 0
fi
if [ -z $2 ]; then
  echo "No file name indicated"
  echo "Usage: ./genfile.sh <megabytes> <filename>, ex: ./genfile 10 file.txt"
  exit 0
fi
  date1=$(date +"%s")

  if [ -e $2 ]; then
    rm $2 || exit 0
  fi
  
for (( i=1;i<=$1;i++)); do
  dd if=/dev/urandom bs=$((1024*1024)) count=$((1)) >> $2 || break
  clear
  echo "Generating $2:  $i MB / $1 MB"
done
  echo "done"
  date2=$(date +"%s")
  diff=$(($date2-$date1))
  echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
