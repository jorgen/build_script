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

function resolve_buildset_file {
    local base_src_dir=$1
    local build_set_file=$2

    if [[ $build_set_file == \.* ]]; then
        #relative path
        local path_to_buildset_file=$(dirname $base_src_dir/$build_set_file)
        if [ ! -e $path_to_buildset_file ]; then
            echo "The relative path specified $path_to_buildset_file does not exist"
            exit
        fi
        cd $path_to_buildset_file
        path_to_buildset_file=$(pwd)
        cd -
        local filename_to_buildset_file=$(basename $base_src_dir/$build_set_file)
        build_set_file="$path_to_buildset_file/$filename_to_buildset_file"
    elif [[ $build_set_file == \/* ]]; then
        #full path
        build_set_file="$build_set_file"
    elif [ ! -z $build_set_file ]; then
        #look in the buildsets folder
        build_set_file="$base_src_dir/build_meta/buildsets/$build_set_file"
    fi

    if [ -z $build_set_file ]; then
        if [ -e $base_src_dir/current_buildset ]; then
            build_set_file="$base_src_dir/current_buildset"
        fi
    fi

    if [ -z $build_set_file ]; then
        build_set_file="$base_src_dir/build_meta/buildsets/default_buildset"
    fi

    if [ ! -e "$build_set_file" ]; then
        echo "The buildset file: $build_set_file does not exist"
        exit
    fi

    if [ -L $build_set_file ]; then
        build_set_file=$(readlink $build_set_file)
    fi

    echo "$build_set_file"
}
