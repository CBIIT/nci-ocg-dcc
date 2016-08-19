#!/bin/bash

script=$(basename $0)
usage="Usage: $script <data file directory>"

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    echo $usage
    exit 1
fi
cd $1
for filename in *.fastq; do
    gzip -vc $filename > ${filename}.gz
done
