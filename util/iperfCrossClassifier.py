#!/usr/bin/env python

import sys
import os
import argparse
import json
import glob

import pprint
pp = pprint.PrettyPrinter(indent=4)

def dist(a, b):
	return abs(a-b)

def sort(items, key):
	items.sort(key=lambda i: i[key])

def chunk(items, K):
	n = int((len(items) + 1) / K)
	return [items[i:i + n] for i in range(0, len(items), n)]

def centroid_median(c, key):
	sort(c, key) # sort the list
	c[0], c[int(len(c)/2)] = c[int(len(c)/2)], c[0] # swap median to the beginning

def centroid_mean(c, key):
	m = mean(c, key)
	closest_i = 0 # index of current centroid

	for i in range(1, len(c)):
		if dist(c[i][key], m) < dist(c[closest_i][key], m):
			closest_i = i

	c[0], c[i] = c[i], c[0] # swap closest with current centroid

# super simple 1-dimension kmeans clustering
def kmeans(items, K, key, max_iter=10):

	clusters = chunk(items, K)
	moved = True

	# centroids are the first item of each list

	# start moving them around!
	while moved == True:
		pp.pprint(clusters)

		# stage 1, compute centroids
		for c in clusters:
			centroid_mean(c, key)

		pp.pprint(clusters)

		# track whether a move was made this iteration
		moved = False

		# stage 1, move values as needed based on distance
		for current in clusters:
			for item in list(current[1:]): # iterate over a copy so we can remove safely
				closest = current

				# find the centroid with the minimum distance to the sample
				for other in clusters:
					if dist(item[key], other[0][key]) < dist(item[key], current[0][key]):
						closest = other

				# move sample to that cluster
				if closest != current:
					moved = True
					current.remove(item)
					closest.append(item)

	pp.pprint(clusters)

	# all done
	return clusters

def ssd(items, key):
	m = mean(items, key)
	return sum([(i[key]-m) ** 2 for i in items])

def jenks(items, K, key, target_GVF, max_iter=10):
	sort(items, key)
	classes = chunk(items, K)

#	sdam = ssd(items, key)
	ssds = [ssd(cls, key) for cls in classes]

	while True:
#		sdcm = sum(ssds)
#		gvf = (sdam - sdcm) / sdam
#		pp.pprint(classes)
#		print(gvf)

		mx = 0
		mn = 0

		for i in range(K):
			if ssds[i] > ssds[mx]:
				mx = i
			if ssds[i] < ssds[mn]:
				mn = i

		if mx == mn:
			break

		# calculate new ssd values before changing
		if mx > mn:
			ssd_mx = ssd(classes[mx][1:], key)
			ssd_mn = ssd(classes[mn]+classes[mx][:1], key)
		else:
			ssd_mx = ssd(classes[mx][:-1], key)
			ssd_mn = ssd(classes[mn]+classes[mx][:-1], key)

		# if it makes gvf worse, quit now
		if ssd_mx + ssd_mn >= ssds[mx] + ssds[mn]:
			break

		# otherwise go ahead
		if mx > mn:
			classes[mn].append(classes[mx].pop(0))
		else:
			classes[mn].append(0, classes[mx].pop()) # sort below anyway

		# update the ssds
		ssds[mx] = ssd_mx
		ssds[mn] = ssd_mn

		sort(classes[mn], key)

	return classes

def parse_samples(fn_list):
	for fn in fn_list:
		with open(fn) as f:
			sample = json.load(f)
			yield {
				'pair':(sample['start']['connected'][0]['local_host'],
						sample['start']['connected'][0]['remote_host']),
				'bps':sample['end']['sum_received']['bits_per_second']
			}

# mean of a list of dicts
def mean(l, key):
	return sum([s[key] for s in l]) / float(len(l))

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
	parser.add_argument('--filter_by')
	parser.add_argument('--descending', action='store_true', help='use if the first class name should match largest cluster median value')
	parser.add_argument('--stdout', action='store_true', help='describe clusters to stdout rather than write hostfiles')

	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('--output_dir')
	group.add_argument('--quiet', action='store_true', help='reduces stdout stream to one class per line (in order provided), comma separated values')

	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('--K', type=int)
	group.add_argument('--classes')

	args = vars(parser.parse_args())

	# sanity checking on input
	if args['classes']:
		classes = args['classes'].split(',')
		K = len(classes)
	else:
		K = args['K']
		classes = ['class'+str(i) for i in range(1, args['K']+1)]

	# get list of iperf samples in result directory
	pattern = args['sample_dir'] + "/iperf"

	if args['filter_by']:
		pattern += "*" + args['filter_by']

	pattern += "*json"

	filenames = glob.glob(pattern)

	# parse the samples for host pairs and receive rate
	samples = list(parse_samples(filenames))

	if len(samples) < K:
		print("Warning: ", len(samples), " provided, reducing K to match.")
		K = len(samples)

#	sample_clusters = kmeans(samples, K, 'bps')
	sample_clusters = jenks(samples, K, 'bps', 1)

	# sort to match key order
	sample_clusters.sort(key=lambda c: mean(c, 'bps'), reverse=args['descending'])

	# detach host pairs from measured values
	pair_clusters = [[s['pair'] for s in c] for c in sample_clusters]

	# reduce hosts in each cluster to unique and fully connected within the cluster
	host_clusters = [reduce_to_hosts(c) for c in pair_clusters]

	# hack, hosts only exist in one cluster, assume left-dominant
	# and remove duplicates in classes to the right
#	for i in range(len(host_clusters)-1):
#		for host in host_clusters[i]:
#			if host in host_clusters[i+1]:
#				host_clusters[i+1].remove(host)

	# write output files
	for i in range(len(host_clusters)):
		if args['stdout']:
			if args['quiet']:
				print(','.join(host_clusters[i]))
			else:
				print(classes[i], " - ", host_clusters[i])
		else:
			fn = classes[i]+".hosts"

			with open(args['output_dir']+'/'+fn, 'w') as f:
				for host in host_clusters[i]:
					f.write(host+'\n')

if __name__ == "__main__":
	main()
