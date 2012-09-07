#!/bin/bash

function build_qtbase {
    local project_source_dir=$1
    local project_install_dir=$2
    local __resultvar=$3
    local to_return="0"

    if [ ! -e $project_source_dir/configure ]; then
        to_return="-1"
    fi

    if [[ $to_return == "0" ]] && [ ! -e Makefile ]; then
        echo "Executing QTBASE"
        $project_source_dir/configure -developer-build -prefix $project_install_dir -opengl es2 -opensource -confirm-license
        if [[ $? != 0 ]]; then
            to_return="-1"
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
            to_return="-3"
        fi
    fi

    eval $__resultvar="'$to_return'"
}
