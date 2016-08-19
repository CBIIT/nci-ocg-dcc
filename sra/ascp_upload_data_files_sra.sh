#!/bin/bash

script=$(basename $0)
usage="Usage: $script <data file directory> <data file ext>"

if [ "$#" -ne 2 ] || [ ! -d "$1" ]; then
    echo $usage
    exit 1
fi
if test -n "$(find $1 -maxdepth 1 -name *.$2 -print -quit)"; then
    for file in $1/*.$2; do
        ascp_cmd="ascp -i $HOME/.ssh/id_rsa -q -Q -v -l 400m -k 1 $file asp-nci@gap-submit.ncbi.nlm.nih.gov:protected"
        echo $ascp_cmd
        $ascp_cmd
        [ $? -eq 0 ] && echo 'OK' || echo 'FAILED'
    done
else
    echo "No $2 files found"
fi
exit 0
