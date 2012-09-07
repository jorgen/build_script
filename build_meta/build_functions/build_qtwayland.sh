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

function ask_if_continue {
    while true; do
        read -p "Continue? [Y/n]: " to_continue < /dev/tty
        to_continue=${to_continue:-Y}
        case "$to_continue" in
            Y|y)
                return 0
                break
                ;;
            N|n)
                return 1
                break
                ;;
            *)
                echo "Please specify Y or N"
                ;;
        esac
    done
}

function pre_qtwayland {
    local project_source_dir=$1
    local project_install_dir=$2

    local wayland_source="$(dirname $project_source_dir)/wayland"

    if [ ! -e $wayland_source ]; then
        echo "Could not find wayland sources at $wayland_source"
        ask_if_continue
        if [[ $? != 0 ]]; then
            return 4
        fi
    fi

    wayland_sha=$(awk 'NR==3' $project_source_dir/wayland_sha1.txt)
    if [[ $? != 0 ]]; then
        return 1 
    fi

    cd $wayland_source
    if [[ wayland_sha != $(git rev-parse HEAD) ]]; then
        echo "Wayland HEAD and QtWayland:wayland_sha1.txt not equal"
        commits_ahead=$(git log $wayland_sha..HEAD 2>&1)
        if [[ $? != 0 ]]; then
            echo "QtWayland::wayland_sha1.txt not found in wayland history"
            ask_if_continue
            if [[ $? != 0 ]]; then
                return 2
            fi
        else
            
            echo $in_history
            commits_ahead=$(git log --oneline $wayland_sha..HEAD | wc -l)
            echo "Wayland SHA1 is $commits_ahead commits ahead of QtWayland::wayland_sha1.txt"
            ask_if_continue
            if [[ $? != 0 ]]; then
                return 3
            fi

        fi
    fi
}
