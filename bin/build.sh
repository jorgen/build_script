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

BASE_META_DIR=$BASE_SCRIPT_DIR/build_meta

BASE_SRC_DIR=""
BASE_BUILD_DIR=""
BASE_INSTALL_DIR=""

BUILD_ODER_FILE=""
BUILDSET_FILE=""

WIPE_PROJECTS="no"
WIPE_INSTALL="no"

RUN_PRE_ROUTINE="yes"
RUN_BUILD_ROUTINE="yes"
RUN_POST_ROUTINE="yes"

PLATFORM_OS="linux"

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -s directory"
  echo ""
  echo "Options:"
  echo "-s, --src-dir           Source dir (REQUIRED)"
  echo "-b, --build-dir         Directory for building projects"
  echo "                            Defaults to src-dir"
  echo "-i, --install-dir       Directory where projects will be installed"
  echo "                            Defaults to build-dir"
  echo "-f, --buildset          Buildset file"
  echo "                            Defaults to default_buildset"
  echo "-w, --wipe              Remove build directories before building"
  echo "    --wipe-install      Remove install dir"
  echo "    --skip-pre          Skip pre routine"
  echo "    --skip-build        Skip build routine"
  echo "    --skip-post         Skip post routine"
  echo "-h, --help              Print this message"
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

function process_arguments {
    while [ ! -z $1 ]; do
        case "$1" in
            -w|--whipe)
                WIPE_PROJECTS="yes"
                shift
                ;;
            --wipe-install)
                WIPE_INSTALL="yes"
                shift
                ;;
            -s|--src-dir)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                echo "SETTING BASE SRC DIR to $2"
                BASE_SRC_DIR=$2
                shift 2
                ;;
            -b|--build-dir)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                BASE_BUILD_DIR=$2
                shift 2
                ;;
            -f|--buildset)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                BUILDSET_FILE=$2
                shift 2
                ;;
            -i|--install-dir)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                BASE_INSTALL_DIR=$2
                shift 2
                ;;
            --skip-pre)
                RUN_PRE_ROUTINE="no"
                shift
                ;;
            --skip-build)
                RUN_BUILD_ROUTINE="no"
                shift
                ;;
            --skip-post)
                RUN_POST_ROUTINE="no"
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

function check_and_create_directory {
     if [ ! -e $1 ]; then
        mkdir -p $1
        if [[ $? != 0 ]]; then
            echo ""
            echo "Could not create build directory"
            print_usage
        fi
    elif [ ! -d $1 ]; then
        echo "Conflicting file for dir $1"
        print_usage
    fi

    local dir="$( cd $1 && pwd )"

    if [[ $? != 0 ]]; then
        echo "faild to create directory $1"
        exit
    fi

    echo "$dir"
}

function set_global_variables {
    if [[ $BASE_SRC_DIR == "" ]]; then
        echo "$BASE_SRC_DIR"
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
    
    if [ -z $BASE_BUILD_DIR ]; then
        BASE_BUILD_DIR=$BASE_SRC_DIR
    else
        BASE_BUILD_DIR=$(check_and_create_directory $BASE_BUILD_DIR)
        if [[ $BASE_BUILD_DIR == $BASE_META_DIR ]]; then
            echo "Build dir $BASE_BUILD_DIR is an illigal build dir"
        fi
    fi
   
    if [ -z $BASE_INSTALL_DIR ]; then
        BASE_INSTALL_DIR=$BASE_BUILD_DIR
    else
        BASE_INSTALL_DIR=$(check_and_create_directory $BASE_INSTALL_DIR)
    fi

    if [[ $WIPE_INSTALL == "yes" ]]; then
        if [[ $BASE_INSTALL_DIR == $BASE_SRC_DIR ]]; then
            echo "Trying to wipe install dir, but its the same as the src dir"
            exit 1
        else 
            rm -rf $BASE_INSTALL_DIR
            mkdir $BASE_INSTALL_DIR
        fi
    fi

    BUILD_ODER_FILE=$BASE_META_DIR/build_order

    source "$BASE_META_DIR/functions/find_buildset_file.sh"
    BUILDSET_FILE=$(resolve_buildset_file $BASE_SCRIPT_DIR $BUILDSET_FILE)
    echo "Using buildset file: $BUILDSET_FILE"


    echo "#!/bin/bash" > $BASE_BUILD_DIR/build_and_run_env.sh
    echo "export LD_LIBRARY_PATH=$BASE_INSTALL_DIR/lib" >> $BASE_BUILD_DIR/build_and_run_env.sh
    echo "export PKG_CONFIG_PATH=$BASE_INSTALL_DIR/lib/pkgconfig" >> $BASE_BUILD_DIR/build_and_run_env.sh
    echo "export PATH=$BASE_INSTALL_DIR/bin:$PATH" >> $BASE_BUILD_DIR/build_and_run_env.sh

    if [[ $? != 0 ]]; then
        echo "Could not make build environment file"
        print_usage
    fi

    source $BASE_BUILD_DIR/build_and_run_env.sh

    platform_name=$(uname | tr '[A-Z]' '[a-z]')
    if [[ $platform_name == "*bad" || $platform_name == "darwin" ]]; then
        PLATFORM_OS="bsd"
    fi
}

function set_make_flags {
    if [[ $MAKEFLAGS != *-j* ]]; then
        local found_makeflags=0
        if [[ $PLATFORM_OS == "linux" ]]; then
            local number_of_processors=$(grep -e "processor[[:space:]]*: [0-9]*" /proc/cpuinfo | wc -l)
            found_makeflags=1
        elif [[ $PLATFORM_OS == "bsd" ]]; then
            local number_of_processors=$(sysctl hw.ncpu | awk '{print $2}')
            found_makeflags=1
        fi
        if [ $found_makeflags -gt 0 ]; then 
            local export_makeflags='export MAKEFLAGS="$MAKEFLAGS -j$number_of_processors"'
            echo $export_makeflags >> $BASE_BUILD_DIR/build_and_run_env.sh
            eval $export_makeflags
        fi
    fi
}

function find_qmake {
    local project_install_dir=$1

    if [ -e $project_install_dir/bin/qmake ]; then
        echo "$project_install_dir/bin/qmake"
    fi
}

function main {

    create_buildset_arg="Src dir: $BASE_SRC_DIR Build dir: $BASE_BUILD_DIR Install dir $BASE_INSTALL_DIR"
    $BASE_SCRIPT_DIR/bin/create_buildset.sh -s "$BASE_SRC_DIR" --build-name "$create_buildset_arg"
    if [[ $? != 0 ]]; then
        echo "Failed to create snapshot"
        exit 1
    fi

    set_make_flags

    if [ -e $BASE_META_DIR/build_functions/build_default.sh ]; then
        source $BASE_META_DIR/build_functions/build_default.sh
    else
        echo "Missing $BASE_META_DIR/build_default.sh"
        exit 1
    fi 

    while read line; do
        if [[ $line == \#* ]] ; then
            continue
        fi

        set -- $line

        local project=$1

        local project_source_dir=$BASE_SRC_DIR/$project
        local project_build_dir=$BASE_BUILD_DIR/$project
        local project_install_dir=$BASE_INSTALL_DIR

        if [ ! -d $project_source_dir ]; then
            echo "Couldn't find projects source dir at: $project_source_dir"
            echo "But its specified by the defined build set, exiting..."
            exit 1
        fi
        
        if [ -e $BASE_META_DIR/build_functions/build_$project.sh ]; then
            source $BASE_META_DIR/build_functions/build_$project.sh
        fi
        
        if [ -e $project_build_dir ]; then
            if [ ! -d $project_build_dir ]; then
                echo "Conflicting file! Build script wants to make " \
                    + "directory $project_build_dir to build project $dir"
                exit 1
            fi
        else
            mkdir -p $project_build_dir
        fi

        if [[ $RUN_PRE_ROUTINE == "yes" ]]; then
            if [ "$(type -t pre_$project)" == "function" ]; then
                cd $project_build_dir
                pre_$project $project_source_dir $project_install_dir
                if [[ $? != 0 ]]; then
                    echo "prepare for $project failed"
                    exit
                fi
            fi
        fi

    done < $BUILDSET_FILE 

    if [[ $WIPE_PROJECTS == "yes" ]]; then
        while read line; do
            if [[ $line == \#* ]] ; then
                continue
            fi

            set -- $line

            local project=$1

            local project_build_dir=$BASE_BUILD_DIR/$project
            if [[ $BASE_BUILD_DIR == $BASE_SRC_DIR ]]; then
                if [ -e $project_build_dir/.git ]; then
                    $( cd $project_build_dir && git clean -xdfq )
                elif [ -e $project_build_dir/Makefile ]; then
                    $( cd $project_build_dir && make clean )
                else
                    echo "Dont know how to clean build directory $project_build_dir"
                    echo "Its a in src build and it doesn't have a git repo nor a Makefile"
                    exit 1;
                fi
            else 
                if [ -e $project_build_dir ]; then
                    rm -rf $project_build_dir
                    mkdir $project_build_dir
                fi
            fi
        done < $BUILDSET_FILE 
    fi

    while read line; do
        if [[ $line == \#* ]] ; then
            continue
        fi

        set -- $line

        local project=$1

        local project_source_dir=$BASE_SRC_DIR/$project
        local project_build_dir=$BASE_BUILD_DIR/$project
        local project_install_dir=$BASE_INSTALL_DIR

        if [[ $RUN_BUILD_ROUTINE == "yes" ]]; then
            cd $project_build_dir
            if [ "$(type -t build_$project)" == "function" ]; then
                build_$project $project_source_dir $project_install_dir
            else
                build_default $project_source_dir $project_install_dir
            fi

            if [[ $? != 0 ]]; then
                echo "Build failed at: $project"
                exit 1
            fi
        fi

    done < $BUILDSET_FILE 
    
    while read line; do
        if [[ $line == \#* ]] ; then
            continue
        fi

        set -- $line

        local project=$1

        local project_source_dir=$BASE_SRC_DIR/$project
        local project_build_dir=$BASE_BUILD_DIR/$project
        local project_install_dir=$BASE_INSTALL_DIR

        if [[ $RUN_POST_ROUTINE == "yes" ]]; then
            if [ "$(type -t post_$project)" == "function" ]; then
                cd $project_build_dir

                post_$project $project_source_dir $project_install_dir
                if [[ $? != 0 ]]; then
                    echo "Post failed at: $project"
                    exit 1
                fi

            fi
        fi

    done < $BUILDSET_FILE 
}

process_arguments $@
set_global_variables
main
