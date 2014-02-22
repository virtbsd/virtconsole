#!/usr/local/bin/zsh

# (BSD 2-clause license)
# 
# Copyright (c) 2014, Shawn Webb
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

#    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

dialogchoice=$(mktemp)
host=${1}

function manage_virtual_machine {
    json=${1}
    vmid=${2}
    name=${3}

    while [ true ]; do
        dialog --backtitle 'VirtBSD' --title "Manage ${name}" --menu "" 0 0 0 \
            1 'Show Status' \
            2> ${dialogchoice}

        if [ ${?} = 1 ]; then
            return
        fi

        choice=$(cat ${dialogchoice})

        case ${choice} in
            1)
                echo -n "Status: " > ${outfile}
                echo ${json} | jsonpath "VirtualMachines[${vmid}].Status" >> ${outfile}
                echo -n "Path: " >> ${outfile}
                echo ${json} | jsonpath "VirtualMachines[${vmid}].Path" >> ${outfile}

                dialog --backtitle VirtBSD --title ${name} --textbox ${outfile} 8 40
                ;;
        esac
    done
}

function show_virtual_machines {
    json=$(curl -s http://${host}/vmapi/1/vm/list)
    outfile=$(mktemp)

    nvms=$(echo ${json} | jsonpath 'len:VirtualMachines')
    i=0
    dialogargs=("--backtitle" "VirtBSD" "--title" "Virtual Machines" "--menu" " " "0" "0" "0")
    for i in $(seq 0 $((${nvms}-1))); do
        vmname=$(echo ${json} | jsonpath "VirtualMachines[${i}].Name")
        dialogargs+=($((${i} + 1)))
        dialogargs+=(${vmname})
        i=$((${i} + 1))
    done

    dialog ${dialogargs} 2> ${dialogchoice}
    if [ ${?} = 1 ]; then
        return
    fi

    choice=$(cat ${dialogchoice})
    choice=$((${choice}-1))

    name=$(echo ${json} | jsonpath "VirtualMachines[${choice}].Name")
    manage_virtual_machine ${json} ${choice} ${name}

    rm -f ${outfile}
}

function main_screen {
    while [ true ]; do
        dialog --backtitle 'VirtBSD' --title "Main Screen" --nocancel --menu "" 0 0 0 \
            1 'Show Virtual Machines' \
            2 'Exit' \
            2> ${dialogchoice}

        choice=$(cat ${dialogchoice})

        case ${choice} in
            1)
                show_virtual_machines
                ;;
            2)
                return
                ;;
        esac
    done
}

main_screen
rm -f ${dialogchoice}
