#!/usr/bin/env python

import sys
import os
import json
import logging
import subprocess
import traceback

region = sys.argv[1]
expName = sys.argv[2]

try:
    # aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-BastionHost" "Name=instance-state-name,Values=running"
    response = subprocess.check_output(['aws', 'ec2', '--region', str(region), 'describe-instances', '--filters', 'Name=tag:Name,Values=' + str(expName) + '-BastionHost ', 'Name=instance-state-name,Values=running'], stderr=subprocess.STDOUT)
    temp = json.loads(response)

    # Get the IP address from the instance list
    print temp['Reservations'][0]['Instances'][0]['PublicIpAddress']
except subprocess.CalledProcessError as e:
    print ''.join(traceback.format_exc())
    print e.output
    sys.exit(0)

