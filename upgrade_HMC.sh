#!/usr/bin/bash

#-----------------------------------------------------------------------
#
# *** This tool is for upgrading the HMC ***
#
#
# File Name  :- upgrade_HMC.sh
# Created on :- 20/10/2022
#
#
# Created by :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#----------------------------------------------------------------------

HMCPASS='abcd1234'
HMCUSER='hscpe'
WHITE='\e[97m'
EC='\033[0m'
BLUE='\033[94m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'
Install_OpenCert="NO"
HMC_OpenCert=""


# usage function.
usage () {
    echo -e "${UNDERLINE}Usage:${EC}"
    echo -e "\n\t$0 [-h <HMC>] [-u <HMC user name>] [-p <HMC password>] [-b <build path>] [--install-OpenCert] [ --OpenCert <build path>]\n"
    echo -e "${UNDERLINE}Supported Options:${EC}\n"
    echo -e "\t-h : HMC host name or IP."
    echo -e "\t-u : HMC user name. ${WHITE}Default: hscpe${EC}"
    echo -e "\t-p : HMC user password. ${WHITE}Default: abcd1234${EC}"
    echo -e "\t-b : Provide the build path. Eg: HMC10.2.1030.0/2210191530/ppc64le/network_install\n\n"
    echo -e "\t--install-OpenCert : To install opencert for HMC."
    echo -e "\t--Opencert         : Provide the open cert build path. Eg: OpenCert/HMC-10-2-OpenCert.iso"
    echo -e "\t--help             : help.\n"
    echo -e "${UNDERLINE}Example:${EC}"
    echo -e "\n\t$0 -h 192.12.133.5 -u hscpe -p abcd1234 -b HMC10.2.1030.0/2210191530/ppc64le/network_install\n"
    echo -e "Contact:- ${WHITE}Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)${EC}"
}

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

TEMP=`getopt -o "h:b:u:p:" -l "install-OpenCert,OpenCert:,help" -n $0 -- "$@"` || {
        echo ""
        usage
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in
            -h)
                    HMC=$2;
                    shift 2
                                    ;;
            -b)
                    BUILD=$2;
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
            --install-OpenCert)
                    Install_OpenCert="YES";
                    shift 1
                                    ;;
            --OpenCert)
                    HMC_OpenCert=$2;
                    shift 2
                                    ;;
            --)
                    shift; break;
                                    ;;
        --help)
                    usage
                    exit 0
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

## validating the passed options and its values.
[[ "$BUILD" == "" ]] && echo -e "\nOption: -b is missing.\n" && usage && exit 1
[[ "$HMC" == "" ]] && echo -e "\nOption: -h is missing.\n" && usage && exit 1
[[ "$HMCUSER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$HMCPASS" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1
[[ "${Install_OpenCert}" == "YES" ]] && [[ "${HMC_OpenCert}" == "" ]] && echo -e "\nOption: --OpenCert is missing.\n" && usage && exit 1

echo ""
ECHO "Validating HMC IP: ${BLUE}${HMC}${EC} ... \c"
ping -c3 $HMC > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- ping to the HMC: ${HMC} failed."
        exit 1
else
        echo -e "${GREEN}Passed${EC}"
fi

ECHO "Validating the HMC credentials ...\c"
VALIDATE_CRED=$(sshpass -p $HMCPASS ssh -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "echo ssk")

[[ $? -ne 0 ]] && echo -ne " ${RED}Failed${EC}\n\n${UNDERLINE}Failure Analysis:${EC}\n\tVerify the parsed HMC credentials once.\n\t\t> ${HMC_USER}\n\t\t> $HMC_PASS\n\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

ECHO "Get the current version of HMC ...\c"
CURRENT_HMC_VERSION=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "lshmc -v | grep RM | cut -d' ' -f 2")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$CURRENT_HMC_VERSION${EC}"

ECHO "Get the HMC current build level ...\c"
CURRENT_HMC_BUILD_LEVEL=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "lshmc -V | grep 'HMC Build level' | cut -d' ' -f 4")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$CURRENT_HMC_BUILD_LEVEL${EC}"

#INPUT_BUILD=$(echo "$BUILD" | cut -d'-' -f 3)
#[[ $INPUT_BUILD -le $CURRENT_HMC_BUILD_LEVEL ]] && echo -e "\n${UNDERLINE}Failure Analysis:${EC}\n\n\tHMC is already on the latest build or same level,\n\tthan given one:- ${RED}${BUILD}${EC}\n" && exit 1

ECHO "Get the architecture of HMC ...\c"
HMC_ARCHITECTURE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "uname -i")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$HMC_ARCHITECTURE${EC}"

ECHO "Upgrading to ... ${BLUE}${BUILD}${EC}"


recover_altboot () {

        ECHO "Disabling the altdiskboot for HMC ...\c"
        ALDISKBOOT=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "chhmc -c altdiskboot -s disable --mode upgrade &")
        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" || echo -e " ${GREEN}Passed${EC}"
}


upgrade_HMC () {

        ECHO "Initiating saveupgdata command ...\c"

        INITIATE_BACKUP=$(sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  "${HMCUSER}"@"${HMC}" "saveupgdata -r disk")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $INITIATE_BACKUP\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Downloading the n/w files from ftp/sftp server ...\c"

        DOWNLOAD_FILES=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "getupgfiles -r nfs -h 9.3.147.71 -l /HMCImages -d ${BUILD}")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $DOWNLOAD_FILES\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Initiating altdiskboot command ...\c"
        INITIATE_ALTDISKBOOT=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "chhmc -c altdiskboot -s enable --mode upgrade")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $INITIATE_ALTDISKBOOT\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Initiating HMC reboot command ...\c"
        INITIATE_REBOOT=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@${HMC} "hmcshutdown -r -t now")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $INITIATE_REBOOT\n" && recover_altboot && exit 1 || echo -e " ${GREEN}Passed${EC}"

}

upgrade_HMC

## spin function
spin () {
        while [ 1 ]
        do
                echo -ne "."
                sleep $1
        done
}


final_check () {

ECHO "Rebooting the HMC .\c"
## calling the spin function
spin 10 &
# collecting the PID and running it in background
T_PID=$! && disown

count=0
while true
do
        sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "echo 'ssk'" > /dev/null 2>&1
        if [[ $? -eq 0 ]]
        then
                sleep 65 ; count=$((count+1))
                if [[ $count -gt 7 ]]
                then
                        ## kill process
                        kill -9 ${T_PID} 2> /dev/null

                        echo -e " ${RED}Failed${EC}\n" ; exit 1
                fi
        else
                ## kill process
                kill -9 ${T_PID} 2> /dev/null

                echo -e " ${GREEN}Passed${EC}" ; break
        fi
done


ECHO "Waiting for HMC to come up .\c"
## calling the spin function and running it in backgroun
spin 300 &
# storing the PID and hiding the process
FO_PID=$! && disown

F_count=0
while true
do
IS_HMC_UP=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "echo 'ssk'")
if [[ $? -ne 0 ]]
then
        sleep 120 ; F_count=$((F_count+1))
        if [[ ${F_count} -gt 28 ]]
        then
                ## kill process
                kill -9 ${FO_PID} 2> /dev/null
                echo -e " ${RED}Failed${EC}\n\nTime Out .. While waiting for HMC to come up after reboot.\n" ; exit 1
        fi
else
        ## kill process
        kill -9 $FO_PID 2> /dev/null

        echo -e " ${GREEN}Passed${EC}" ; break
fi
done


ECHO "Waiting for command server to come up .\c"
## calling the spin function and running it in backgroun
spin 20 &
# stroing the PID and hiding it
FI_PID=$! && disown

S_count=0
while true
do
IS_CMD_SERVER_UP=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@$HMC "lshmc -v" > /dev/null 2>&1)
if [[ $? -ne 0 ]]
then
        sleep 60 ; S_count=$((S_count+1))
        if [[ $S_count -gt 7 ]]
        then
                ## kill process
                kill -9 $FI_PID 2> /dev/null

                echo -e " ${RED}Failed${EC}\n\nTime Out .. While waiting for command to start on HMC.\n" ; exit 1
        fi
else
        ## kill process
        kill -9 $FI_PID 2> /dev/null

        echo -e " ${GREEN}Passed${EC}" ; break
fi
done

}

# calling the final check function
final_check

ECHO "After upgrade HMC version ...\c"
NEW_HMC_VERSION=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@$HMC "lshmc -v | grep RM | cut -d' ' -f 2")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$NEW_HMC_VERSION${EC}"


ECHO "After upgrade HMC build level ...\c"
NEW_HMC_BUILD_LEVEL=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@$HMC "lshmc -V | grep 'HMC Build level' | cut -d' ' -f 4")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$NEW_HMC_BUILD_LEVEL${EC}"


if [[ "$Install_OpenCert" == "YES" ]]
then

    ECHO "Installing the OpenCert for HMC"
    ECHO "Initiating the command to install OpenCert ... \c"
    OPENCERT=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMCUSER}@$HMC "updhmc -t nfs -r -h hmcnfsbuild.isst.aus.stglabs.ibm.com -l /HMCImages -f ${HMC_OpenCert}")

    [[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && echo -e "${RED}${OPENCERT}${EC}" || echo -e "${GREEN}Passed${EC}"

    # calling the final check function
    final_check
fi


ECHO "Finished.\n"
exit 0
