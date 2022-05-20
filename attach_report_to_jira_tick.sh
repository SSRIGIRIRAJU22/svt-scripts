#!/usr/bin/bash

#-------------------------------------------------------------
#
# *** This script is for attaching the file to jira ticket ***
#
# Created by:- Saikumar Srigiriraju.
# Created on:- 10:05:2022
#
#-------------------------------------------------------------

BLUE='\033[94m'
EC='\033[0m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'

usage () {
        echo -e "\n${UNDERLINE}Usage:${EC}\n\t$0 [-u <user name>] [-p <password>] [-l <file location>] {-h help}\n"
        echo -e "${UNDERLINE}Supported Options:${EC}\n"
        echo -e "\t-u : user name"
        echo -e "\t-p : password."
        echo -e "\t-l : file location"
        echo -e "\t-t : jira ticket id"
        echo -e "${UNDERLINE}Example(s):${EC}\n\n\t$0 -u test -p abc123 -t CMC-1234 -l /data/reports/file.txt\n"
}


ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

[[ $# -eq 0 ]] && usage && exit 1


##
TEMP=`getopt -o "u:p:t:l:h" --long help -n $0 -- "$@"` || {
        usage
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

            -u)
                USER=$2;
                shift 2
                                ;;
            -p)
                PASSWORD=$2;
                shift 2
                                ;;
            -l)
                LOCATION=$2;
                shift 2
                                ;;
            -t)
                TICKET_ID=$2;
                shift 2
                                ;;
            -h)
                usage
                exit 0
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

[[ "$USER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$PASSWORD" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1
[[ "$LOCATION" == "" ]] && echo -e "\nOption: -l is missing.\n" && usage && exit 1

if [[ -f "$LOCATION" ]]
then
        curl --user $USER:$PASSWORD -H "X-Atlassian-Token: nocheck" -F "file=@${LOCATION}" -X POST "https://jira.rocketsoftware.com/rest/api/2/issue/${TICKET_ID}/attachments"
    if [[ $? -ne 0 ]]
    then
            exit 1
    fi
else
    echo "could not able to locate the give file."
    exit 1
fi