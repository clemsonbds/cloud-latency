#!/usr/bin/env python3

import sys
import os
import argparse
import json
import glob

import pprint
pp = pprint.PrettyPrinter(indent=4)

def distance(a, b):
	return abs(a-b)

# mean of a list of dicts
def mean(l, key):
	return sum([s[key] for s in l]) / float(len(l))

# super simple 1-dimension kmeans clustering
def kmeans(samples, k, compare_key, max_iter=10):
	import random

	# find the range of the samples for initial centroids
	mn = min([s[compare_key] for s in samples])
	mx = max([s[compare_key] for s in samples])

	# k random centroids from within the range to get started
	centroids = []
	for _ in range(k):
		centroids.append(random.uniform(mn, mx))

	clusters = [samples[i::k] for i in range(k)]

	# start moving them around!
	for _ in range(max_iter):

		# track whether a move was made this iteration
		moved = False

		# stage 1, move values as needed based on distance
		for i in range(k):
			for sample in list(clusters[i]): # iterate over a copy so we can remove safely
				min_dist = float('inf')
				min_j = 0

				# find the centroid with the minimum distance
				for j in range(k):
					dist = distance(sample[compare_key], centroids[j])

					if dist < min_dist:
						min_dist = dist
						min_j = j

				# move sample to that cluster
				if min_j != i:
					moved = True
					clusters[i].remove(sample)
					clusters[min_j].append(sample)

		# if no moves were made, we're done
		if moved == False:
			break

		# stage 2, compute new centroids
		for i in range(k):
			centroids[i] = mean(clusters[i], compare_key)

	# all done
	return clusters

def parse_samples(fn_list):
	for fn in fn_list:
		with open(fn) as f:
			sample = json.load(f)
			yield {
				'pair':(sample['start']['connected'][0]['local_host'],
						sample['start']['connected'][0]['remote_host']),
				'bps':sample['end']['sum_received']['bits_per_second']
			}

# check that a pairing between host1 and host2 exists in pairs, order ignored
def pairing_exists(host1, host2, pairs):
	for pair in pairs:
		if host1 in pair and host2 in pair: # (a,b) == (b,a)
			return True

	return False

# check that a pairing exists between 'host' and every member of hosts
def all_pairings_exist(host1, hosts, pairs):
	for host2 in hosts:
		if not pairing_exists(host1, host2, pairs):
			return False

	return True

# reduce host pairings to a fully connected to set of hosts
def reduce_to_hosts(pairs):
	hosts = []

	for pair in pairs:
		for host in pair:
			if host not in hosts and all_pairings_exist(host, hosts, pairs): hosts.append(host)

	return hosts

def write_hostfile(hosts, fn):
	with open(fn, 'w') as f:
		for host in hosts:
			f.write(host+'\n')

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('--sample_dir', required=True)
	parser.add_argument('--output_dir', required=True)
	parser.add_argument('--filter_by')
	parser.add_argument('--K', type=int, default=2)
	parser.add_argument('--classes')

	args = vars(parser.parse_args())

	# sanity checking on input
	if args['classes']:
		classes = args['classes'].split(',')

		if len(classes) < args['K']:
			sys.exit("The class name list needs to be at least K long.")
	else:
		classes = ['class'+str(i) for i in range(1, args['K']+1)]

	# get list of iperf samples in result directory
	pattern = args['sample_dir'] + "/iperf"

	if args['filter_by']:
		pattern += "*" + args['filter_by']

	pattern += "*json"

	filenames = glob.glob(pattern)

	# parse the samples for host pairs and receive rate
	samples = list(parse_samples(filenames))

	sample_clusters = kmeans(samples, args['K'], 'bps')
	sample_clusters.sort(key=lambda c: mean(c, 'bps'))

	pair_clusters = [[s['pair'] for s in c] for c in sample_clusters]
	host_clusters = [reduce_to_hosts(c) for c in pair_clusters]

	# write output files
	for i in range(len(host_clusters)):
		fn = classes[i]+".hosts"

		with open(args['output_dir']+'/'+fn, 'w') as f:
			for host in host_clusters[i]:
				f.write(host+'\n')

if __name__ == "__main__":
	main()
