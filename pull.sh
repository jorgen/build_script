#!/bin/bash

BASE_SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BUILD_META_DIR=$BASE_SRC_DIR/build_meta
BUILD_ODER_FILE=$BUILD_META_DIR/build_order
BUILD_REPO_FILE=$BUILD_META_DIR/build_repos

while read line; do
    if [[ $line == \#* ]]; then
        continue
    fi
    set -- $line
    project_name=$1
    project_url=$2

    if [ ! -d $project_name ] || [ -z $project_url ]; then
        echo "Continuing for $project_name"
        continue
    fi
    cd $project_name
    if [ -e .git ]; then
        git pull --rebase
    fi
    cd $BASE_SRC_DIR
done < $BUILD_REPO_FILE 

