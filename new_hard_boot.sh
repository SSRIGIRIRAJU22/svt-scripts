#!/usr/bin/bash

#-----------------------------------------------------------------------
#
# *** This tool will perform the hard boot on the given system ***
#
#
# File Name  :- hard_boot.sh
# Created on :- 12/07/2021
#
#
# Created by :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#----------------------------------------------------------------------

HMCPASS='abcd1234'
HMCUSER='hscpe'
LPARUSER='root'
WHITE='\e[97m'
EC='\033[0m'
BLUE='\033[94m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'


# usage function.
usage () {
    echo -e "${UNDERLINE}Usage:${EC}"
    echo -e "\n\t$0 [-h <HMC>] [-u <HMC user name>] [-p <HMC password>] [-m <machine>] [-i <iterations>] [-U <LPAR user name>] [-P <LPAR Password>]\n"
    echo -e "${UNDERLINE}Supported Options:${EC}\n"
    echo -e "\t-h : HMC host name or IP."
    echo -e "\t-u : HMC user name. ${WHITE}Default: hscpe${EC}"
    echo -e "\t-p : HMC user password. ${WHITE}Default: abcd1234${EC}"
    echo -e "\t-m : Power system host name or IP."
    echo -e "\t-U : LPAR user name. ${WHITE}Default: root${EC}"
    echo -e "\t-P : LPAR user password."
    echo -e "\t-i : Iterations."
    echo -e "    --help : help.\n"
    echo -e "${UNDERLINE}Optional Parameters:${EC}"
    echo -e "\n\t[-u] [-p] [-U] [-t]\n"
    echo -e "${UNDERLINE}Example:${EC}"
    echo -e "\n\t$0 -h 192.12.133.5 -u hscpe -p abcd1234 -m zepp20fp -i 10 -U root -P Th3resyerproblem! \n"
    echo -e "Contact:- ${WHITE}Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)${EC}"
}


synopsis () {
    echo -e "\n${UNDERLINE}Synopsis:${EC}\n"
    echo -e "\tThis script will perform the hard boot on the given system."
}

ECHO () {

        echo -e "$(date '+%Y%m%d%H%M%S'): $*"
}

TEMP=`getopt -o "m:h:i:u:p:U:P:" --long help -n $0 -- "$@"` || {
        echo ""
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
            -i)
                    ITERATIONS=$2;
                    shift 2
                                    ;;
            -U)
                    LPARUSER=$2;
                    shift 2
                                    ;;
            -P)
                    LPARPASS=$2;
                    shift 2
                                    ;;
            --)
                    shift; break;
                                    ;;
        --help)
                    synopsis
                    usage
                    exit 0
                                    ;;
            *)
                    usage
                    exit 1
                                    ;;
    esac
done

## validating the passed options and its values.
[[ "$MACHINE" == "" ]] && echo -e "\nOption: -m is missing.\n" && usage && exit 1
[[ "$HMC" == "" ]] && echo -e "\nOption: -h is missing.\n" && usage && exit 1
[[ "$HMCUSER" == "" ]] && echo -e "\nOption: -u is missing.\n" && usage && exit 1
[[ "$HMCPASS" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1
[[ "$LPARPASS" == "" ]] && echo -e "\nOption: -P is missing.\n" && usage && exit 1
[[ "$ITERATIONS" == "" ]] && echo -e "\nOption: -i is missing.\n" && usage && exit 1

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

ECHO "Validating the CEC: ${BLUE}$MACHINE${EC} ... \c"
IS_CEC_CONNECTED_TO_HMC=$(sshpass -p $HMCPASS ssh -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F name -m $MACHINE")
if [[ $? -ne 0 ]]
then
        echo -e "${RED}Failed${EC}\n"
        if [[ -n $IS_CEC_CONNECTED_TO_HMC ]]
        then
                echo "Error Msg:- $IS_CEC_CONNECTED_TO_HMC On ${HMC}."
        fi
        exit 1
else
                CEC_STATE=$(sshpass -p $HMCPASS ssh -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F state -m $MACHINE")
                if [[ $? -ne 0 ]]
                then
                                echo -e " ${RED}Failed${EC}"
                                echo "Failure Analysis:- CEC: ${MACHINE} not in Operating state.\n"
                                exit 1
                else
                                echo -e "${GREEN}Passed${EC}"
                fi
fi

ECHO "Validating the VIOS partition(s) ...\c"
VIOS_COUNT=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name -m $MACHINE | grep -i vios | wc -l")
if [[ $? -eq 0 ]]
then
                if [[ $VIOS_COUNT == 1 ]]
                then
                        VIOS_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state,rmc_state -m $MACHINE | grep -i vios")
                        if [[ $? -eq 0 ]]
                        then
                                        STATE=$(echo $VIOS_LPAR | cut -d',' -f2)
                                        if [[ $STATE -ne 'Running' ]]
                                        then
                                                echo -e " ${RED}Failed${EC}"
                                                echo "VIOS: ${VIOS_LPAR} not in Running State."
                                                exit 1
                                        else
                                                echo -e " ${GREEN}Passed${EC}"
                                        fi
                        else
                                echo -e "${RED}Failed${EC}"
                                echo -e "Failure Analysis:- Could not able to get the VIOS informatin."
                                exit 1
                        fi
                elif [[ $VIOS_COUNT -gt 1 ]]
                then
                        VIOS_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state,rmc_state -m $MACHINE | grep -i vios")
                        count=0
                        if [[ $? -eq 0 ]]
                        then
                                        if [[ -n $VIOS_LPAR ]]
                                        then
                                                for A in $VIOS_LPAR
                                                do
                                                        STATE=$(echo $A | cut -d',' -f2)
                                                        RMCSTATE=$(echo $A | cut -d',' -f3)
                                                        if [[ $STATE == 'Running' ]] && [[ $RMCSTATE == 'active' ]]
                                                        then
                                                                ((count++))
                                                        else
                                                                VIOS_NAME=$(echo $A | cut -d',' -f1)
                                                                sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $VIOS_NAME --immed --force" > /dev/null
                                                        fi
                                                done
                                                if [[ $count -gt 0 ]]
                                                then
                                                            echo -e " ${GREEN}Passed${EC}"
                                                else
                                                            echo -e " ${RED}Failed${EC}"
                                                            exit 1
                                                fi
                                        else
                                                echo -e "${RED}Failed${EC}"
                                                echo -e "Failure Analysis:- Could not able to get the VIOS Information."
                                                exit 1
                                        fi
                        else
                                echo -e "${RED}Failed${EC}"
                                echo -e "Failure Analysis:- Could not able to get the VIOS information."
                                exit 1
                        fi
                else
                            echo -e " ${RED}Failed${EC}"
                            echo "Failure Analysis :- None of the VIOS(s) are in Running state or VIOS partition(s) does not exist on ${MACHINE}."
                            exit 1
                fi
else
        echo "Failure Analysis:- Could not able to get the VIOS information."
        exit 1
fi

ECHO "Shutting down the LPARs which are not in ${BLUE}Running${EC} state ... \c"
LPARS_NOT_IN_RUNNING=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state -m $MACHINE | grep -v 'Running' | grep -iv 'vios' | grep -v 'Not Activated' | cut -d',' -f1")
if [[ $? -eq 0 ]]
then
        if [[ -n $LPARS_NOT_IN_RUNNING ]]
        then
                for B in $LPARS_NOT_IN_RUNNING
                do
                    sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $B --immed --force" > /dev/null
                    if [[ $? -eq 0 ]]
                    then
                            sleep 2
                    fi
                done
                echo -e "${GREEN}Passed${EC}"
        else
                echo -e "${WHITE}Done${EC}"
        fi
else
        echo "${RED}Failed${EC}"
        exit 1
fi

ECHO "Shutting down the LPARs which has no proper RMC ... \c"
RMC_COUNT=0
RMC_NONE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,rmc_state,state -m $MACHINE | grep 'none' | grep -iv 'vios' | grep -v 'Not Activated' | cut -d',' -f1")
if [[ $? -eq 0 ]]
then
        if [[ -n $RMC_NONE ]]
        then
                for C in $RMC_NONE
                do
                    sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $C --immed --force" > /dev/null
                    if [[ $? -eq 0 ]]
                    then
                            ((RMC_COUNT++))
                    fi
                done
        fi
else
        exit 1
fi

RMC_INACTIVE=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,rmc_state,state -m $MACHINE | grep 'inactive' | grep -iv 'vios' | grep -v 'Not Activated' | cut -d',' -f1")
if [[ $? -eq 0 ]]
then
        if [[ -n $RMC_INACTIVE ]]
        then
                for D in $RMC_INACTIVE
                do
                    sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $D --immed --force" > /dev/null
                    if [[ $? -eq 0 ]]
                    then
                            ((RMC_COUNT++))
                    fi
                done
        fi
else
        exit 1
fi
if [[ $RMC_COUNT -gt 0 ]]
then
        echo -e "${GREEN}Passed${EC}"
else
        echo -e "${WHITE}Done${EC}"
fi

ECHO "Validating the LPAR password ... \c"
LPARS_CORRECT_PASSWORD=()
FETCH_LPARS=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state -m $MACHINE | grep \"Running\" | grep -iv \"vios\" | cut -d',' -f1")
if [[ $? -eq 0 ]]
then
                if [[ -n $FETCH_LPARS ]]
                then
                        for E in $FETCH_LPARS
                        do
                                timeout 2m sshpass -p "$LPARPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${LPARUSER}@${E} "hcl -status" > /dev/null
                                if [[ $? -eq 255 ]]
                                then
                                        LPARS_CORRECT_PASSWORD=($E "${LPARS_CORRECT_PASSWORD[@]}")
                                else
                                        sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $E --immed --force" > /dev/null
                                fi
                        done
                else
                        echo -e "Failure Analysis:- Could not able to get the LPARS information."
                        exit 1
                fi
else
        echo "Failure Analysis:- Command execution did not success."
        exit 1
fi

if [[ ${#LPARS_CORRECT_PASSWORD[@]} -gt 10 ]]
then
                echo -e "${GREEN}Passed${EC}"
else
                echo -e "${RED}Failed${EC}"
                echo "Failuer Analysis:"
                echo -e "\tInvalid Password:- ${LPARPASS}, can not proceed further try giving valid password."
                exit 1
fi

ECHO "Getting final VIOS info which should be part of hard boot ... \c"
FINAL_VIOS=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state -m $MACHINE | grep -i vios | grep -i Running | cut -d',' -f1")

if [[ $? -eq 0 ]]
then
            if [[ -n $FINAL_VIOS ]]
            then
                        echo -e "${GREEN}Passed${EC}"
            else
                        echo -e "${RED}Failed${EC}"
                        echo "Failuer Analysis:"
                        echo -e "\tCould not able to get the VIOS information, try running the script again."
                        exit 1
            fi
else
        echo -e "${RED}Failed${EC}"
        echo -e "Failure Analysis:- Command execution failed."
        exit 1
fi

ECHO "Getting final LPARs info which should be part of hard boot ... \c"
FINAL_LPARS=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state -m $MACHINE | grep -iv vios | grep -i Running | cut -d',' -f1")

if [[ $? -eq 0 ]]
then
        if [[ -n $FINAL_LPARS ]]
        then
                        echo -e "${GREEN}Passed${EC}"
                        if [[ "${#FINAL_LPARS}" < 10 ]]
                        then
                                echo "Failuer Analysis:"
                                echo -e "\tTry changing the passowrd to other lpars and run the script again."
                                echo -e "\tAtleast more than 10 lpar should be running properly with correct password and RMC"
                                exit 1
                        fi
        else
                        echo -e "${RED}Failed${EC}"
                        echo -e "\tCould not able to get the LPAR(s) information, try running the script again."
                        exit 1
        fi
else
        echo -e "${RED}Failed${EC}"
        echo -e "Failure Analysis:- Command execution failed."
        exit 1
fi

ECHO "Enabling the auto start policy for LPAR(s) & VIOS(s)."
ECHO "Shutting down all the LPAR(s), Including VIOS(s) ... \c"
ALL_SHUTDOWN=0
for LPAR in $(echo $FINAL_LPARS | tr " " "\n") $(echo $FINAL_VIOS | tr " " "\n")
do
        SHUTDOWN_LPAR=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $LPAR --immed --force" 2>&1)
        if [[ $? -eq 0 ]]
        then
                ((ALL_SHUTDOWN++))
                sleep 2
        fi
done


if [[ $ALL_SHUTDOWN -gt 0 ]]
then
        echo -e "${GREEN}Passed${EC}"
else
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- Failed to shutdown all the LPARS."
        exit 1
fi

ECHO "Initiating auto_start policy for VIOS(s) ... \c"
VIOS_ASPC=0
for F in $(echo $FINAL_VIOS | tr " " "\n")
do
    GET_VIOS_ID=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F lpar_id --filter \"lpar_names=${F}\" -m $MACHINE")
    if [[ $? -eq 0 ]]
    then
            BREAK_LOOP_COUNT=0
            while true
            do
                ACTIVATE_POLICY_FOR_VIOS=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_id=$GET_VIOS_ID,auto_start=1\" --force" 2>&1)
                        if [[ $? -eq 0 ]]
                        then
                                ((VIOS_ASPC++))
                                break
                        else
                                sleep 5
                                ((BREAK_LOOP_COUNT++))
                                [[ $BREAK_LOOP_COUNT > 15 ]] && echo -e "${RED}Failed${EC}" && echo "Error Msg:- $ACTIVATE_POLICY_FOR_VIOS" && exit 1
                        fi
            done
    fi
done

if [[ $VIOS_ASPC == 0 ]]
then
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- auto_start policy command failed to execute."
        exit 1
else
        echo -e "${GREEN}Passed${EC}"
fi

ECHO "Initiating auto_start policy for LPAR(s) ... \c"
LPAR_ASPC=0
for G in $(echo $FINAL_LPARS | tr " " "\n")
do
    GET_LPAR_ID=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F lpar_id --filter lpar_names=${G} -m $MACHINE")
    if [[ $? -eq 0 ]]
    then
            sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_id=$GET_LPAR_ID,auto_start=1\" --force" > /dev/null
            if [[ $? -eq 0 ]]
            then
                        ((LPAR_ASPC++))
            fi
    fi
done

if [[ $LPAR_ASPC == 0 ]]
then
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- auto_start policy command did not succed."
        exit 1
else
        echo -e "${GREEN}Passed${EC}"
fi

ECHO "Activating the VIOS partition(s) ... \c"
VIOS_ON=0
for FF in $(echo $FINAL_VIOS | tr " " "\n")
do
    sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $MACHINE -n ${FF}" > /dev/null
    if [[ $? -eq 0 ]]
    then
            ((VIOS_ON++))
    fi
done
if [[ $VIOS_ON == 0 ]]
then
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- Failed to activate VIOS(s), Command returned exit status as 1."
        exit 1
else
        echo -e "${GREEN}Passed${EC}"
fi

ECHO "Sleeping 2 mins ... \c"
sleep 120
echo -e "${GREEN}Passed${EC}"

ECHO "Activating the LPAR(s) ... \c"
LPAR_ON=0
for GG in $(echo $FINAL_LPARS | tr " " "\n")
do
    sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $MACHINE -n ${GG}" > /dev/null
    if [[ $? -eq 0 ]]
    then
         LPAR_ON=$((LPAR_ON+1))
    fi
done
if [[ $LPAR_ON == 0 ]]
then
        echo -e "${RED}Failed${EC}"
        echo "Failure Analysis:- Failed to activate LPAR(s), Command returned exit status as 1."
        exit 1
else
        echo -e "${GREEN}Passed${EC}"
fi

ECHO "Will wait for all the VIOS to come up ... \c"
VIOS_LOOP_TERMINATE=0
for SSK_VIOS in $(echo $FINAL_VIOS | tr " " "\n")
do
    while true
    do
        PRE_TEST=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state,rmc_state -m $MACHINE --filter \"lpar_names=$SSK_VIOS\"")
        if [[ $? -eq 0 ]]
        then
                if [[ -n $PRE_TEST ]]
                then
                        if [[ $(echo "$PRE_TEST" | cut -d',' -f2) == 'Running' ]] && [[ $(echo "$PRE_TEST" | cut -d',' -f3) == 'active' ]]
                        then
                                break
                        else
                                sleep 30
                        fi
                else
                        ((VIOS_LOOP_TERMINATE++))
                        [[ $VIOS_LOOP_TERMINATE -gt 30 ]] && echo -e "${RED}Failed${EC}" && echo "Failure Analysis:- Could not able to get the VIOS info." && exit 1
                fi
        else
                ((VIOS_LOOP_TERMINATE++))
                [[ $VIOS_LOOP_TERMINATE -gt 30 ]] && echo -e "${RED}Failed${EC}" && echo "Failure Analysis:- VIOS did not come up." && exit 1
        fi
    done
done
echo -e "${GREEN}Passed${EC}"

ECHO "Will wait for all the LPAR(s) to come up ... \c"
LPARS_LOOP_TERMINATE=0
while true
do
    PRE_LPAR_TEST=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F rmc_state -m $MACHINE | grep -vi \"vios\" | grep -i \"Running\" | grep \"inactive\" | wc -l")
    if [[ $? -eq 0 ]]
    then
            if [[ -n $PRE_LPAR_TEST ]]
            then
                    if [[ $PRE_LPAR_TEST -le 5 ]]
                    then
                            break
                    else
                            sleep 30
                            ((LPARS_LOOP_TERMINATE++))
                    fi
            fi
    else
            sleep 30
            ((LPARS_LOOP_TERMINATE++))
            [[ $LPARS_LOOP_TERMINATE -gt 30 ]] && echo -e "${RED}Failed${EC}" && echo "Failure Analysis:- Could not able to get the LPARS info." && exit 1
    fi
done
echo -e "${GREEN}Passed${EC}"

ECHO "Enabling the power off policy for CEC: ${BLUE}${MACHINE}${EC} ... \c"
sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r sys -m $MACHINE -i \"power_off_policy=0\"" > /dev/null
[[ $? -ne 0 ]] && echo -e "${RED}Failed${EC}" && exit 1 || echo -e "${GREEN}Passed${EC}"

# MACHINE=$1 and LPAR=$2
shutdown_lpar () {

    sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $1 -r lpar -o shutdown -n $2 --immed --force" > /dev/null
        if [[ $? -eq 0 ]]
        then
                    GET_ID=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F lpar_id --filter \"lpar_names=$2\" -m $1")
                    if [[ $? -eq 0 ]]
                    then
                                sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $1 -i \"name=default_profile,lpar_id=$GET_ID,auto_start=0\" --force" > /dev/null
                                if [[ $? -eq 0 ]]
                                then
                                            sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $1 -n $2" > /dev/null
                                            if [[ $? -eq 0 ]]
                                            then
                                                        sleep 15
                                                        sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $1 -r lpar -o shutdown -n $2 --immed --force" > /dev/null
                                            fi
                                fi
                    fi
        fi
}

ECHO "Initiating HTX and Hard Boot commands on the LPAR(s) ... \c"
FHB_LPARS=()
MyCount=0

for H in $(echo $FINAL_LPARS | tr " " "\n")
do
        sshpass -p "$LPARPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${LPARUSER}@${H} "hcl -run -mdt mdt.bu;htxcmdline -bootme on mode:hardf period:3" > /dev/null
        if [[ $? -eq 0 ]]
        then
                #HB_LPARS=("${HB_LPARS[@]}" $H)
                MyCount=$((MyCount+1))
        else
                #shutdown_lpar ${MACHINE} ${H}
                FHB_LPARS=("${FHB_LPARS[@]}" $H)
        fi
done


if [[ $MyCount -gt 5 ]]
then
            echo -e "${GREEN}Passed${EC}"
else
            echo -e "${RED}Failed${EC}"
            exit 1
fi

if [[ -n $FHB_LPARS ]]
then
        ECHO "Unable to start the hard boot on couple of LPARS, shutting down those LPARS ... \c"
        for I in $(echo $FHB_LPARS | tr " " "\n")
        do
                shutdown_lpar ${MACHINE} ${I}
        done
        echo -e "${GREEN}Passed${EC}"
fi

ECHO "Total number of LPARs that are part of Hard Boot ... ${BLUE}${MyCount}${EC} LPAR(s)."
HB_START_TIME=$(date)
ECHO "Start Time ... ${BLUE}${HB_START_TIME}${EC}"
ECHO "Hard Boot on CEC: ${BLUE}${MACHINE}${EC} is in progress ... \c"

## cleanup function.
Stop_Hard_Boot () {

        ECHO "Disblaing the power off policy for CEC: ${BLUE}${MACHINE}${EC} ...\c"
        while true
        do
                sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r sys -m $MACHINE -i \"power_off_policy=1\"" > /dev/null
                if [[ $? -eq 0 ]]
                then
                            get_power_off_policy=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F power_off_policy -m $MACHINE")
                            if [[ $? -eq 0 ]]
                            then
                                        if [[ ${get_power_off_policy} == 1 ]]
                                        then
                                                    echo -e " ${GREEN}Passed${EC}"
                                                    break
                                        fi
                            else
                                        sleep 60
                            fi
                else
                            sleep 60
                fi
        done

        ECHO "Disabling the auto start policy for VIOS(s) ...\c"
        FINAL_VIOS_VERIFICATION=0
        for P in $(echo $FINAL_VIOS | tr " " "\n")
        do
                sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r lpar -o shutdown -n $P --immed --force" > /dev/null
                if [[ $? -eq 0 ]]
                then
                        FIND_ID=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F lpar_id --filter \"lpar_names=$P\" -m $MACHINE")
                        if [[ $? -eq 0 ]]
                        then
                                sleep 60
                                sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_id=${FIND_ID},auto_start=0\" --force" > /dev/null
                                if [[ $? -eq 0 ]]
                                then
                                        sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $MACHINE -n $P" > /dev/null
                                        if [[ $? -eq 0 ]]
                                        then
                                                sleep 5
                                                ((FINAL_VIOS_VERIFICATION++))
                                        fi
                                fi
                        fi
                fi
        done
        if [[ ${FINAL_VIOS_VERIFICATION} > 0 ]]
        then
                echo -e " ${GREEN}Passed${EC}"
        else
                echo -e " ${RED}Failed${EC}"
                exit 1
        fi

        ECHO "Sleeping 2 mins ... \c"
        sleep 120
        echo -e "${GREEN}Passed${EC}"

        ECHO "Disabling the auto start policy for LPAR(s) ... \c"
        CLEANUP_VERIFICATION=0
        for Q in $(echo $FINAL_LPARS | tr " " "\n")
        do
                GET_LPARID=$(sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F lpar_id --filter \"lpar_names=$Q\" -m $MACHINE")
                if [[ $? -eq 0 ]]
                then
                        sshpass -p $HMCPASS ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsyscfg -r prof -m $MACHINE -i \"name=default_profile,lpar_id=$GET_LPARID,auto_start=0\" --force" > /dev/null
                        if [[ $? -eq 0 ]]
                        then
                                sshpass -p ${HMCPASS} ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -r lpar -o on -f default_profile -m $MACHINE -n $Q" > /dev/null
                                if [[ $? -eq 0 ]]
                                then
                                        ((CLEANUP_VERIFICATION++))
                                fi
                        fi
                fi
        done
        if [[ ${CLEANUP_VERIFICATION} > 0 ]]
        then
                echo -e "${GREEN}Passed${EC}"
        else
                echo -e "${RED}Failed${EC}"
                exit 1
        fi

        ECHO "Stoping the HTX on LPAR(s) ... \c"
        CLEANUP_HTX=0
        for R in $(echo $FINAL_LPARS | tr " " "\n")
        do
                END=$(sshpass -p "$LPARPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${LPARUSER}@${R} "hcl -shutdown > /dev/null &" 2>&1)
                [[ $? -eq 0 ]] && sleep 5 && ((CLEANUP_HTX++))
        done
        if [[ ${CLEANUP_HTX} > 0 ]]
        then
                echo -e "${GREEN}Passed${EC}"
        else
                echo -e "${RED}Failed${EC}"
                exit 1
        fi
}


PowerOn_CEC () {

        while true
        do
                GET_CEC_STATE=$(sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F state -m $MACHINE" 2>&1)
                if [[ $? -eq 0 ]]
                then
                        if [[ $GET_CEC_STATE == 'Power Off' ]]
                        then
                                GET_CEC_TYPE=$(sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F type_model -m $MACHINE")
                                 if [[ $? -eq 0 ]]
                                 then
                                        TYPE=$(echo $GET_CEC_TYPE | cut -d'-' -f1)
                                        if [[ $TYPE == '9080' ]]
                                        then
                                               sleep 300
                                        elif [[ $TYPE == '9040' ]]
                                        then
                                               sleep 250
                                        else
                                               sleep 200
                                        fi
                                        break
                                  fi
                        else
                                sleep 180
                        fi
                else
                        echo "Failure Analysis:- $GET_CEC_STATE"
                        exit 1
                fi
        done

    # power on cec
        sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m $MACHINE -r sys -o on" > /dev/null
        if [[ $? -eq 0 ]]
        then
                sleep 120
                while true
                do
                        IS_CEC_UP=$(sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r sys -F state -m $MACHINE")
                        if [[ $? -eq 0 ]]
                        then
                                if [[ $IS_CEC_UP == 'Operating' ]]
                                then
                                        sleep 200
                                        break
                                 else
                                        sleep 120
                                 fi
                        fi
                done
        else
                echo "Could not able to power on the CEC, command returned exit status as 1."
                exit 1
        fi
}

HB_END_COUNT=0

# lpars will go shutdown from here
while true
do
    GET_LPAR_SHUTDOWN_COUNT=$(sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "lssyscfg -r lpar -F name,state -m $MACHINE | grep Running | grep -v vios | wc -l")

    if [[ $? -eq 0 ]]
    then
                if [[ -n $GET_LPAR_SHUTDOWN_COUNT ]]
                then
                        if [[ $GET_LPAR_SHUTDOWN_COUNT == 0 ]]
                        then
                                if [[ $HB_END_COUNT != $ITERATIONS ]]
                                then
                                        ((HB_END_COUNT++))
                                        for J in $(echo $FINAL_VIOS | tr " " "\n")
                                        do
                                                sshpass -p "$HMCPASS" ssh -k -oLogLevel=quiet -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ${HMCUSER}@${HMC} "chsysstate -m ${MACHINE} -r lpar -o shutdown -n ${J} --immed --force" > /dev/null
                                        done
                                        PowerOn_CEC
                                else
                                        echo -e "${GREEN}Passed${EC}"
                                        #ECHO "End Time ... ${BLUE}${HB_END_TIME}${EC}"
                                        ECHO "End Time ... ${BLUE}$(date)${EC}"
                                        ECHO "Initiated cleanup."
                                        Stop_Hard_Boot
                                        break
                                fi
                        else
                                sleep 120
                        fi
                fi
    else
            sleep 120
    fi
done


ECHO "Finished.\n"
exit 0
