#!/usr/bin/env bash
#-----------------------------------------------------------------------
#
# *** This tool will perform LPM for the given lpar ***
#
#
# File Name  :- lpm.sh
# Created on :- 19/11/2021
#
#
# Created by :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#----------------------------------------------------------------------


WHITE='\e[97m'
EC='\033[0m'
BLUE='\033[94m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'
LPAR=""
SOURCEHMC=""
TARGETHMC=""
SOURCECEC=""
TARGETCEC=""
HMCUSER="hscpe"
HMCPASS="abcd1234"
ITERATIONS=1
WAITTIME="1m"
REMOTEMIGRATION="NO"
MYCOUNT=0


usage () {
        echo -e "Options:-\n"
        echo -e "-l,  --lpar,            LPM lpar hostname or IP."
        echo -e "-?,  --sourcehmc        source HMC hostname or IP."
        echo -e "-?,  --targethmc        target HMC hostname or IP."
        echo -e "-?,  --sourcecec        source CEC hostname or IP."
        echo -e "-?,  --targetcec        target CEC hostname or IP."
        echo -e "-w,  --waittime         after every LPM operation"
        echo -e "-i,  --iterations"
        echo -e "-r,  --remotemigration  yes or no"
}

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

TEMP=`getopt -o "l:i:hw:r:u:p:" -l "hmcuser:,hmcpass:,waittime:,iterations:,help,sourcehmc:,targethmc:,lpar:,sourcecec:,targetcec:,remotemigration:" -n $0 -- "$@"` || {
        echo ""
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

        -r | --remotemigration)
                        REMOTEMIGRATION=$2;
                        shift 2
                                            ;;
        -u | --hmcuser)
                        HMCUSER=$2;
                        shift 2
                                            ;;
        -p | --hmcpass)
                        HMCPASS=$2;
                        shift 2
                                            ;;
        --sourcehmc)
                        SOURCEHMC=$2;
                        shift 2
                                            ;;
        --targethmc)
                        TARGETHMC=$2;
                        shift 2
                                            ;;
        --sourcecec)
                        SOURCECEC=$2;
                        shift 2
                                            ;;
        --targetcec)
                        TARGETCEC=$2;
                        shift 2
                                            ;;
        -l | --lpar)
                        LPAR=$2;
                        shift 2
                                            ;;
        -i | --iterations)
                        ITERATIONS=$2;
                        shift 2
                                            ;;
        -w | --waittime)
                        WAITTIME=$2;
                        shift 2
                                            ;;
                --)
                        shift; break;
                                            ;;
                 *)
                        usage;
                        exit 1
                                            ;;
    esac
done

## validating the passed options and its values.
[[ "$LPAR" == "" ]] && echo -e "\nOption: -l is missing.\n" && usage && exit 1
[[ "$HMCUSER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$HMCPASS" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1
[[ "$WAITTIME" == "" ]] && echo -e "\nOption: -w is missing.\n" && usage && exit 1
[[ "$SOURCEHMC" == "" ]] && echo -e "\nOption: --sourcehmc is missing.\n" && usage && exit 1
[[ "$SOURCECEC" == "" ]] && echo -e "\nOption: --sourcecec is missing.\n" && usage && exit 1
[[ "$TARGETCEC" == "" ]] && echo -e "\nOption: --targetcec is missing.\n" && usage && exit 1

if [[ $( echo $REMOTEMIGRATION | tr '[:lower:]' '[:upper:]') == 'YES' ]] && [[ "$TARGETHMC" == "" ]]
then
        echo -e "\nOption: --targethmc is missing.\n"
        usage
        exit 1
fi

## remote hmc migration function
remote_hmc_migration () {
    echo "remote migration function "
}



## same hmc migration function
same_hmc_migration () {

    # Validating the migration
    ECHO "Validating the migration ... \c"
    VM=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "migrlpar -m ${SOURCECEC} -t ${TARGETCEC} -o v -p ${LPAR} --ip ${SOURCEHMC} -u ${HMCUSER}")
    if [[ $? -eq 0 ]]
    then
            echo -e "${GREEN}Passed${EC}"

                # migrating the partition from source to destination
            ECHO "Migrating ${BLUE}${LPAR}${EC} from ${WHITE}${SOURCECEC}${EC} to ${WHITE}${TARGETCEC}${EC} ... \c"
            MR=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "migrlpar -m ${SOURCECEC} -t ${TARGETCEC} -o m -p ${LPAR} --ip ${SOURCEHMC} -u ${HMCUSER}")

            if [[ $? -eq 0 ]]
            then
                    echo -e "${GREEN}Passed${EC}"
                    ECHO "Post migration discovering lpar in ${WHITE}${TARGETCEC}${EC} ... \c"
                    GETLPARNAME=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "lssyscfg -r lpar -m ${TARGETCEC} -F name --filter \"lpar_names=${LPAR}\"")
                    if [[ $? -eq 0 ]]
                    then
                            echo -e "${BLUE}${GETLPARNAME}${EC}"

                            ECHO "Post migration rmc status of lpar in destination ... \c"
                            GETRMCSTATUS=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "lssyscfg -r lpar -m ${TARGETCEC} -F rmc_state --filter \"lpar_names=${LPAR}\"")
                            if [[ $? -eq 0 ]]
                            then
                                    echo -e "${BLUE}${GETRMCSTATUS}${EC}"
                            else
                                    echo -e "${RED}Failed${EC}"
                            fi
                    else
                            echo -e "${RED}Failed${EC}"
                    fi
            else
                    echo -e "${RED}Failed${EC}"
                    exit 1
            fi
    else
            echo -e "${RED}Failed"
            echo -e "${VM}${EC}"
            exit 1
    fi
}


echo ""
ECHO "Validating HMC IP: ${BLUE}${SOURCEHMC}${EC} ... \c"
ping -c3 $SOURCEHMC > /dev/null 2>&1
if [[ $? -ne 0 ]]
then
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- ping to the HMC: ${SOURCEHMC} failed."
        exit 1
else
        SOURCEHMCIP=$(host ${SOURCEHMC} | cut -d' ' -f4)
        echo -e "${GREEN}Passed${EC}"
fi


if [[ $(echo $REMOTEMIGRATION | tr '[:lower:]' '[:upper:]') == "YES" ]]
then
        ECHO "Validating HMC IP: ${BLUE}${TARGETHMC}${EC} ... \c"
        ping -c3 ${TARGETHMC} > /dev/null 2>&1
        if [[ $? -ne 0 ]]
        then
                echo -e "${RED}Failed${EC}"
                echo "Failure Analysis:- ping to the HMC: ${TARGETHMC} failed."
                exit 1
        else
                echo -e "${GREEN}Passed${EC}"
        fi
else
    while true
    do
            if [[ ${MYCOUNT} -ne ${ITERATIONS} ]]
            then
                    same_hmc_migration
                    TEMP=${SOURCECEC}
                    SOURCECEC=${TARGETCEC}
                    TARGETCEC=${TEMP}
                    ((MYCOUNT++))

                    # sleep time
                    if [[ ${MYCOUNT} -ne ${ITERATIONS} ]]
                    then
                            ECHO "Sleeping $WAITTIME ... \c"
                            sleep $WAITTIME
                            echo -e "${GREEN}Passed${EC}"
                    fi
            else
                    ECHO "Finished."
                    exit 0
            fi
    done
fi
