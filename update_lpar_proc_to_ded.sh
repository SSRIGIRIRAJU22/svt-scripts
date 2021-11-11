#!/usr/bin/bash

#-------------------------------------------------------------------
#
# *** This script is for converting the given lpar proc to ded. ***
#
# File Name :- update_lpar_proc_to_ded.sh
# Created on:- 22/07/2021
#
# Created by:- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#
#
#
#
#-------------------------------------------------------------------


UNDERLINE='\033[4m'
BLUE='\033[94m'
EC='\033[0m'
RED='\033[91m'
GREEN='\033[92m'
HMCUSER='hscpe'
HMCPASS="abcd1234"

usage () {

        echo -e "\n${UNDERLINE}Usage:${EC}"
        echo -e "\t$0 [-m CEC] [-l lpar] [-h hmc] [-u HMC user name] [-p HMC user pass]\n"
        echo -e "${UNDERLINE}Supported Options:${EC}\n"
        echo -e "\t-m : Power system host name or IP."
        echo -e "\t-l : LPAR host name or IP."
        echo -e "\t-h : HMC host name or IP."
        echo -e "\t-u : HMC user name. Default: hscpe"
        echo -e "\t-p : HMC user password. Default: abcd1234"
        echo -e "\n${UNDERLINE}Example:${EC}"
        echo -e "\n\t$0 -h 192.12.133.5 -u hscpe -p abcd1234 -m zepp20fp -l zepp20-lpar10\n"
        echo -e "Contact:- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)"
}

## spin function
spin () {
        while [ 1 ]
        do
                echo -ne "."
                sleep 2
        done
}

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

[[ $# -eq 0 ]] && usage && exit 1

##
TEMP=`getopt -o "m:h:l:u:p:" --long help -n $0 -- "$@"` || {
        echo "could not parse arguments"
        usage
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

            -m)
                    MACHINE=$2;
                    shift 2
                                    ;;
            -h)
                    HMC=$2;
                    shift 2
                                    ;;
            -u)
                    HMCUSER=$2;
                    shift 2
                                    ;;
            -p)
                    HMCPASS=$2;
                    shift 2
                                    ;;
            -l)
                    LPAR=$2
                    shift 2
                                    ;;
            --)
                    shift; break;
                                    ;;
            *)
                    usage
                    exit 1
                                    ;;
            --help)
                    usage
                    exit 0
                                    ;;
    esac
done

[[ "$MACHINE" == "" ]] && echo -e "\nOption: -m is missing.\n" && usage && exit 1
[[ "$HMC" == "" ]] && echo -e "\nOption: -h is missing.\n" && usage && exit 1
[[ "$LPAR" == "" ]] && echo -e "\nOption: -l is missing.\n" && usage && exit 1
[[ "$HMCUSER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$HMCPASS" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1

## validating the hmc.
echo ""
ECHO "Validating HMC: ${BLUE}$HMC${EC} ...\c"
ping -c3 $HMC > /dev/null 2>&1
if [[ $? -eq 0 ]]
then
        echo -e " ${GREEN}Passed${EC}"
else
        echo -e " ${RED}Fail${EC}"
        exit 1
fi

## validating CEC
ECHO "Validating CEC: ${BLUE}$MACHINE${EC} ...\c"
IS_CEC_CONNECTED_TO_HMC=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F name -m $MACHINE")

if [[ "$IS_CEC_CONNECTED_TO_HMC" != $MACHINE ]]
then
        echo -e " ${RED}Fail${EC}"
        echo -e "\n${RED}Error Msg:${EC} ${IS_CEC_CONNECTED_TO_HMC}"
        exit 1
fi

CEC_STATE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F state -m $MACHINE")

if [[ "$CEC_STATE" != 'Operating' ]]
then
        echo -e " ${RED}Fail${EC}"
        echo -e "\n${RED}Error Msg:${EC} ${CEC_STATE}"
        exit 1
else
        echo -e " ${GREEN}Passed${EC}"
fi

## validating lpar
ECHO "Discovering the LPAR: ${BLUE}${LPAR}${EC} ...\c"
IS_LPAR_EXIST=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name -m $MACHINE --filter lpar_names=$LPAR")

if [[ "$IS_LPAR_EXIST" != $LPAR ]]
then
        echo -e " ${RED}Fail${EC}"
        echo -e "\n${RED}Error Msg:${EC} ${IS_LPAR_EXIST}"
        exit 1
else
        echo -e " ${GREEN}Passed${EC}"
fi

ECHO "Getting the current proc mode for LPAR: ${BLUE}$LPAR${EC} ...\c"
CURRENT_PROC_MODE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -m $MACHINE -r prof --filter lpar_names=$LPAR -F proc_mode")
[[ $? -eq 0 ]] && echo -e " ${BLUE}$CURRENT_PROC_MODE${EC}"
if [[ $CURRENT_PROC_MODE == 'ded' ]]
then
        echo -e "Already LPAR: ${BLUE}$LPAR${EC} having the dedicated procs."
        exit 1
fi

## shutdown the lpar
ECHO "Shutting down the LPAR: ${BLUE}$LPAR${EC} ...\c"
LPAR_STATE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F state -m $MACHINE --filter lpar_names=$LPAR")

if [[ "$LPAR_STATE" != "Running" ]] || [[ "$LPAR_STATE" != "Open Firmware" ]]
then
        SHUTDOWN_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $LPAR --immed --force")
    sleep 4
    if [[ $? -eq 0 ]]
    then
            echo -e " ${GREEN}Passed${EC}"
    fi
else
        echo -e " ${GREEN}Passed${EC}"
fi

## Convert shared to ded proc
ECHO "Converting LPAR: ${BLUE}$LPAR${EC} proc to dedicated ...\c"
while :
do
GET_LPAR_STATE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F state -m $MACHINE --filter lpar_names=$LPAR")

if [[ $GET_LPAR_STATE == "Not Activated" ]]
then
        break
else
        sleep 5
fi
done

CONVERT_PROC_TO_DED=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_name=$LPAR,proc_mode=ded,sharing_mode=keep_idle_procs\" --force")
[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}Passed${EC}"

## Activate lpar
ECHO "Activating LPAR: ${BLUE}$LPAR${EC} ...\c"
sleep 5
ACTIVATE_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $MACHINE -n $LPAR")
[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" && echo -e "Error Msg:- ${RED}${ACTIVATE_LPAR}${EC}" || echo -e " ${GREEN}Passed${EC}"

ECHO "Getting the current proc mode for LPAR: ${BLUE}$LPAR${EC} ...\c"
NEW_PROC_MODE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -m $MACHINE -r prof --filter lpar_names=$LPAR -F proc_mode")

[[ $? -eq 0 ]] && echo -e " ${BLUE}$NEW_PROC_MODE${EC}"
ECHO "Finished."
exit 0
