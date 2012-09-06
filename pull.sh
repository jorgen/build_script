#!/bin/bash

TOP_LEVEL_SRC_DIR=$PWD
for file in *; do
    if [ ! -d $file ]; then
        continue
    fi
    cd $file
    if [ -e .git ]; then
        git pull --rebase
    else
        echo "NOT A GIT REPO $file"
    fi
    cd $TOP_LEVEL_SRC_DIR 
done
