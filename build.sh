#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function build_base {
    if [ -e config.status ]; then
        BUILD_CMD=$(awk 'NR==3' config.status | sed -n -e 's/-confirm.*/\ /p')
        $($BUILD_CMD)
    else
        echo "didn't have a build command to parse"
        exit 1
    fi
}

function build_default {
    echo "building $(basename $PWD)"
}


for dir in *; do
    if [ ! -d $dir ]; then
        continue
    fi
    if [ "$(type -t build_$dir)" == "function" ]; then
        cd $dir
        build_$dir
        cd $SCRIPT_DIR
    else
        cd $dir
        build_default
        cd $SCRIPT_DIR
    fi
done
