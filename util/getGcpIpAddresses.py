#!/usr/bin/env python3

import sys
import os
from googleapiclient import discovery
from googleapiclient.errors import HttpError

# Checking this variable because I have two GCP accounts and GCP doesn't allow for multiple profiles so I'm remapping here
if 'GOOGLE_APPLICATION_CREDS' in os.environ:
    # Overwrite the default GCP account so that the correct account is utilized.
    credsPath = os.environ['GOOGLE_APPLICATION_CREDS']
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credsPath

service = discovery.build('compute', 'v1', cache_discovery=False)

projectId = sys.argv[1]

expName = sys.argv[2]

nodeType = sys.argv[3]

if nodeType == "bastion":
    request = service.instances().aggregatedList(project=projectId, filter="(labels.instance-type = \"bastion\") AND (labels.experiment-name = \"" + str(expName) + "\")")
    response = request.execute()
    try:
        for zone in response['items']:
            if "instances" in response['items'][zone]:
                print(response['items'][zone]['instances'][0]['networkInterfaces'][0]['accessConfigs'][0]['natIP'])
                sys.exit(0)
    except Exception:
        print("No Bastion IP Found")
        sys.exit(0)

elif nodeType == "internal":
    request = service.instances().aggregatedList(project=projectId, filter="(labels.instance-type = \"internal\") AND (labels.experiment-name = \"" + str(expName) + "\")")
    response = request.execute()
    try:
        foundInstance = False
        for zone in response['items']:
            if "instances" in response['items'][zone]:
                for instance in response['items'][zone]['instances']:
                    print(instance['networkInterfaces'][0]['networkIP'])
                    foundInstance = True
        if not foundInstance:
            print("No Internal IPs Were Found")
            sys.exit(0)
        else:
            sys.exit(0)
    except Exception:
        print("No Internal IPs Found")
        import traceback
        print(traceback.format_exc())        
        sys.exit(0)
else:
    print("Invalid Instance Type")
    sys.exit(0)
