#!/bin/bash

BASE_SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_NAME=""

function print_usage {
    echo "Usage for $0"
    echo "$0 [options]"
    echo ""
    echo "Options:"
    echo "    --build-name      Append a line at the top identifying the snapshot with build-name"
    echo ""

    exit 1
}

function print_missing_argument {
    echo ""
    echo "Missing argument for $1"
    echo ""
    print_usage
}

function print_unknown_argument {
    echo ""
    echo "Unknown argument: $1"
    echo ""
    print_usage
}

while [ ! -z $1 ]; do
    case "$1" in
    --build-name)
        if [ -z $2 ]; then
            print_missing_argument $1
        fi
        BUILD_NAME=$2
        shift 2
        ;;
    *)
        print_unknown_argument $1
        shift
        ;;
    esac
done

BUILD_META_DIR=$BASE_SRC_DIR/build_meta
BUILD_ODER_FILE=$BUILD_META_DIR/build_order
BUILDSETS_DIR=$BUILD_META_DIR/buildsets

if [ ! -e $BUILDSETS_DIR/snapshots ]; then
    mkdir $BUILDSETS_DIR/snapshots
fi

DATE=$(date +%F_%T)
BUILD_SET_FILE=$BUILDSETS_DIR/snapshots/buildset_$DATE

if [ -e $BUILD_SET_FILE ]; then
    rm $BUILD_SET_FILE
fi

if [ ! -z $BUILD_NAME ]; then
    echo "# $BUILD_NAME" >> $BUILD_SET_FILE
fi
printf "%-20s%-80s%-24s\n" "# Name" "Url" "SHA1" >> $BUILD_SET_FILE

while read line; do
    if [[ $line == \#* ]]; then
        continue
    fi
    url=""
    common_ancestor=""
    if [ -d $line ]; then
        cd $line
        if [ -d .git ]; then
            url=$(git config --get remote.origin.url)
            branch=$(basename $(git symbolic-ref HEAD))
            remote=$(git config --get "branch.$branch.remote")
            if [ -n $remote ]; then
                remote_branch=$(git config --get "branch.$branch.merge")
                if [ ! -z $remote_branch ]; then
                    remote_branch=$(basename $remote_branch)
                fi
            fi
            if [ -z $remote ] || [ -z $remote_branch ]; then
                echo "Could not find remote branch for ***$line***, using local HEAD as sha!"
                common_ancestor=$(git rev-parse HEAD)
            else
                common_ancestor=$(git merge-base HEAD $remote/$remote_branch)
            fi
        fi
        cd $BASE_SRC_DIR
    fi
    printf "%-20s%-80s%-24s\n" $line $url $common_ancestor >> $BUILD_SET_FILE
done < $BUILD_ODER_FILE
