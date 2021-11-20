#!/usr/bin/env bash
#---------------------------------------------------------------------------
#
# *** Script to perform LPM - live partition mobility for given LPAR. ***
#
#
# File Name  :- lpm.sh
# Created on :- 19/11/2021
#
#
# Created by :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#--------------------------------------------------------------------------


LPAR=""
SOURCEHMC=""
TARGETHMC=""
SOURCECEC=""
TARGETCEC=""
MYCOUNT=0
HMCUSER="hscpe"
HMCPASS="abcd1234"
ITERATIONS=1
WAITTIME="1m"
WHITE='\e[97m'
EC='\033[0m'
BLUE='\033[94m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'
REMOTEMIGRATION="NO"

# usage function.
usage () {
    echo -e "${UNDERLINE}Usage:${EC}"
    echo -e "\n$0 [-l <LPAR>] [--sourcecec <hostname|IP>] [--targetcec <hostname|IP>] [--sourcehmc <hostname|IP>] [--targethmc <hostname|IP>] [-i] [-w] [-u] [-p] [-r] [-h]\n"
    echo -e "${UNDERLINE}Supported Options:${EC}\n"
    echo -e "\t-l, --lpar            : Provide LPM LPAR hostname|IP."
    echo -e "\t-i, --iterations      : Number of LPM operation."
    echo -e "\t-w, --waittime        : Wait time b/w every LPM operation."
    echo -e "\t-u, --hmcuser         : Provide HMC user name."
    echo -e "\t-p, --hmcpass         : Provide HMC user password."
    echo -e "\t-r, --remotemigration : Remote HMC migration."
    echo -e "\t--sourcecec           : Provide source CEC hostname|IP."
    echo -e "\t--sourcehmc           : Provide source HMC hostname|IP."
    echo -e "\t--targetcec           : Provide target CEC hostname|IP."
    echo -e "\t--targethmc           : Provide target HMC hostname|IP."
    echo -e "${UNDERLINE}Example:${EC}"
    echo -e "\n\t$0 -l d152a-lpm-lpar1 --sourcecec d152a --targetcec d120a --sourcehmc 9.3.147.165\n"
    echo -e "Contact:- ${WHITE}Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)${EC}"
}


synopsis () {
    echo -e "\n${UNDERLINE}Synopsis:${EC}\n"
    echo -e "\tThis script will perform the hard boot on the given system."
}


ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

TEMP=`getopt -o "l:i:hw:ru:p:" -l "hmcuser:,hmcpass:,waittime:,iterations:,help,sourcehmc:,targethmc:,lpar:,sourcecec:,targetcec:,remotemigration" -n $0 -- "$@"` || {
        echo ""; usage
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

        -r | --remotemigration)
                        REMOTEMIGRATION="YES"
                        shift 1
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
        -h | --help)
                        shift 1;
                        echo ""
                        usage
                        exit 0
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

if [[ -n "${SOURCEHMC}" ]] && [[ -n "${TARGETHMC}" ]] && [[ "${REMOTEMIGRATION}" == "NO" ]]
then
        echo -e "\nOption: -r is missing.\n"
        usage
        exit 1
fi

if [[ -n "${SOURCEHMC}" ]] && [[ "${REMOTEMIGRATION}" == "YES" ]] && [[ "$TARGETHMC" == "" ]]
then
        echo -e "\nOption: --targethmc is missing.\n"
        usage
        exit 1
fi


migrate_lpar () {

#--------------------------------------------
# migrate lpar from source to destination
#--------------------------------------------

    # Validating the migration
    ECHO "Validating the migration ... \c"
    VM=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "migrlpar -m ${SOURCECEC} -t $2 -o v -p ${LPAR} --ip $1 -u ${HMCUSER}")
    if [[ $? -eq 0 ]]
    then
            echo -e "${GREEN}Passed${EC}"

            # migrating the partition from source to destination
            ECHO "Migrating ${BLUE}${LPAR}${EC} from ${WHITE}${SOURCECEC}${EC} to ${WHITE}$2${EC} ... \c"
            MR=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "migrlpar -m ${SOURCECEC} -t $2 -o m -p ${LPAR} --ip $1 -u ${HMCUSER}")

            if [[ $? -eq 0 ]]
            then
                    echo -e "${GREEN}Passed${EC}"
                    ECHO "Post migration discovering lpar in ${WHITE}$2${EC} ... \c"
                    GETLPARNAME=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@$1 "lssyscfg -r lpar -m $2 -F name --filter \"lpar_names=${LPAR}\"")
                    if [[ $? -eq 0 ]]
                    then
                            echo -e "${BLUE}${GETLPARNAME}${EC}"

                            ECHO "Post migration rmc status of lpar in destination ... \c"
                            GETRMCSTATUS=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@$1 "lssyscfg -r lpar -m $2 -F rmc_state --filter \"lpar_names=${LPAR}\"")
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


if [[ "$REMOTEMIGRATION"  == "YES" ]]
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


        AUTHCOUNT=0
        IS_AUTH_COMMAND_EXECUTED=0
                ECHO "Doing mkauthkeys between two HMC's ... \c"
        STMKA=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "mkauthkeys --ip ${TARGETHMC} -u ${HMCUSER} --test")
        if [[ $? -ne 0 ]]
        then
                                SOURCEAUTH=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${SOURCEHMC} "mkauthkeys --ip ${TARGETHMC} -u ${HMCUSER} --passwd ${HMCPASS}")
                                if [[ $? -eq 0 ]]
                                then
                                                ((AUTHCOUNT++))
                        ((IS_AUTH_COMMAND_EXECUTED++))
                                else
                                                echo -e "${RED}Failed"
                        echo -e "${SOURCEAUTH}${EC}"
                        exit 1
                                fi
                else
                                ((AUTHCOUNT++))
                fi

                TTMKA=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${TARGETHMC} "mkauthkeys --ip ${SOURCEHMC} -u ${HMCUSER} --test")
                if [[ $? -ne 0 ]]
                then
                                TARGETAUTH=$(sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${TARGETHMC} "mkauthkeys --ip ${SOURCEHMC} -u ${HMCUSER} --passwd ${HMCPASS}")
                                if [[ $? -eq 0 ]]
                                then
                                                ((AUTHCOUNT++))
                        ((IS_AUTH_COMMAND_EXECUTED++))
                                else
                                                echo -e "${RED}Failed"
                        echo -e "${TARGETAUTH}${EC}"
                        exit 1
                                fi
                else
                                ((AUTHCOUNT++))
                fi

                if [[ "${AUTHCOUNT}" -eq 2 ]]
                then
                                echo -e "${GREEN}Passed${EC}"
                if [[ "${IS_AUTH_COMMAND_EXECUTED}" -gt 0 ]]
                then
                                        ECHO "Sleeping 1 minute ... \c"
                        sleep 1m
                        echo -e "${GREEN}Passed${EC}"
                fi

                else
                                echo -e "${RED}Failed${EC}"
                echo -e "Failure:- mkauthkeys did not happend properly."
                exit 1
                fi

        while true
        do
                if [[ ${MYCOUNT} -ne ${ITERATIONS} ]]
                then
                        ## calling the remote HMC migration function
                        migrate_lpar ${TARGETHMC} ${TARGETCEC}

                        TEMP_ONE=${SOURCEHMC}
                        SOURCEHMC=${TARGETHMC}
                        TARGETHMC=${TEMP_ONE}
                        TEMP_TWO=${SOURCECEC}
                        SOURCECEC=${TARGETCEC}
                        TARGETCEC=${TEMP_TWO}
                        ((MYCOUNT++))

                        # sleep time
                        if [[ ${MYCOUNT} -ne ${ITERATIONS} ]]
                        then
                                ECHO "Sleeping $WAITTIME ... \c"
                                sleep $WAITTIME
                                echo -e "${GREEN}Passed${EC}"
                        fi
                else
                        break
                fi
        done
else

    while true
    do
            if [[ ${MYCOUNT} -ne ${ITERATIONS} ]]
            then
                    migrate_lpar ${SOURCEHMC} ${TARGETCEC}

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
                    break
            fi
    done
fi

ECHO "Finished."
exit 0
