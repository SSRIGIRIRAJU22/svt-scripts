#!/usr/bin/python3

import paramiko
import os, sys
import argparse
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException, ElementNotVisibleException
import time


class CODTemp:
    """
        *** This script will creates the COD template file & returns the file location. ***

    Modules required:
    ----------------
        1. paramiko
        2. os
        3. selenium, Options
        4. time

    Required arguments to pass in the function call:
    ----------------------------------------------
        1. HMC name
        2. System name
        3. Pool type
        4. Pool id
        5. COD web application
            a. user name
            b. password
            c. email
            d. first name  - (name)
            e. last name   - (surname)


    -----------------------------------
    File name   : generate_COD_codes.py
    Created by  : Saikumar Srigiriraju (ssrigiriraju@rocketsoftware.com)
    Created On  : 16/05/2021
    -----------------------------------
    """

    # calss level required items.
    CEC_MTMS        = {}
    pool_CMD        = "lssyscfg -r sys -m {CEC} -F metered_cod_pool_id"
    CEC_MTMS_CMD    = "lscod -m {CEC} -t code -c metered"
    POOL_TYPES      = {'ded': 'PB01', 'shared': 'PP01'}


    def arrange_sn(self, num):
        """
        this function is for handling sequence number in the
        CEC MTMS details.
        """
        l1 = [];
        l1.append(num)
        l1.append(str(int(num) + 1))
        l1.append(str(int(num) + 2))
        for i in l1:
            if len(i) != 4:
                l1[l1.index(i)] = '0' * (4 - len(i)) + i

        return l1

    def SSH(self, HMC, CMD, user_name="hscroot", password="abc123"):
        """
        this function is for ssh connection to the remote server.
        """

        try:
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh_client.connect(hostname=HMC, username=user_name, password=password)
            stdin, stdout, stderr = ssh_client.exec_command(CMD)

            return stdout.readlines()

        except paramiko.AuthenticationException as e:
            return "\nCould not able establish connection - Verify the credintionals."
        finally:
            ssh_client.close()

    def generate_COD(self, u_name, passwd, F_Name, L_Name, Email, S_N, OQ, E_C, P_Id, Serial, dept):

        """
        this function will connectes to COD generation page &
        generates the COD codes.

        Note: it runs in the background.
        return: COD code.
        """
        try:
            protocol = "https://"
            COD_App = "@w3.rchland.ibm.com/projects/lab-operations/request/cgi-bin/pod.acgi"
            url_path = protocol + u_name + ':' + passwd + COD_App

            op = Options()
            op.add_argument("--allow-running-insecure-content")
            op.add_argument("--ignore-certificate-errors")
            op.add_argument("--headless")
            op.add_argument('--no-sandbox')
            op.add_argument('--disable-dev-shm-usage')
            driver = webdriver.Chrome(executable_path='/home/chrome_driver/chromedriver',options=op)
            driver.get(url_path)
            time.sleep(6)

            # home page data
            f_name = driver.find_element_by_name('first')
            f_name.clear()
            f_name.send_keys(F_Name)

            l_name = driver.find_element_by_name('last')
            l_name.clear()
            l_name.send_keys(L_Name)

            Serial_Inp = driver.find_element_by_name('serial')
            Serial_Inp.clear()
            Serial_Inp.send_keys(Serial)

            DEPT_Inp = driver.find_element_by_name('dept')
            DEPT_Inp.clear()
            DEPT_Inp.send_keys(dept)

            Email_Inp = driver.find_element_by_name('email')
            Email_Inp.clear()
            Email_Inp.send_keys(Email)

            driver.find_element_by_name('opt').click()
            driver.find_element_by_name('next').click()
            #driver.implicitly_wait(10)
            time.sleep(10)

            # Power COD page data.
            driver.find_element_by_name('systype').send_keys(self.CEC_MTMS['sys_type'])
            driver.find_element_by_name('syssn').send_keys(self.CEC_MTMS['sys_serial_num'])
            driver.find_element_by_name('prcfcode').send_keys(self.CEC_MTMS['anchor_card_ccin'])
            driver.find_element_by_name('prccrdsn').send_keys(self.CEC_MTMS['anchor_card_serial_num'])
            driver.find_element_by_name('prccrdid').send_keys(self.CEC_MTMS['anchor_card_unique_id'])
            driver.find_element_by_name('podactf').send_keys(self.CEC_MTMS['resource_id'])
            driver.find_element_by_name('podactprc').send_keys(self.CEC_MTMS['activated_resources'])
            driver.find_element_by_name('podsednum').send_keys(S_N)
            driver.find_element_by_name('podordact').send_keys(OQ)
            driver.find_element_by_name('podactchk').send_keys(E_C)
            driver.find_element_by_name('codindex').send_keys(P_Id)
            driver.find_element_by_name('submit').click()
            #driver.implicitly_wait(20)
            time.sleep(12)

            # get the code.
            code = driver.find_element_by_css_selector("td[colspan='7']")

            return code.text

        except NoSuchElementException:
            return "Failed to generated code"
        except ElementNotVisibleException:
            return "Failed to generated code"
        finally:
            driver.close()


    def generate_authorization_code(self, name, pwd, firstname, lastname, mail, id, pooltype, ec, sn, dep, serial_number):

        AC = self.generate_COD(u_name=name, passwd=pwd, F_Name=firstname, L_Name=lastname, Email=mail, S_N=sn, P_Id=id, E_C=ec,
                                OQ=pooltype, dept=dep, Serial=serial_number)
        return AC


    def generate_resource_code(self, N, P, F, L, M, S, CPU, E, MEMORY, USER_DEPT, USER_SN):

        RC = self.generate_COD(u_name=N, passwd=P, F_Name=F, L_Name=L, Email=M, S_N=S, OQ=CPU, E_C=E, P_Id=MEMORY, Serial=USER_SN, dept=USER_DEPT)
        return RC


    def generate_deauth_code(self, NAME, PASS, MAIL, FN, LN, TIME, POOLID, EC, SERIALNUMBER, COD_USER_DEPT, COD_USER_SN):

        DC = self.generate_COD(u_name=NAME, passwd=PASS, F_Name=FN, L_Name=LN, Email=MAIL, S_N=SERIALNUMBER,
                OQ=TIME, E_C=EC, P_Id=POOLID, Serial=COD_USER_SN, dept=COD_USER_DEPT)

        return DC


    def get_mtms_details(self, hmc, system):

        # get the MTMS details of the CEC.
        CEC_MTMS_Res = self.SSH(HMC=hmc, CMD=self.CEC_MTMS_CMD.replace('{CEC}', system))
        if len(CEC_MTMS_Res) == 0:
            print("Failed to get the MTMS details.")
            exit()


        for details in CEC_MTMS_Res[0].split(','):
                ref = details.split('=')
                self.CEC_MTMS[ref[0]] = ref[1].strip('\n')


    def generate_auth_res_deauth_codes(self, HMC, CEC, POOL_ID, POOL_TYPE, COD_USERNAME, COD_PASSWORD, COD_MAIL, COD_FN, COD_LN, COD_DEPT, COD_SN):

        # this will get the MTMS details for th egiven cec
        print("Finding the mtms details for the given machine ...")
        self.get_mtms_details(hmc=HMC, system=CEC)
        print(self.CEC_MTMS)

        # prepare sequence number
        print("Preparing the sequence numbers ...")
        SN = self.arrange_sn(num=self.CEC_MTMS['sequence_num'])
        print(SN)

        # generate authorization code
        if POOL_TYPE in self.POOL_TYPES:
            POOL_TYPE = self.POOL_TYPES[POOL_TYPE]
        else:
            print("Invalid pool type given :-", POOL_TYPE)
            exit()

        print("Generating the authorization code ...")
        ac = self.generate_authorization_code(name=COD_USERNAME, pwd=COD_PASSWORD, firstname=COD_FN,
                lastname=COD_LN, mail=COD_MAIL, id=POOL_ID, pooltype=POOL_TYPE, ec=self.CEC_MTMS['entry_check'], sn=SN[0],
                            dep=COD_DEPT, serial_number=COD_SN)

        print(ac)

        # generate resource code
        print("Generating the resource code ...")
        res = self.generate_resource_code(N=COD_USERNAME, P=COD_PASSWORD, F=COD_FN, L=COD_LN, M=COD_MAIL, S=SN[1], CPU='0100',
                E='XX', MEMORY='0001', USER_DEPT=COD_DEPT, USER_SN=COD_SN)
        print(res)

        # generate deauth code
        print("Generating the de-authorizaation code ...")
        dea = self.generate_deauth_code(NAME=COD_USERNAME, PASS=COD_PASSWORD, MAIL=COD_MAIL, FN=COD_FN, LN=COD_LN, TIME='Q030',
                POOLID=POOL_ID, EC='XX', SERIALNUMBER=SN[2], COD_USER_DEPT=COD_DEPT,COD_USER_SN=COD_SN)
        print(dea)

    def generate_resource_code_only(self, HMC, CEC, POOL_ID, POOL_TYPE, COD_USERNAME, COD_PASSWORD, COD_MAIL, COD_FN, COD_LN, COD_DEPT, COD_SN):

        # this will get the MTMS details for th egiven cec
        print("Finding the mtms details for the given machine ...")
        self.get_mtms_details(hmc=HMC, system=CEC)
        print(self.CEC_MTMS)

        print("Generating the resource code ...")
        res = self.generate_resource_code(N=COD_USERNAME, P=COD_PASSWORD, F=COD_FN, L=COD_LN, M=COD_MAIL, S=self.CEC_MTMS['sequence_num'], CPU='0100',
                                E='XX', MEMORY='0001', USER_DEPT=COD_DEPT, USER_SN=COD_SN)
        print(res)

    def generate_authorization_code_only(self, HMC, CEC, POOL_ID, POOL_TYPE, COD_USERNAME, COD_PASSWORD, COD_MAIL, COD_FN, COD_LN, COD_DEPT, COD_SN):

        print("Finding the mtms details for the given machine ...")
        self.get_mtms_details(hmc=HMC, system=CEC)
        print(self.CEC_MTMS)

        if POOL_TYPE in self.POOL_TYPES:
                POOL_TYPE = self.POOL_TYPES[POOL_TYPE]
        else:
                print("Invalid pool type given :-", POOL_TYPE)
                exit()

        print("Generating the authorization code ...")
        ac = self.generate_authorization_code(name=COD_USERNAME, pwd=COD_PASSWORD, firstname=COD_FN,lastname=COD_LN, mail=COD_MAIL, id=POOL_ID, pooltype=POOL_TYPE, ec=self.CEC_MTMS['entry_check'], sn=self.CEC_MTMS['sequence_num'],dep=COD_DEPT, serial_number=COD_SN)
        print(ac)

    def generate_deauth_code_only(self, HMC, CEC, POOL_ID, POOL_TYPE, COD_USERNAME, COD_PASSWORD, COD_MAIL, COD_FN, COD_LN, COD_DEPT, COD_SN):

        print("Finding the mtms details for the given machine ...")
        self.get_mtms_details(hmc=HMC, system=CEC)
        print(self.CEC_MTMS)

        # generate deauth code
        print("Generating the de-authorizaation code ...")
        dea = self.generate_deauth_code(NAME=COD_USERNAME, PASS=COD_PASSWORD, MAIL=COD_MAIL, FN=COD_FN, LN=COD_LN, TIME='Q030',
                                    POOLID=POOL_ID, EC='XX', SERIALNUMBER=self.CEC_MTMS['sequence_num'], COD_USER_DEPT=COD_DEPT,COD_USER_SN=COD_SN)
        print(dea)


parser = argparse.ArgumentParser()
parser.add_argument('--hmc', required=True)
parser.add_argument('--cec', required=True)
parser.add_argument('--poolid', required=True)
parser.add_argument('--pooltype', required=True)
parser.add_argument('--username', required=True)
parser.add_argument('--password', required=True)
parser.add_argument('--firstname', required=True)
parser.add_argument('--lastname', required=True)
parser.add_argument('--mail', required=True)
parser.add_argument('--serialnumber', required=True)
parser.add_argument('--dept', required=True)
parser.add_argument('-a', action='store_true')
parser.add_argument('-r', action='store_true')
parser.add_argument('-d', action='store_true')
parser.add_argument('--all', action='store_true')
args = parser.parse_args()

if args.all == True:
    CODTemp().generate_auth_res_deauth_codes(HMC=args.hmc, CEC=args.cec, POOL_ID=args.poolid, COD_USERNAME=args.username, COD_PASSWORD=args.password,COD_FN=args.firstname, COD_LN=args.lastname, COD_MAIL=args.mail, POOL_TYPE=args.pooltype, COD_DEPT=args.dept, COD_SN=args.serialnumber)
elif args.r == True:
    CODTemp().generate_resource_code_only(HMC=args.hmc, CEC=args.cec, POOL_ID=args.poolid, COD_USERNAME=args.username, COD_PASSWORD=args.password,COD_FN=args.firstname, COD_LN=args.lastname, COD_MAIL=args.mail, POOL_TYPE=args.pooltype, COD_DEPT=args.dept, COD_SN=args.serialnumber)
elif args.a == True:
    CODTemp().generate_authorization_code_only(HMC=args.hmc, CEC=args.cec, POOL_ID=args.poolid, COD_USERNAME=args.username, COD_PASSWORD=args.password,COD_FN=args.firstname, COD_LN=args.lastname, COD_MAIL=args.mail, POOL_TYPE=args.pooltype, COD_DEPT=args.dept, COD_SN=args.serialnumber)
elif args.d == True:
    CODTemp().generate_deauth_code_only(HMC=args.hmc, CEC=args.cec, POOL_ID=args.poolid, COD_USERNAME=args.username, COD_PASSWORD=args.password,COD_FN=args.firstname, COD_LN=args.lastname, COD_MAIL=args.mail, POOL_TYPE=args.pooltype, COD_DEPT=args.dept, COD_SN=args.serialnumber)
else:
    print("bad input given")
