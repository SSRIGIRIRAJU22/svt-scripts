#!/usr/bin/python3

#-----------------------------------------------------------------------
# *** This script is for generating the pesh password for the vHMC ***
#
#
#  Created On: 01/Nov/2022
#  Created By: Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
#-----------------------------------------------------------------------


import requests, sys, json, os
from datetime import date
import getopt
import time, re
import urllib3
urllib3.disable_warnings()
sys.tracebacklimit=0
from requests.auth import HTTPBasicAuth
from datetime import datetime


## colour codes
BLUE        = '\033[94m'
GREEN       = '\033[92m'
RED         = '\033[91m'
BOLD        = '\033[1m'
UNDERLINE   = '\033[4m'
END         = '\033[0m'


def print_help():
    """Prints command line options and exits"""

    print("""
Usage:
------
        ./generate_pesh_passwords.py -u <IBM id> -p <Password> --hmc <vHMC name with UVMID/SE> -r <singleDay|threeDay|multipleDay> -s <YYYY-MM-DD> -e <YYYY-MM-DD> [-f] [-h]

Long Options:
-------------
        --hmc : Provide the vHMC(s) name along with UVMID or SE with : seperated
                Eg:- waldevcmchmc06:897f:5f78:4903:4153

                Multiple values can be given with comma superated
                Eg:- waldevcmchmc06:897f:5f78:4903:4153,waldevcmchmc07:b17f:391a:4a00:4f57

Short Options:
--------------
        -u : Provide the IBM id
        -p : Provide the IBM id password
        -r : Request type
             Supported options are 'singleDay|threeDay|multipleDay'
        -s : Start date
             Provide in YYYY-MM-DD format only. Eg:- 2022-11-01
        -e : End date
             Provide in YYYY-MM-DD format only. Eg:- 2022-12-01
        -f : To format the data according to the Jira table
        -h : help

Additional Info:
----------------
        Contact :- Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
""")
    sys.exit()



def generate_pesh_password(USERNAME, USERPASS, REQUEST_TYPE, HMCS, START_DATE, END_DATE):
    """
    This function is for generating the pesh password for the vHMC.
    """
    # API end points.
    AUTH_ENDPOINT = "https://pex.pok.ibm.com/pepw/rs/auth"
    REQUEST_PESH_PASS_ENDPOINT = "https://pex.pok.ibm.com/pepw/rs/pw/request"

    headers = {"Content-Type":"application/json"}

    DATA = {'id': USERNAME, 'pass': USERPASS}
    JD = json.dumps(DATA,skipkeys = True)

    print()
    print(str(datetime.now()).split('.')[0], ": Validating the given credentials ...", end=" ")

    # post request for validating the given credentials
    AUTH_RES = requests.post(AUTH_ENDPOINT, headers=headers, data=JD, verify=False)

    # Verifying/validating the API response
    if AUTH_RES.status_code == 200:
        print(GREEN + "Passed" + END)
    else:
        print(RED + "Failed" + END)
        print(AUTH_RES.json()['message'])
        sys.exit(-1)


    API_INPUT_DATA = {"requestType": None,"algId": "vhmc","serialNumber": None, "reasonCode": "1015","start": None,"stop": None,"outputFormat": "list"}
    ALL_PESH_PASS_DICT  = {}
    ALL_PESH_PASS       = ""
    ALL_HMC_NAMES       = ""

    for i in HMCS.split(','):

        print(str(datetime.now()).split('.')[0], ": Generating the password(s) for" , i.split(':', 1)[0], "...", end=" ")

        API_INPUT_DATA['requestType']   = REQUEST_TYPE
        API_INPUT_DATA['serialNumber']  = i.split(':', 1)[1]
        API_INPUT_DATA['start']         = START_DATE
        API_INPUT_DATA['stop']          = END_DATE


        test_jd = json.dumps(API_INPUT_DATA)

        # post request for generating the  pesh password(s)
        REQ_PASS_RES = requests.post(REQUEST_PESH_PASS_ENDPOINT, headers=headers, verify=False, data=test_jd, auth=HTTPBasicAuth(USERNAME, USERPASS))

        # Verifying/validating the API response
        if REQ_PASS_RES.status_code == 200:
            print(GREEN + "Passed" + END)
            ALL_HMC_NAMES += " || " + i.replace(':', ' ',1)
            ALL_PESH_PASS_DICT[i] = REQ_PASS_RES.json()['data']['resultStrings']
        else:
            print(RED + "Failed" + END)
            print(REQ_PASS_RES.status_code)
            print(REQ_PASS_RES.json())
            sys.exit(-1)
    else:
        ALL_HMC_NAMES+= " ||"

        if FORMAT_DATA == "YES":
            print(str(datetime.now()).split('.')[0], ": Formatting the data ...", end=" ")


            tmp1 = HMCS.split(',')
            for j in ALL_PESH_PASS_DICT[tmp1[0]]:
                for k in tmp1:
                    ALL_PESH_PASS += ' | ' + j + " " + ALL_PESH_PASS_DICT[k][j]
                else:
                     ALL_PESH_PASS += ' |\n'
            else:
                print(GREEN + "Passed" + END)
                ALL_HMC_NAMES += '\n' + ALL_PESH_PASS

            FILENAME = "vhmcs_pesh_passwords_" + datetime.now().strftime("%Y%m%d%H%M%S") + ".txt"
            with open(FILENAME, 'w') as fo:
                fo.write(ALL_HMC_NAMES)

            print(str(datetime.now()).split('.')[0], ": For pesh passwords refer this file ...", BLUE + FILENAME + END)
        else:
            print(HMCS)
            print(ALL_PESH_PASS_DICT)


        print(str(datetime.now()).split('.')[0], ": Finished.")
        sys.exit(0)



def main(argv):

    # Global variables
    global USER_NAME, USER_PASSWORD, HMCS, REQUEST_TYPE, START_DATE, END_DATE, FORMAT_DATA

    USER_NAME       = ""
    USER_PASSWORD   = ""
    HMCS            = ""
    REQUEST_TYPE    = ""
    START_DATE      = ""
    END_DATE        = ""
    FORMAT_DATA     = "NO"

    opts, args = getopt.getopt(argv, "hu:p:r:s:e:f", ["hmc="])

    for opt, arg in opts:

        if opt == '-h':
            print_help()
        if opt == '-u':
            USER_NAME = arg
        if opt == '-p':
            USER_PASSWORD = arg
        if opt == '--hmc':
            HMCS = arg
        if opt == '-r':
            REQUEST_TYPE = arg
        if opt == '-s':
            START_DATE = arg
        if opt == '-e':
            END_DATE = arg
        if opt == '-f':
            FORMAT_DATA = "YES"


    if USER_NAME == "":
        print()
        print("Option: -u is missing.")
        print_help()

    if USER_PASSWORD == "":
        print()
        print("Option: -p is missing.")
        print_help()

    if HMCS == "":
        print()
        print("Option: --hmc is missing.")
        print_help()
    if REQUEST_TYPE == "":
        print()
        print("Option: -r is missing.")
        print_help()
    if START_DATE == "":
        print()
        print("Option: -s is missing.")
        print_help()
    if END_DATE == "":
        print()
        print("Option: -e is missing.")
        print_help()

    if REQUEST_TYPE != "multipleDay":
        print()
        print("Received invalid argument for option '-r'")
        print("At the moment script supports only 'multipleDay'")
        print("Try with 'multipleDay'")
        sys.exit(-1)

    if re.fullmatch('\d\d\d\d-\d\d-\d\d', START_DATE):
        pass
    else:
        print()
        print("Received invalid argument for option: '-s'")
        print_help()
        sys.exit(-1)

    if re.fullmatch('\d\d\d\d-\d\d-\d\d', END_DATE):
        pass
    else:
        print()
        print("Received invalid argument for option: '-e'")
        print_help()
        sys.exit(-1)

    # If all the required values received calling the functon to generate the pesh password
    if USER_NAME and USER_PASSWORD and HMCS and REQUEST_TYPE and START_DATE and END_DATE:
        generate_pesh_password(USER_NAME, USER_PASSWORD, REQUEST_TYPE, HMCS, START_DATE, END_DATE)
    else:
        print_help()
        sys.exit(-1)


if __name__ == "__main__":
    main(sys.argv[1:])
