#!/bin/bash

BASE_SRC_DIR=$PWD

if [ -e repos.txt ]; then
    rm repos.txt
fi
while read line; do
    url=""
    if [ -d $line ]; then
        cd $line
        if [ -d .git ]; then
            url=$(git config --get remote.origin.url)
        fi
        cd $BASE_SRC_DIR
    fi
    printf "%-20s%-80s\n" $line $url >> repos.txt
done < build_order
