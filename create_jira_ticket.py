import requests
from requests.auth import HTTPBasicAuth
import argparse
import sys
import json
import time

parser = argparse.ArgumentParser()

parser.add_argument('--project', default="CMC")
parser.add_argument('-s', '--summary', required=True)
parser.add_argument('-d', '--description', required=True)
parser.add_argument('-t', '--issuetype', default="Task")
parser.add_argument('-a', '--assignee', required=True)
parser.add_argument('-c', '--components', required=True)
parser.add_argument('-l', '--labels', required=True)
parser.add_argument('-u', '--username', required=True)
parser.add_argument('-p', '--passwd', required=True)
#parser.add_argument('--priority', required=True)
#parser.add_argument('--severity', required=True)

args = parser.parse_args()

MYJIRA_ENDPOINT = "http://ehmc103.aus.stglabs.ibm.com:8080/rest/api/2/issue"

headers = {}

def create_jira_ticket():
    """
        This function is for creating the jira ticket.
    """

    REQUIRED_DATA = {
        "fields": {"project": {"key": None},
                   "summary": None, "description": None,
                   "issuetype": {"name": None},
                   "components": [{"name": None}],
                   "assignee": {"name": None}
        }
    }

    headers['Content-Type'] = "application/json"

    REQUIRED_DATA['fields']['project']['key'] = args.project
    REQUIRED_DATA['fields']['summary'] = args.summary
    REQUIRED_DATA['fields']['description'] = args.description
    REQUIRED_DATA['fields']['issuetype']['name'] = args.issuetype
    REQUIRED_DATA['fields']['components'][0]['name'] = args.components
    REQUIRED_DATA['fields']['assignee']['name'] = args.assignee
    
    
    jsonData = json.dumps(REQUIRED_DATA)
    print(jsonData)

    CREATE_TICKET = requests.post(MYJIRA_ENDPOINT,json=json.loads(jsonData),auth=HTTPBasicAuth(args.username, args.passwd))

    if CREATE_TICKET.status_code == 201:
        print(MYJIRA_ENDPOINT.replace('rest/api/2/issue', 'browse/' + CREATE_TICKET.json()['key']))
        return MYJIRA_ENDPOINT.replace('rest/api/2/issue', 'browse/' + CREATE_TICKET.json()['key'])
    else:
        print(CREATE_TICKET.status_code)
        print(CREATE_TICKET.json())
        sys.exit(-1)
    
create_jira_ticket()