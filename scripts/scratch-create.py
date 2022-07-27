#!/usr/bin/env python3
import json, os
import requests

print('\n\nCREATING SCRATCH ORG...\n\n')
print('################################################################\n\n')

project_url = os.getcwd()

org_name = input('Scratch org name: ')
scratch_type = input('Org Type ? (scratch|sandbox)')

print('\nCreating Scratch...\n')
 

os.system('sfdx force:org:create -a "{org_name}" -f "{project_url}/config/project-scratch-def.json" -s -w 10 -d 30 -t {scratch_type}'.format(org_name=org_name, scratch_type=scratch_type, project_url=project_url ))

os.system('sfdx force:config:set defaultusername={org_name}'.format(org_name=org_name))

print('\nImporting components...\n')

auth_data = json.loads(
    os.popen('sfdx force:org:display --json').read()
)['result']

os.system('sfdx force:source:push -f')

print('\n\nScratch org created successfully.\n')