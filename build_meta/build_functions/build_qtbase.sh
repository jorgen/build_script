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

__QT_BASE_FORCE_OPENGL_ES=""

function pre_qtbase {
    while true; do
        read -p "Force OpenGL ES2 compatibillity for QtGui? [N/y]: " force_es2 < /dev/tty
        force_es2=${force_es2:-N}
        case "$force_es2" in
            Y|y)
                __QT_BASE_FORCE_OPENGL_ES="es2"
                break
                ;;
            N|n)
                __QT_BASE_FORCE_OPENGL_ES=""
                break
                ;;
            *)
                echo "Please specify Y or N"
                ;;
        esac
    done

}

function build_qtbase {
    local project_source_dir=$1
    local project_install_dir=$2

    if [ ! -e $project_source_dir/configure ]; then
        return 1
    fi

    if [ ! -e Makefile ]; then
        echo "Executing QTBASE"
        $project_source_dir/configure \
            -developer-build \
            -prefix $project_install_dir \
            -opengl $__QT_BASE_FORCE_OPENGL_ES \
            -nomake tests \
            -opensource \
            -confirm-license

        if [[ $? != 0 ]]; then
            return 2
        fi
    fi

    make
    if [[ $? != 0 ]]; then
        return 3
    fi

    make install
    if [[ $? != 0 ]]; then
        return 4
    fi
}
