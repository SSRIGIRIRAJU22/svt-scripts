#!/usr/bin/bash

#------------------------------------------------------------------------
#
#  *** This tool is for updating/upgrading the hmc. ***
#
# File Name  : update_hmc.sh
# Created On : 27/June/2021.
#
#
#
# Created By :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#------------------------------------------------------------------------


## required variables.
EC='\033[0m'
RED='\033[91m'
BLUE='\033[94m'
GREEN='\033[92m'
UNDERLINE='\033[4m'
ISO_FILE_PATH='/data/images/HMC/'
IMAGE_LOCATION_ON_HMC="/home/"
FTP_SERVER='dendevcmcdev01.dev.rocketsoftware.com'
trap "trap_fun" SIGINT


usage () {

        echo -e "${UNDERLINE}Usage:${EC}\n"
        echo -e "\t$0 [-h <hmc ip| hmc hostname>] [-b <build info>] [-u <hmc user name>] [-p <hmc password>] [--ftp_user <user name>] [--ftp_pass <password>] {--help <help>}\n"
        echo -e "${UNDERLINE}Note:${EC}\n\tAll the below parameters need to be passed, except one long option (--help)\n"
        echo -e "${UNDERLINE}Valid Options:${EC}\n\t\n\t${UNDERLINE}Short Options${EC}\n\n\t-h : hmc ip | hmc hostname\n\t-b : build\n\t-u : hmc user name\n\t-p : hmc password\n"
        echo -e "\t${UNDERLINE}Long Options${EC}\n\n\t--ftp_user : ftp server username\n\t--ftp_pass : ftp server password\n\t--help     : help\n"
        echo -e "${UNDERLINE}Example:${EC}\n"
        echo -e "\t1. $0 -h 10.33.20.1 -b HMC-10.1.1010.0-2106201112-ppc64le.iso -u test -p password --ftp_user ssrigiriraju --ftp_pass abc123\n"
        echo -e "\t2. $0 -h 10.33.20.1 -b 2106181112 -u test -p password --ftp_user ssrigiriraju --ftp_pass abc123\n"
        echo -e "${UNDERLINE}Aditional Info:${EC}\n\n\tContact :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)\n\n"
}


trap_fun () {

        echo ""
        ECHO "Human interrupt occured from keyboard, Initiated cleanup."

        ## validate file exist or not.
        sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} " [[ -f "${IMAGE_LOCATION_ON_HMC}${HMC_USER}\/${BUILD}" ]] " > /dev/null 2>&1

        if [[ $? -eq 0 ]]
        then
                sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@$HMC " rm -rf ${IMAGE_LOCATION_ON_HMC}${HMC_USER}/${BUILD} & " 2>&1
        fi

        [[ $BUILD =~ ^[0-9]+$ ]] && recover_altboot
        ECHO "Cleanup is done.\n"
        exit 1

}

## spin function
spin () {
        while [ 1 ]
        do
                echo -ne "."
                sleep $1
        done
}

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

update_HMC () {

        ## find the path to iso
        BUILD_FULL_PATH=$(sshpass -p $FTP_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${FTP_USER}@${FTP_SERVER} "find ${ISO_FILE_PATH} -name ${BUILD}")

        ## validate file exist or not.
        sshpass -p ${FTP_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${FTP_USER}@${FTP_SERVER} " [[ -f ${BUILD_FULL_PATH} ]] " > /dev/null 2>&1

        [[ $? -ne 0 ]] && echo -e " \nFile:- ${RED}$BUILD${EC}\nNot found on this location :- ${BLUE}${FTP_SERVER}:${ISO_FILE_PATH}${EC}\n" && exit 1

        ECHO "Downloading the ISO image from ftp server to HMC .\c"
        ## calling the spin function and running it in backgroun
        spin 8 &
        # storing the PID and running in background
        F_PID=$! && disown

        ISO_STATUS=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@$HMC "sshpass -p $FTP_PASS scp -q -r -oStrictHostKeyChecking=no $FTP_USER@$FTP_SERVER:${BUILD_FULL_PATH} ${IMAGE_LOCATION_ON_HMC}${HMC_USER}/" 2>&1)

        if [[ $ISO_STATUS =~ "command not found" ]]
        then
                        kill -9 $F_PID 2> /dev/null
                        echo -ne " ${RED}Failed${EC}"
                        echo -ne "\n\n"
                        echo "#-----------------------------------------------------------------------------------------"
                        echo -ne "Failure Analysis:-\n\tIssue:- sshpass command not found.\n"
                        echo -ne "\nPlease fallow below steps to resolve this issue and try again.\n\t1. Login to HMC.\n\t2. Now switch to root user.\n\t3. Try firing this command: ${BLUE}cp /usr/bin/sshpass /usr/hmcrbin/${EC}\n"
                        echo -ne "\nStill facing issue:\n\tContact :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)\n"
                        echo -e "\nExample:\n\t> [root@waldevcmchmc02 ~] # cp /usr/bin/sshpass /usr/hmcrbin/"
                        echo "#-----------------------------------------------------------------------------------------"
                        exit 1
        fi

        ## kill process
        kill -9 $F_PID 2> /dev/null

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" && exit 1

        ## validate file exist or not.
        sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} " [[ -f "${IMAGE_LOCATION_ON_HMC}${HMC_USER}\/${BUILD}" ]] " > /dev/null 2>&1

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

    ECHO "Initiating HMC updade .\c"
    ## calling the spin function and running it in backgroun
    spin 9 &
    ## storing the spin function PID
    S_PID=$!
    ## hiding the killed process information
    disown

    # Running updhmc command.
    T_CMD=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@$HMC "updhmc -t disk -f  ${IMAGE_LOCATION_ON_HMC}${HMC_USER}/${BUILD} -r" 2>/dev/null)
    if [[ $? -ne 0 ]]
    then
         ## kill process
         kill -9 $S_PID 2> /dev/null

         echo -e " ${RED}Failed${EC}"
         remove_ISO
         echo -ne "\n\nFailure Analysis:- ${RED}updhmc -t disk -f  ${IMAGE_LOCATION_ON_HMC}${HMC_USER}/${BUILD} -r${EC} command retured exit code 1.\n\n"
         echo -ne "Error Msg:- $T_CMD\n"
         exit 1
    else
         kill -9 $S_PID 2> /dev/null
         echo -e " ${GREEN}Passed${EC}"
    fi

}


upgrade_HMC () {

        ECHO "Verifying build exist or not on ftp server ...\c"
        BUILD_PATH=$(sshpass -p $FTP_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  $FTP_USER@$FTP_SERVER "find $ISO_FILE_PATH -name $BUILD")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nBuild not found on ftp server." && exit 1

        sshpass -p ${FTP_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${FTP_USER}@${FTP_SERVER} " [[ -d ${BUILD_PATH}/${HMC_ARCHITECTURE}/network_install ]] " > /dev/null 2>&1

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Initiating saveupgdata command ...\c"

        INITIATE_BACKUP=$(sshpass -p "$HMC_PASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  "${HMC_USER}"@"${HMC}" "saveupgdata -r disk")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $INITIATE_BACKUP\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Downloading the n/w files from ftp to HMC ...\c"

        UPGFILE="${BUILD_PATH}/${HMC_ARCHITECTURE}/network_install"
        DOWNLOAD_FILES=$(sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMC_USER}@${HMC} "getupgfiles -r sftp -h ${FTP_SERVER} -u ${FTP_USER} --passwd $FTP_PASS -d $UPGFILE")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $DOWNLOAD_FILES\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Initiating altdiskboot command ...\c"
        INITIATE_ALTDISKBOOT=$(sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "chhmc -c altdiskboot -s enable --mode upgrade")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $INITIATE_ALTDISKBOOT\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

        ECHO "Initiating HMC reboot command ...\c"
        INITIATE_REBOOT=$(sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "hmcshutdown -r -t now")

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\nError Msg:- $INITIATE_REBOOT\n" && recover_altboot && exit 1 || echo -e " ${GREEN}Passed${EC}"

}


recover_altboot () {

        ECHO "Disabling the altdiskboot for HMC ...\c"
        ALDISKBOOT=$(sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "chhmc -c altdiskboot -s disable --mode upgrade &")
        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" || echo -e " ${GREEN}Passed${EC}"
}

remove_ISO () {

        ## removing iso from hmc.
        ECHO "Removing ISO from HMC ...\c"

        sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@$HMC " rm -rf ${IMAGE_LOCATION_ON_HMC}${HMC_USER}/${BUILD} " 2>&1

        [[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" || echo -e " ${GREEN}Passed${EC}"
}


##
TEMP=`getopt -o "h:b:u:p:" -l "ftp_user:,ftp_pass:,help" -n $0 -- "$@"` || {
        usage
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
        case "$1" in

                -h)
                      HMC=$2
                      shift 2
                                        ;;
                -b)

                      BUILD=$2
                      shift 2
                                        ;;
                -u)
                      HMC_USER=$2
                      shift 2
                                        ;;
                -p)
                      HMC_PASS=$2
                      shift 2
                                        ;;
        --ftp_user)
                      FTP_USER=$2
                      shift 2
                                        ;;
        --ftp_pass)
                      FTP_PASS=$2
                      shift 2
                                        ;;
            --help)
                      usage
                      exit 0
                                        ;;
               --)
                      shift; break;
                                        ;;
                *)
                      usage
                      exit 1
        esac
done

if [[ "$#" -ne 0 ]]
then
        echo ""
        usage
        exit 1
fi

[[ "$HMC" == "" ]] && echo -e "\nOption: -h is missing.\n" && usage && exit 1
[[ "$BUILD" == "" ]] && echo -e "\nOption: -b is missing.\n" && usage && exit 1
[[ "$HMC_USER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$HMC_PASS" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1
[[ "$FTP_USER" == "" ]] && echo -e "\nOption: --ftp_user is missing.\n" && usage && exit 1
[[ "$FTP_PASS" == "" ]] && echo -e "\nOption: --ftp_pass is missing.\n" && usage && exit 1

if [[ $BUILD =~ ^[0-9]+$ ]]
then
        true
elif [[ "${BUILD: -4}" == ".iso" ]]
then
        true
else
        echo -ne "\nInvalid ISO:- ${RED}${BUILD}${EC}\nParse valid ISO file.\n\n" && exit 1
fi

## validate hmc.
echo ""; ECHO "Validating the HMC IP: ${BLUE}${HMC}${EC} ...\c"
ping -c3 $HMC > /dev/null 2>&1

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"


ECHO "Validating the HMC credentials ...\c"
VALIDATE_CRED=$(sshpass -p $HMC_PASS ssh -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "echo ssk")

[[ $? -ne 0 ]] && echo -ne " ${RED}Failed${EC}\n\n${UNDERLINE}Failure Analysis:${EC}\n\tVerify the parsed HMC credentials once.\n\t\t> ${HMC_USER}\n\t\t> $HMC_PASS\n\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

ECHO "Getting the current version of HMC ...\c"
CURRENT_HMC_VERSION=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "lshmc -v | grep RM | cut -d' ' -f 2")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$CURRENT_HMC_VERSION${EC}"

ECHO "Getting the HMC current build level ...\c"
CURRENT_HMC_BUILD_LEVEL=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "lshmc -V | grep 'HMC Build level' | cut -d' ' -f 4")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$CURRENT_HMC_BUILD_LEVEL${EC}"

INPUT_BUILD=$(echo "$BUILD" | cut -d'-' -f 3)
[[ $INPUT_BUILD -le $CURRENT_HMC_BUILD_LEVEL ]] && echo -e "\n${UNDERLINE}Failure Analysis:${EC}\n\n\tHMC is already on the latest build or same level,\n\tthan given one:- ${RED}${BUILD}${EC}\n" && exit 1

ECHO "Getting the architecture of HMC ...\c"
HMC_ARCHITECTURE=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@${HMC} "uname -i")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$HMC_ARCHITECTURE${EC}"

if [[ "${BUILD: -4}" == ".iso" ]]
then
        VALIDATE_PARSED_BUILD_ARCH=$(echo "$BUILD" | cut -d'-' -f 4 | cut -d'.' -f 1)
        [[ $HMC_ARCHITECTURE != $VALIDATE_PARSED_BUILD_ARCH ]] && echo -ne "\nChoose proper ISO:- ${RED}${BUILD}${EC}\n\n" && exit 1
fi

ECHO "Validating the ftp IP: ${BLUE}$FTP_SERVER${EC} ...\c"
ping -c3 $FTP_SERVER > /dev/null 2>&1

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

ECHO "Validating ftp credentials ...\c"
sshpass -p $FTP_PASS ssh -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  $FTP_USER@$FTP_SERVER "echo ssk" > /dev/null

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}\n\n${UNDERLINE}Failure Analysis:${EC}\n\n\tPlease verify once parsed ftp credentials\n\t\t> ${FTP_USER}\n\t\t> ${FTP_PASS}\n" && exit 1 || echo -e " ${GREEN}Passed${EC}"

if [[ ${BUILD: -4} == ".iso" ]]
then
        update_HMC
elif [[ ${BUILD} =~ ^[0-9]+$ ]]
then
        upgrade_HMC
else
        exit 1
fi

ECHO "Rebooting the HMC .\c"
## calling the spin function
spin 10 &
# collecting the PID and running it in background
T_PID=$! && disown

count=0
while true
do
        sshpass -p ${HMC_PASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMC_USER}@${HMC} "echo 'ssk'" > /dev/null 2>&1
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
IS_HMC_UP=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMC_USER}@${HMC} "echo 'ssk'")
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
spin 15 &
# stroing the PID and hiding it
FI_PID=$! && disown

S_count=0
while true
do
IS_CMD_SERVER_UP=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMC_USER}@$HMC "lshmc -v" > /dev/null 2>&1)
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

ECHO "After update/upgrade HMC version ...\c"
NEW_HMC_VERSION=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@$HMC "lshmc -v | grep RM | cut -d' ' -f 2")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$NEW_HMC_VERSION${EC}"


ECHO "After update/upgrade HMC build level ...\c"
NEW_HMC_BUILD_LEVEL=$(sshpass -p $HMC_PASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  ${HMC_USER}@$HMC "lshmc -V | grep 'HMC Build level' | cut -d' ' -f 4")

[[ $? -ne 0 ]] && echo -e " ${RED}Failed${EC}" || echo -e " ${GREEN}$NEW_HMC_BUILD_LEVEL${EC}"

## removing iso from hmc.
[[ "${BUILD: -4}" == ".iso" ]] && remove_ISO

ECHO "Finished.\n"
exit 0
