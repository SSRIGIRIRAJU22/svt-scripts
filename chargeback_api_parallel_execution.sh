#!/usr/bin/bash


#---------------------------------------------------------------------------
#
# *** script for calling the charge back API in parallel ***
#
#
# File Name  :- $0
# Created on :- 24/11/2021
#
#
# Created by :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#--------------------------------------------------------------------------


ID=""
ENDPOINT=""
PASSWORD=""
ITERATIONS=""
WHITE='\e[97m'
EC='\033[0m'
BLUE='\033[94m'
RED='\033[91m'
GREEN='\033[92m'
UNDERLINE='\033[4m'


# usage function.
usage () {
    echo -e "${UNDERLINE}Usage:${EC}"
    echo -e "\n\t$0 [-e <End point>] [-u <X-CMC-Client-Id>] [-p <X-CMC-Client-Secret>] [-i <iterations>]\n"
    echo -e "${UNDERLINE}Supported Options:${EC}\n"
    echo -e "\t-e : Provide the API end point."
    echo -e "\t-u : Provide the X-CMC-Client-Id."
    echo -e "\t-p : Provide the X-CMC-Client-Secret."
    echo -e "\t-i : Provide the number of iteration to call the end point."
    echo -e "${UNDERLINE}Example:${EC}"
    echo -e "\n\t$0 -e https://api-dallas.cmc-staging.com/cmctestsvt2-powercloud/v1/ep/inventory/tags/SVT_CB_fw39c -u 8173ef2c-0f65-4522-8dfe-0134e1061974 -p a379add8-44dd-45bc-a77a-4bcd34a5b5ca -i 10\n"
    echo -e "Contact:- ${WHITE}Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)${EC}"
}

TEMP=`getopt -o "hi:e:u:p:" -l "api:,id:,passwd:,iterations:,help" -n $0 -- "$@"` || {
        echo "";
        exit 1
}

eval set -- "$TEMP"

## extract options and their arguments into variables.
while true
do
    case "$1" in

           -e | --api)
                   ENDPOINT=$2;
                   shift 2
                                    ;;
           -u | --id)
                   ID=$2;
                   shift 2
                                    ;;
           -p | --passwd)
                   PASSWORD=$2;
                   shift 2
                                    ;;
           -i | --iterations)
                   ITERATIONS=$2;
                   shift 2
                                    ;;
           -h | --help)
                   shift 1;
                   echo ""
                   usage
                   exit 0
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

if [[ "$#" -ne 0 ]]
then
        echo ""
        usage
        exit 1
fi

[[ "$ID" == "" ]] && echo -e "\nOption: --id is missing.\n" && usage && exit 1
[[ "$ENDPOINT" == "" ]] && echo -e "\nOption: -e is missing.\n" && usage && exit 1
[[ "$PASSWORD" == "" ]] && echo -e "\nOption: -p is missing.\n" && usage && exit 1
[[ "$ITERATIONS" == "" ]] && echo -e "\nOption: -i is missing.\n" && usage && exit 1


for (( i=0; $i < ${ITERATIONS}; ((i++)) ))
do
ST=$(date +%s)
echo "Start Time: $ST"

echo "Response:"
curl -s --write-out "\nAPI Status Code:%{http_code}" "${ENDPOINT}" -H "X-CMC-Client-Id:${ID}" -H "X-CMC-Client-Secret:{PASSWORD}" &
echo ""
ET=$(date +%s)
echo "End Time: $ET"
echo -e "Average Time: $((ET-ST)) second(s)\n"
echo "----------------------------------------------------------------------------------------------------------------"
done

wait
echo "Finished."
