#!/usr/bin/bash

#-----------------------------------------------------------------------
#
# *** This script is for converting the given lpar proc to shared. ***
#
# Created on :- 12/07/2021
# Created by :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#
#
#
#----------------------------------------------------------------------


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

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

## spin function
spin () {
        while [ 1 ]
        do
                echo -ne "."
                sleep 2
        done
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

if [[ "$#" -ne 0 ]]
then
        echo ""
        usage
        exit 1
fi

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
        echo -e " ${RED}Failed${EC}"
        exit 1
fi

## validating CEC
ECHO "Validating CEC: ${BLUE}$MACHINE${EC} ...\c"
IS_CEC_CONNECTED_TO_HMC=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F name -m $MACHINE")

if [[ "$IS_CEC_CONNECTED_TO_HMC" != $MACHINE ]]
then
        echo -e " ${RED}Failed${EC}"
        echo -e "\n${RED}Error Msg:${EC} ${IS_CEC_CONNECTED_TO_HMC}"
        exit 1
fi

CEC_STATE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F state -m $MACHINE")

if [[ "$CEC_STATE" != 'Operating' ]]
then
        echo -e " ${RED}Failed${EC}"
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
        echo -e " ${RED}Failed${EC}"
        echo -e "\n${RED}Error Msg:${EC} ${IS_LPAR_EXIST}"
        exit 1
else
        echo -e " ${GREEN}Passed${EC}"
fi

ECHO "Getting the current proc mode for LPAR: ${BLUE}$LPAR${EC} ...\c"
CURRENT_PROC_MODE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -m $MACHINE -r prof --filter lpar_names=$LPAR -F proc_mode")
[[ $? -eq 0 ]] && echo -e " ${BLUE}$CURRENT_PROC_MODE${EC}"
if [[ $CURRENT_PROC_MODE == 'shared' ]]
then
        echo -e "Failure Analysis:- Already LPAR: ${BLUE}$LPAR${EC} having the shared proc."
        exit 1
fi

## shutdown the lpar
ECHO "Shutting down the LPAR: ${BLUE}$LPAR${EC} ...\c"
LPAR_STATE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F state -m $MACHINE --filter lpar_names=$LPAR")

if [[ "$LPAR_STATE" = "Running" ]] || [[ "$LPAR_STATE" = "Open Firmware" ]]
then
            SHUTDOWN_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $LPAR --immed --force")
        sleep 10
        if [[ -z $SHUTDOWN_LPAR ]]
        then
                echo -e " ${GREEN}Passed${EC}"
        fi
else
        sleep 10
        echo -e " ${GREEN}Passed${EC}"
fi

## Convert ded proc to shared
ECHO "Converting ${BLUE}$LPAR${EC} proc to shared ...\c"
while true
do
    GET_LPAR_STATE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F state -m $MACHINE --filter lpar_names=$LPAR")

    if [[ $GET_LPAR_STATE == "Not Activated" ]]
    then
            break
    else
            sleep 5
    fi
done

GET_HMC_VERSION=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lshmc -V | grep \"Service Pack:\" | cut -d' ' -f4" 2>&1)
if [[ $? == 0 ]]
then
        if [[ -n "$GET_HMC_VERSION" ]]
        then
                if [[ $GET_HMC_VERSION -lt 1010 ]]
                then
                        CONVERT_PROC_TO_SHARED=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_name=$LPAR,proc_mode=shared,sharing_mode=uncap,uncap_weight=128,min_proc_units=0.1,desired_proc_units=0.1,max_proc_units=0.15\" --force -p $LPAR" 2>&1)
                        if [[ $? -eq 0 ]]
                        then
                                sleep 5
                                echo -e " ${GREEN}Passed${EC}"
                        else
                                echo -e " ${RED}Failed${EC}"
                                echo "Error Msg:- $CONVERT_PROC_TO_SHARED"
                        fi
                elif [[ $GET_HMC_VERSION -ge 1010 ]]
                then
                        CONVER=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_name=$LPAR,proc_mode=shared,sharing_mode=uncap,uncap_weight=128,min_proc_units=0.1,desired_proc_units=0.1,max_proc_units=0.15\" --force" 2>&1)
                        if [[ $? -eq 0 ]]
                        then
                                sleep 5
                                echo -e " ${GREEN}Passed${EC}"
                        else
                                echo -e " ${RED}Failed${EC}"
                        fi
                else
                        echo -e " ${RED}Failed${EC}"
                fi
        else
                echo -e "${RED}Failed${EC}"
        fi
else
        echo -e "${RED}Failed${EC}"
        echo "Error Msg:- ${GET_HMC_VERSION}"
fi

## Activate lpar
ECHO "Activating LPAR: ${BLUE}$LPAR${EC} ...\c"
ACTIVATE_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $MACHINE -n $LPAR")

if [[ -z $ACTIVATE_LPAR ]]
then
        sleep 10
        echo -e " ${GREEN}Passed${EC}"
fi

ECHO "Getting the current proc mode for LPAR: ${BLUE}$LPAR${EC} ...\c"
NEW_PROC_MODE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -m $MACHINE -r prof --filter lpar_names=$LPAR -F proc_mode")
[[ $? -eq 0 ]] && echo -e " ${BLUE}$NEW_PROC_MODE${EC}"
ECHO "Finished."
exit 0
