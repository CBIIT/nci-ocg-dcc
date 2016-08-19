#!/bin/bash

script=$(basename $0)
usage="Usage: $script <data file directory>"

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
    echo $usage
    exit 1
fi
for bam in $1/*.bam; do
    echo "Validating $bam"
    bam validate --verbose --in $bam
    echo
done
