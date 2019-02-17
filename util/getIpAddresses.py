#!/usr/bin/env python3

from __future__ import print_function

def perror(s):
	import sys
	print(s, file=sys.stderr)

class CloudResponseError(Exception):
	pass

def get_gcp_addresses(args):
	from googleapiclient import discovery
	from googleapiclient.errors import HttpError
	import os

	# Checking this variable because I have two GCP accounts and GCP doesn't allow for multiple profiles so I'm remapping here
	if 'GOOGLE_APPLICATION_CREDS' in os.environ:
		# Overwrite the default GCP account so that the correct account is utilized.
		credsPath = os.environ['GOOGLE_APPLICATION_CREDS']
		os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credsPath

	try:
		service = discovery.build('compute', 'v1', cache_discovery=False)
		request = service.instances().aggregatedList(
			project=args.project_id,
			filter="(labels.instance-type = \"%s\") AND (labels.experiment-name = \"%s\")" % (args.node_type, args.exp_name)
		)
		response = request.execute()

	except HttpError as e:
		perror(e._get_reason())
		raise CloudResponseError from e

	instances = sum([zone['instances'] if 'instances' in zone else [] for zone in response['items'].values()], [])
	return [instance['networkInterfaces'][0]['networkIP'] for instance in instances]

def get_aws_addresses(args):
	import subprocess
	import json

	if args.node_type == "bastion":
		name = args.exp_name+'-BastionHost'
		address_type = 'Public'
	elif args.node_type == "internal":
		name = args.exp_name+'-Instance'
		address_type = 'Private'

	try:
		response = subprocess.check_output([
			'aws',
			'ec2',
			'--region', str(args.region),
			'describe-instances',
			'--filters', 'Name=tag:Name,Values=%s ' % name, 'Name=instance-state-name,Values=running',
			"--output", "json"
		], stderr=subprocess.STDOUT)

	except subprocess.CalledProcessError as e:
		perror(str(e.output, 'utf-8'))
		raise CloudResponseError from e

	result = json.loads(response)
	instances = sum([reservation['Instances'] for reservation in result['Reservations']], [])

	address_key = "%sIpAddress" % address_type

	return [instance[address_key] for instance in instances]

def parse_args():
    import argparse
    parser = argparse.ArgumentParser()

    parser.add_argument('node_type', choices=['bastion','internal'])
    parser.add_argument('exp_name')

    subparsers = parser.add_subparsers(dest='platform', help="cloud computing platform")

    subp = subparsers.add_parser('gcp')
    subp.add_argument('project_id')

    subp = subparsers.add_parser('aws')
    subp.add_argument('region')

    return parser.parse_args()

def main():
	args = parse_args()
	attempts = 3

	for attempt in range(1, attempts+1):
		try:
			if args.platform == 'gcp':
				addresses = get_gcp_addresses(args)
			elif args.platform == 'aws':
				addresses = get_aws_addresses(args)

			break
		except CloudResponseError as e:
			if attempt < attempts:
				perror("Fetching addresses from %s failed, retrying (%d/%d)..." % (args.platform.upper(), attempt, attempts))
				import time
				time.sleep(1)
	else:
		perror("Fetching addresses from %s failed after %d attempts, aborting." % (args.platform.upper(), attempts))
		return

	if len(addresses) == 0:
		perror("No %s instances were found with the experiment name '%s'." % (args.node_type, args.exp_name))
		return

	if args.node_type == "bastion":
		addresses = addresses[:1]

	for address in addresses:
		print(address)

if __name__ == "__main__":
	main()
