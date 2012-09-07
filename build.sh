#!/bin/bash

BASE_SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_META_DIR=$BASE_SRC_DIR/build_meta

BASE_BUILD_DIR=""
BASE_INSTALL_DIR=""

BUILD_ODER_FILE=""
BUILDSET_FILE=""

WIPE_PROJECTS="no"
WIPE_INSTALL="no"

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -b directory"
  echo ""
  echo "Options:"
  echo "-b, --build-dir         Directory for building projects (REQUIRED)"
  echo "-i, --install-dir       Directory where projects will be installed"
  echo "                            Defaults to build-dir"
  echo "-s, --buildset          Buildset file"
  echo "                            Defaults to default_buildset"
  echo "-w, --wipe              Remove build directories before building"
  echo "    --wipe-install      Remove install dir"
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
            -b|--build-dir)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                BASE_BUILD_DIR=$2
                shift 2
                ;;
            -s|--buildset)
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
    
    local current_dir=$(pwd)
    cd $1
    echo "$(pwd)"
    cd $current_dir

    if [[ $? != 0 ]]; then
        echo "faild to create directory $1"
        exit
    fi
}

function set_global_variables {
    if [ -z $BASE_BUILD_DIR ]; then
        echo ""
        echo "********************************"
        echo "Please specify a build directory"
        echo "********************************"
        echo ""
        print_usage
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
        rm -rf $BASE_INSTALL_DIR
        mkdir $BASE_INSTALL_DIR
    fi

    BUILD_ODER_FILE=$BASE_META_DIR/build_order

    if [ -z $BUILDSET_FILE ]; then
        BUILDSET_FILE="$BASE_META_DIR/buildsets/default_buildset"
    fi

    if [[ $BUILDSET_FILE == \.* ]]; then
        #relative path
        local path_to_buildset_file=$(dirname $BASE_SRC_DIR/$BUILDSET_FILE)
        if [ ! -e $path_to_buildset_file ]; then
            echo "The relative path specified $path_to_buildset_file does not exist"
            exit
        fi
        cd $path_to_buildset_file
        path_to_buildset_file=$(pwd)
        cd -
        local filename_to_buildset_file=$(basename $BASE_SRC_DIR/$BUILDSET_FILE)
        BUILDSET_FILE="$path_to_buildset_file/$filename_to_buildset_file"
    elif [[ $BUILDSET_FILE == \/* ]]; then
        #full path
        BUILDSET_FILE="$BUILDSET_FILE"
    else
        #look in the buildsets folder
        BUILDSET_FILE="$BASE_META_DIR/buildsets/$BUILDSET_FILE"
    fi

    if [ ! -e "$BUILDSET_FILE" ]; then
        echo "The buildset file: $BUILDSET_FILE does not exist"
        exit
    fi

    echo "#!/bin/bash" > $BASE_BUILD_DIR/build_and_run_env.sh
    echo "export LD_LIBRARY_PATH=$BASE_INSTALL_DIR/lib" >> $BASE_BUILD_DIR/build_and_run_env.sh
    echo "export PKG_CONFIG_PATH=$BASE_INSTALL_DIR/lib/pkgconfig" >> $BASE_BUILD_DIR/build_and_run_env.sh
    echo "export PATH=$BASE_INSTALL_DIR/bin:$PATH" >> $BASE_BUILD_DIR/build_and_run_env.sh

    if [[ $? != 0 ]]; then
        echo "Could not make build environment file"
        print_usage
    fi

    source build_and_run_env.sh
}

function set_make_flags {
    if [[ $MAKEFLAGS != *-j* ]]; then
        local number_of_processors=$(grep -e "processor[[:space:]]*: [0-9]*" /proc/cpuinfo | wc -l)
        export MAKEFLAGS="$MAKEFLAGS -j$number_of_processors"
    fi
}

function find_qmake {
    local project_install_dir=$1
    
    if [ -e $project_install_dir/bin/qmake ]; then
        echo "$project_install_dir/bin/qmake"
    fi
}

function main {

    $BASE_SRC_DIR/create_buildset.sh --build-name "Build dir: $BASE_BUILD_DIR Install dir: $BASE_INSTALL_DIR"

    set_make_flags

    if [ -e $BASE_META_DIR/build_default.sh ]; then
        source $BASE_META_DIR/build_default.sh
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
        
        if [ -e $BASE_META_DIR/build_$project.sh ]; then
            source $BASE_META_DIR/build_$project.sh
        fi
        
        cd $BASE_BUILD_DIR
        if [ -e $project_build_dir ]; then
            if [ ! -d $project_build_dir ]; then
                echo "Conflicting file! Build script wants to make " \
                    + "directory $project_build_dir to build project $dir"
                exit 1
            fi
        else
            mkdir -p $project_build_dir
        fi

        if [ "$(type -t prepare_$project)" == "function" ]; then
            cd $project_build_dir
            prepare_$project $project_source_dir $project_install_dir result
        else
            result=0
        fi

        if [[ $result < 0 ]]; then
            echo "prepare for $project failed"
            exit 1
        fi

    done < $BUILDSET_FILE 

    if [[ $WIPE_PROJECTS ]] ; then
        while read line; do
            if [[ $line == \#* ]] ; then
                continue
            fi

            set -- $line
         
            local project=$1

            local project_build_dir=$BASE_BUILD_DIR/$project
            if [ -e $project_build_dir ]; then
                rm -rf $project_build_dir
                mkdir $project_build_dir
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

        cd $project_source_dir
        if [ "$(type -t build_$project)" == "function" ]; then
            build_$project $project_source_dir $project_install_dir result
        else
            build_default $project_source_dir $project_install_dir result
        fi
        cd $BASE_SRC_DIR

        if [[ $result < 0 ]]; then
            echo "Build failed at: $project"
            exit 1
        fi
    done < $BUILDSET_FILE 
}

process_arguments $@
set_global_variables
main
