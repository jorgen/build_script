#!/bin/bash

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

