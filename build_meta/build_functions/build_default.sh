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

function build_default {
    local project_name=$(basename $PWD)
    local project_source_dir=$1
    local project_install_dir=$2
    local _default_build_resultvar=$3
    local to_return="0"
   
    if [ ! -e Makefile ]; then
        if [ -e $project_source_dir/$project_name.pro ]; then
            qmake=$(find_qmake $project_install_dir)
            if [ -z $qmake ]; then
                to_return="-1"
            else
                $qmake $project_source_dir/$project_name.pro
            fi 
        elif [ -e $project_source_dir/autogen.sh ]; then
            $project_source_dir/autogen.sh --prefix=$project_install_dir
            if [[ $? != 0 ]]; then
                to_return="-1"
            fi
        fi
    fi

    if [[ $to_return == "0" ]]; then
        make
        if [[ $? != 0 ]]; then
            to_return="-2"
        fi
    fi

    if [[ $to_return == "0" ]]; then
        make install
        if [[ $? != 0 ]]; then
            to_return= "-3"
        fi
    fi

    eval $_default_build_resultvar="'$to_return'"
}

