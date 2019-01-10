#!/usr/bin/env python

import sys
import os
import json
import logging
import subprocess
import traceback

region = sys.argv[1]
expName = sys.argv[2]
nodeType = sys.argv[3]

try:
    if nodeType == "bastion":
        # aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-BastionHost" "Name=instance-state-name,Values=running"
        response = subprocess.check_output(['aws', 'ec2', '--region', str(region), 'describe-instances', '--filters', 'Name=tag:Name,Values=' + str(expName)+'-BastionHost ', 'Name=instance-state-name,Values=running', "--output", "json"], stderr=subprocess.STDOUT)
        temp = json.loads(response)

        # Get the IP address from the instance list
        print(temp['Reservations'][0]['Instances'][0]['PublicIpAddress'])

    elif nodeType == "internal":
        response = subprocess.check_output(['aws', 'ec2', '--region', str(region), 'describe-instances', '--filters', 'Name=tag:Name,Values=' + str(expName)+'-Instance ', 'Name=instance-state-name,Values=running', "--output", "json"], stderr=subprocess.STDOUT)
        temp = json.loads(response)

        if len(temp['Reservations']) > 0:
            for instance in temp['Reservations'][0]['Instances']:
                print(instance['PrivateIpAddress'])

except subprocess.CalledProcessError as e:
    print(''.join(traceback.format_exc()), file=sys.stderr)
    print(e.output, file=sys.stderr)
    sys.exit(0)
