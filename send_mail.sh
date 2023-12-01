#!/usr/bin/bash

#-----------------------------------------------------------------------------
#
# *** This script is for sending mail alert to user using the mailx tool ***
#
#------------------------------------------------------------------------------


BLUE='\033[94m'
EC='\033[0m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'

usage () {
        echo -e "\n${UNDERLINE}Usage:${EC}\n\t$0 -s <subject> -b <body> -f <from address> -t <to address> [-h help]\n"
        echo -e "${UNDERLINE}Supported Options:${EC}\n"
        echo -e "\t-f : From address"
        echo -e "\t-t : To address\n\t\tTo send to multiple users, provide the mail address in comma separated"
        echo -e "\t-s : Subject of the mail"
        echo -e "\t-b : Mail body\n"
        echo -e "${UNDERLINE}Example(s):${EC}\n\n\t1)$0 -f mark@gmail.com -t henry@xyz.com -s 'Test mail' -b 'Hi, This is a test mail using mailx tool'\n\t2)$0 -f mark@gmail.com -t henry@xyz.com,joe@xyz.com -s 'Test mail' -b 'Hi, This is a test mail using mailx tool'\n"
}

##
TEMP=`getopt -o "f:t:s:b:" --long help -n $0 -- "$@"` || {
        usage
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

            -f)
                FROM_ADDR=$2;
                shift 2
                                ;;
            -t)
                TO_ADDR=$2;
                shift 2
                                ;;
            -s)
                MAIL_SUBJECT=$2;
                shift 2
                                ;;
            -b)
                MAIL_BODY=$2;
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


[[ "$FROM_ADDR" == "" ]] && echo -e "\nOption: -f is missing.\n" && usage && exit 1
[[ "$TO_ADDR" == "" ]] && echo -e "\nOption: -t is missing.\n" && usage && exit 1
[[ "$MAIL_SUBJECT" == "" ]] && echo -e "\nOption: -s is missing.\n" && usage && exit 1
[[ "$MAIL_BODY" == "" ]] && echo -e "\nOption: -b is missing.\n" && usage && exit 1

# command to send mail
echo "${MAIL_BODY}" | mail -s "${MAIL_SUBJECT}" -r "${FROM_ADDR}" "${TO_ADDR}"
