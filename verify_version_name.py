import requests
import argparse
import sys

parser = argparse.ArgumentParser()

parser.add_argument('-p', '--project', default="CMC")
parser.add_argument('-v', '--version', required=True)
parser.add_argument('-k', '--apikey', required=True)

args = parser.parse_args()

ALL_PROJECTS = ""
ALL_VERSIONS = ""
PROJECT_NAME = args.project
API_TOKEN = "token " + args.apikey

AUTHENTICATE_ENDPOINT = "https://rocketsoftware.blackducksoftware.com/api/tokens/authenticate"
GET_PROJECTS_ENDPOINT = "https://rocketsoftware.blackducksoftware.com/api/projects"
GET_ALL_VERSIONS_ENDPOINT = ""

headers = {}

def generate_bearer_token():
    """
        This function is for generating the bearer token.
    """
    
    headers["Authorization"] = API_TOKEN
    post_req = requests.post(AUTHENTICATE_ENDPOINT, headers=headers)
    
    return "Bearer " + str(post_req.json()['bearerToken'])


def get_my_project_from_all_projects():

    headers["Accept"] = "application/vnd.blackducksoftware.project-detail-4+json"
    headers["Authorization"] = TOKEN
    
    ALL_PROJECTS = requests.get(GET_PROJECTS_ENDPOINT, headers=headers)

    for i in ALL_PROJECTS.json()["items"]:
        if i["name"] == PROJECT_NAME:
            for j in i["_meta"]['links']:
                if j['rel'] == "versions":
                    return j['href']
                    

def get_all_version_names():

    headers["Authorization"] = TOKEN
    Request3 = requests.get(GET_ALL_VERSIONS_ENDPOINT, headers=headers)
    ALL_VERSIONS = Request3.json()['items']

    for i in ALL_VERSIONS:
        if args.version == i['versionName']:
            print(f"Given verion name: {args.version} already exist, please use different version name")
            sys.exit(-1)

            
TOKEN = generate_bearer_token()
GET_ALL_VERSIONS_ENDPOINT =  get_my_project_from_all_projects()
get_all_version_names()
