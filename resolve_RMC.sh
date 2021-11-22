#!/usr/bin/bash

#-------------------------------------------------------------------------
#
# *** This script will try to bring the RMC to active for given lpar. ***
#
# File Name  : resolve_RMC.sh
# Created On : 18 July 2021
# Creatd by  : Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#
#
#
# Bug fix and enhancement
# -----------------------
# 21 July 2021 : made option -u as optional.
#
#
#
#-------------------------------------------------------------------------


USER='root'
BLUE='\033[94m'
EC='\033[0m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'
COUNT=0

## RMC commands
CHECKING_STATUS_OF_MANAGED_NODES="/usr/sbin/rsct/bin/rmcdomainstatus -s ctrmc"
CHECKING_RMC_STATUS="lssrc -a | grep rsct"
STOP_RMC_DAEMONS="/usr/sbin/rsct/bin/rmcctrl -z"
ADD_ENTRY_INITTAB_START_DAEMONS="/usr/sbin/rsct/bin/rmcctrl -A"
ENABLES_DAEMONS_FOR_REMOTE_CLIENT_CONNECTION="/usr/sbin/rsct/bin/rmcctrl -p"
RECRATE_RMC_CONFIGURATION="/usr/sbin/rsct/install/bin/recfgct"

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

## usage function
usage ()
{
    echo -e "${UNDERLINE}Usage:${EC}\n\t${0} [-m <LPAR hostname | IP>] [-u <user>] [-p <password>] {-h <help>}\n"
    echo -e "${UNDERLINE}Supported Options:${EC}\n"
    echo -e "\t-m : LPAR host name or IP"
    echo -e "\t-u : LPAR user name. Default: root"
    echo -e "\t-p : LPAR user password"
    echo -e "\t-h : help\n"
    echo -e "${UNDERLINE}Example:${EC}\n\t$0 -m 192.168.12.1 -u root -p abc123\n"
    echo -e "Contact:- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)"

}

## spin function
spin () {
        while [ 1 ]
        do
                echo -ne "."
                sleep $1
        done
}

[[ $# -eq 0 ]] && usage && exit 1
##
TEMP=`getopt -o "m:u:p:h" -n $0 -- "$@"`

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

            -m)
                MACHINE=$2;
                shift 2
                                ;;
            -u)
                USER=$2;
                shift 2
                                ;;
            -p)
                PASSWORD=$2;
                shift 2
                                ;;
            -h)
                echo ""
                usage
                exit 0
                                ;;
            --)
                shift; break;
                                ;;
            *)
                echo ""
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
[[ "$USER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$PASSWORD" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1

## verifying the ping test
echo ""
ECHO "Validating LPAR: ${BLUE}$MACHINE${EC} ... \c"
ping -c3 $MACHINE > /dev/null

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}\n" && exit 1 || echo -e "${GREEN}Passed${EC}"

## host password validation
ECHO "Validating LPAR password ... \c"
sshpass -p $PASSWORD ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o LogLevel=quiet $USER@$MACHINE "echo ssk" > /dev/null

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && echo "Failure Analysis:- Invalid Password: ${PASSWORD}" && exit 1 || echo -e "${GREEN}Passed${EC}"

ECHO "Checking the managed nodes for ${BLUE}$MACHINE${EC} ... \c"
FCMD=$(sshpass -p $PASSWORD ssh -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o LogLevel=quiet $USER@$MACHINE "$CHECKING_STATUS_OF_MANAGED_NODES" 2>&1)

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && echo -e "Error Msg:- ${RED}$FCMD${EC}\n" || echo -e "${GREEN}Passed${EC}"

ECHO "Stoping the RMC deamons ... \c"
SCMD=$(sshpass -p $PASSWORD ssh -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o LogLevel=quiet $USER@$MACHINE "$STOP_RMC_DAEMONS")

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && echo -e "Error Msg:- ${RED}$SCMD${EC}\n" && COUNT=$((COUNT+1)) && exit 1 || echo -e "${GREEN}Passed${EC}"

ECHO "Adding entry in inittab to start the daemons ... \c"
TCMD=$(sshpass -p $PASSWORD ssh -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o LogLevel=quiet $USER@$MACHINE "$ADD_ENTRY_INITTAB_START_DAEMONS" 2>&1)

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && COUNT=$((COUNT+1)) && echo -e "Error Msg:- ${RED}$TCMD${EC}\n" || echo -e "${GREEN}Passed${EC}"

ECHO "Enabling daemons for remote client connection ... \c"
FO_CMD=$(sshpass -p $PASSWORD ssh -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o LogLevel=quiet $USER@$MACHINE "$ENABLES_DAEMONS_FOR_REMOTE_CLIENT_CONNECTION" 2>&1)

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && COUNT=$((COUNT+1)) && echo -e "Error Msg:- ${RED}$FO_CMD${EC}\n" || echo -e "${GREEN}Passed${EC}"

ECHO "Re-creating RMC configuration ... \c"
FI_CMD=$(sshpass -p $PASSWORD ssh -k -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -o LogLevel=quiet $USER@$MACHINE "$RECRATE_RMC_CONFIGURATION" 2>&1)

[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && COUNT=$((COUNT+1)) && echo -e "Error Msg:- ${RED}$FI_CMD${EC}\n" || echo -e "${GREEN}Passed${EC}"

ECHO "Finished.\n"
if [[ $COUNT -eq 0 ]]
then
    echo "Note1: Wait for some time to get the RMC up."
    echo "Note2: If the RMC is not up after some time there mightbe some other issue."
    exit 0
else
    echo "Note: RMC Commands execution did not success, failed to bring the RMC up."
    exit 1
fi
