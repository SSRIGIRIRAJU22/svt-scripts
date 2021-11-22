#!/usr/bin/bash

#-------------------------------------------------------------------------
#
# *** This tools is for managing the HTX on the given lpar. ***
#
# Created by:- Saikumar Srigiriraju.
# Created on:- 13:06:2021
#
# Bug Fixes:
# ----------
# 14 July 2021 : In usage fun. Upper case 'P' is changed to Lower case 'p'.
# 17 July 2021 : Corrected the spelling mistake (Stopping to Stoping).
# 18 July 2021 : Code refractred.
# 22 July 2021 : Added timeout for the HTX commands.
#-------------------------------------------------------------------------


BLUE='\033[94m'
EC='\033[0m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'

# HTX commands
STATUS_HTX="hcl -status"
STOP_HTX="hcl -shutdown"
ACTIVATE_HTX="hcl -run -mdt mdt.bu"


usage () {
        echo -e "\n${UNDERLINE}Usage:${EC}\n\t$0 [-m <lpar IP | lpar hostname>] [-p <lpar password>] [-o <start | status | stop>] {-h help} {-v verbose}\n"
        echo -e "${UNDERLINE}Supported Options:${EC}\n"
        echo -e "\t-m : LPAR hostname or LPAR IP"
        echo -e "\t-p : LPAR password."
        echo -e "\t-v : Verbose."
        echo -e "\t-o : Operation type"
        echo -e "\t\ta) start  : Activate HTX."
        echo -e "\t\tb) stop   : Stop the HTX."
        echo -e "\t\tc) status : HTX staus."
        echo -e "${UNDERLINE}Example(s):${EC}\n\n\t$0 -m 10.20.30.40  -p abc123 -o start\n"
}

## spin function
spin () {
        while [ 1 ]
        do
                echo -ne "."
                sleep 30
        done
}

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}


Activate_HTX () {

    ECHO "Activating HTX on ${BLUE}$MACHINE${EC} ...\c"
    res=$(timeout 60s sshpass -p $PASSWORD ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@$MACHINE "$ACTIVATE_HTX" 2>&1)
    [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" && echo -e "$res" && exit 1 || echo -e " ${GREEN}Passed${EC}"
}

Stop_HTX () {

    ECHO "Stoping the HTX on ${BLUE}$MACHINE${EC} ...\c"
    res=$(timeout 60s sshpass -p $PASSWORD ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@$MACHINE "$STOP_HTX" 2>&1)
    [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" && echo -e "$res" && exit 1 || echo -e " ${GREEN}Passed${EC}"
}

get_HTX_status () {

    ECHO "Getting the HTX status for ${BLUE}$MACHINE${EC} ...\c"
    res=$(timeout 60s sshpass -p $PASSWORD ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@$MACHINE "$STATUS_HTX" 2>&1)
    [[ -z "$res" ]] && echo -e " ${RED}Failed${EC}" && echo -e "$res" && exit 1 || echo -e " ${GREEN}Passed${EC}"
}


[[ $# -eq 0 ]] && usage && exit 1

##
TEMP=`getopt -o "m:p:o:hv" --long help -n $0 -- "$@"` || {
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
            -p)
                PASSWORD=$2;
                shift 2
                                ;;
            -o)
                OPERATION=$2;
                shift 2
                                ;;
            -h)
                usage
                exit 0
                                ;;
            -v)
                VERBOSE='YES';
                shift 1
                                ;;

            --)
                shift; break;
                                ;;
            *)
                usage
                exit 1
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
[[ "$PASSWORD" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1

if [[ "$OPERATION" == "" ]]
then
    echo -e "\nOption: -o is missing.\n" && usage && exit 1

elif [[ $OPERATION != "start" ]] && [[ $OPERATION != "stop" ]] && [[ $OPERATION != "status" ]]
then
    usage
    exit 1
fi

## validating the lpar
echo ""
ECHO "Validating the Lpar: ${BLUE}$MACHINE${EC} ...\c"
ping -c3 $MACHINE > /dev/null 2>&1
[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" && exit 1 || echo -e " ${GREEN}Passed${EC}"

## validating lpar password
ECHO "Validating LPAR password ...\c"
sshpass -p $PASSWORD ssh -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  root@$MACHINE "echo 'ssk'" > /dev/null
[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" && exit 1 || echo -e " ${GREEN}Passed${EC}"

## HTX action
if [[ $OPERATION == 'start' ]]
then
    Activate_HTX
elif [[ $OPERATION == 'status' ]]
then
    get_HTX_status
elif [[ $OPERATION == 'stop' ]]
then
     Stop_HTX
fi

ECHO "Finished."
if [[ $VERBOSE == 'YES' ]]
then
    echo "$res"
fi
exit 0
