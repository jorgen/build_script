#!/bin/bash

#**************************************************************************************************
# Copyright (c) 2012 Jørgen Lind
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#**************************************************************************************************/

REAL_SCRIPT_FILE=${BASH_SOURCE[0]}
if [ -L ${BASH_SOURCE[0]} ]; then
    REAL_SCRIPT_FILE=$(readlink ${BASH_SOURCE[0]})
fi
   
BASE_SCRIPT_DIR="$( dirname "$( cd "$( dirname "$REAL_SCRIPT_FILE" )" && pwd )")"

BASE_SRC_DIR=""
BUILD_NAME=""
BUILD_META_DIR=$BASE_SCRIPT_DIR/build_meta
BUILD_ODER_FILE=$BUILD_META_DIR/build_order
BUILDSETS_DIR=$BUILD_META_DIR/buildsets


function print_usage {
    echo "Usage for $0"
    echo "$0 [options]"
    echo ""
    echo "Options:"
    echo "-s, --src-dir         Directory containing the source folders"
    echo "    --build-name      Append a line at the top identifying the snapshot with build-name"
    echo "-o, --order-file      Use file argument as basis for order of output."
    echo "                          The file must contain project identifier in first collumn"
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
    -s|--src-dir)
        if [ -z $2 ]; then
            print_missing_argument $1
        fi
        BASE_SRC_DIR=$2
        shift 2
        ;;
    --build-name)
        if [[ $2 == "" ]]; then
            print_missing_argument $1
        fi
        BUILD_NAME=$2
        shift 2
        ;;
    -o|--order-file)
        if [[ $2 == "" ]]; then
            print_missing_argument $1
        fi
        BUILD_ODER_FILE=$2
        shift 2
        ;;
    *)
        print_unknown_argument $1
        shift
        ;;
    esac
done

if [ -z $BASE_SRC_DIR ]; then
    echo ""
    echo "********************************"
    echo "Please specify a src directory"
    echo "********************************"
    echo ""
    print_usage
elif [ ! -e $BASE_SRC_DIR ]; then
    echo ""
    echo "Specified srd-dir '$BASE_BUILD_DIR' does not exist"
    print_usage
fi

if [ ! -e $BUILD_ODER_FILE ]; then
    echo "Build order file does not exist"
    exit 1
fi

if [ ! -e $BUILDSETS_DIR/snapshots ]; then
    mkdir $BUILDSETS_DIR/snapshots
fi

DATE=$(date +%F_%T)
BUILD_SET_FILE=$BUILDSETS_DIR/snapshots/buildset_$DATE

if [ -e $BUILD_SET_FILE ]; then
    rm $BUILD_SET_FILE
fi

if [[ $BUILD_NAME != "" ]]; then
    echo "# $BUILD_NAME" >> $BUILD_SET_FILE
fi
printf "%-20s %-80s %-24s\n" "# Name" "Url" "SHA1" >> $BUILD_SET_FILE

while read line; do
    if [[ $line == \#* ]]; then
        continue
    fi
    set -- $line
    project_name=$1

    url=""
    common_ancestor=""

    cd $BASE_SRC_DIR

    if [ -d $project_name ]; then
        cd $project_name
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
                echo "Could not find remote branch for ***$project_name***, using local HEAD as sha!"
                common_ancestor=$(git rev-parse HEAD)
            else
                common_ancestor=$(git merge-base HEAD $remote/$remote_branch)
            fi
        fi
    fi
    printf "%-20s %-80s %-24s\n" $project_name $url $common_ancestor >> $BUILD_SET_FILE
done < $BUILD_ODER_FILE
