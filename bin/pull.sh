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

BUILD_META_DIR=$BASE_SCRIPT_DIR/build_meta
BUILD_ODER_FILE=$BUILD_META_DIR/build_order
BUILDSET_FILE=""
SYNC_TO_SHA="no"

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -s directory"
  echo ""
  echo "Options:"
  echo "-s, --src-dir           Source dir (REQUIRED)"
  echo "-f, --buildset          Buildset file"
  echo "                            Defaults to default_buildset"
  echo "-s, --src               Source dir"
  echo "    --sync              sync to sha1 specified in buildset"

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

function process_arguments {
    while [ ! -z $1 ]; do
        case "$1" in
            -s|--src-dir)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                BASE_SRC_DIR=$2
                shift 2
                ;;
            -f|--buildset)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                BUILDSET_FILE=$2
                shift 2
                ;;
            --sync)
                SYNC_TO_SHA="yes"
                shift
                ;;
            -h|--help)
                print_usage
                shift
                ;;
            *)
                print_unknown_argument $1
                shift
                ;;
        esac
    done
}

function set_global_variables {
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
    
    BASE_SRC_DIR="$( cd $BASE_SRC_DIR && pwd)"

    source "$BUILD_META_DIR/functions/find_buildset_file.sh"
    BUILDSET_FILE=$(resolve_buildset_file $BASE_SCRIPT_DIR $BUILDSET_FILE)
    echo "Using buildset $BUILDSET_FILE"
}

function main {
    while read line; do
        if [[ $line == \#* ]]; then
            continue
        fi
        set -- $line
        local project_name=$1
        local project_url=$2
        local project_sha=$3

        cd $BASE_SRC_DIR

        if [ ! -d $project_name ] && [ -z $project_url ]; then
            echo "Continuing for $project_name"
            continue
        fi

        echo "Processing $project_name"

        if [ -e $project_name ]; then
            if [ ! -d $project_name ]; then
                echo "File $project_name exists and conflicts with git clone target"
                exit 1
            else
                cd $project_name
                if [ -e .git ]; then
                    git pull --rebase
                    if [[ $SYNC_TO_SHA == "yes" ]]; then
                        git reset --hard $project_sha
                    fi
                else
                    echo "Found project directory but its not a git repository"
                    exit 1
                fi
            fi
        else
            git clone $project_url $project_name
            if [[ $SYNC_TO_SHA == "yes" ]]; then
                cd $project_name
                git reset --hard $project_sha
            fi
        fi
    done < $BUILDSET_FILE

    ln -sf $BUILDSET_FILE $BASE_SCRIPT_DIR/current_buildset
}

process_arguments $@
set_global_variables
main
