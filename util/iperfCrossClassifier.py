#!/usr/bin/env python -O

import logging as log

def parse_args():
	import argparse
	import time

	parser = argparse.ArgumentParser()

#	parser.add_argument('--sample_dir', required=True)
#	parser.add_argument('--filter_by', help='a pattern to include in input files')
	parser.add_argument('--sample_files', nargs='+', help='JSON result files from iperf')
	parser.add_argument('--stdout_type', default='csv', choices=['none','csv','json'])
	parser.add_argument('--output_dir', help='write hostfiles named <class>.hosts to this directory')
	parser.add_argument('--verbose', default=False, action='store_true', help='output processing steps, followed by the output specified by stdout_type')
	parser.add_argument("--logfile", nargs='?', default=None, const="./%s.log" % (time.strftime('%m-%d-%Y_%H:%M:%S')))

	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('--K', type=int, help='the number of groups to divide samples into, will generate labels')
	group.add_argument('--labels', type=str, nargs='+', help='two or more class labels, in DESCENDING bandwidth order')

	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('--means', type=float, nargs='+', help='list of mean values, must match number of class_labels')
	group.add_argument('--thresholds', type=float, nargs='+', help='list of threshold values, 1 less than number of class labels')

#	subp = subparsers.add_parser('dynamic', help='use a clustering algorithm to divide samples into K clusters')
#	subp.add_argument('--K', required=True, type=int, help='the number of clusters')
#	subp.add_argument('--min_distance', default=False, action='store_true', help='recombine clusters whose means are within a factor of X of eachother,\n   i.e. 10 and 9 are within factor of 0.1 of eachother')

	return parser.parse_args()

def main():
	args = parse_args()
	log_init(logfile=args.logfile, verbose=args.verbose)

	# sanity checking on input
	if args.labels:
		labels = args.labels
	else:
		labels = ['class%d'%(i+1) for i in range(args.K)]

	K = len(labels)

	# get list of iperf samples in result directory
#	pattern = os.path.join(args.sample_dir, "iperf")

#	if args.filter_by:
#		pattern += "*" + args.filter_by

#	pattern += "*json"
#	sample_files = glob.glob(pattern)

	# parse the samples for host pairs and receive rate
	samples = [parse_sample(f) for f in args.sample_files]
	log.info("Parsed %d samples from %d files." % (len(samples), len(args.sample_files)))

	if len(samples) < K:
		raise ValueError("Only %d samples were provided for %d clusters." % (len(samples), K))

	if args.means:
		clusters = cluster_by_proximity(samples, K, args.means, 'bps')
		sort_keys = args.means
	elif args.thresholds:
		clusters = cluster_by_threshold(samples, K, args.thresholds, 'bps')
		sort_keys = args.thresholds+[0]
#	elif args.cluster_method == 'dynamic':
#		clusters = cluster_by_magic(samples, K, 'bps')

	groups = [{
		'label':label.strip(),
		'samples':cluster,
		'sort_key':key
	} for label, cluster, key in zip(labels, clusters, sort_keys)]

	# reduce to hosts that share the group characteristic with all other hosts in the group
	for group in groups:
		group['connected_hosts'] = get_fully_connected_hosts(group['samples'])
		group['exclusive_hosts'] = group['connected_hosts'].copy()

	# sort descending by mean bandwidth so we can apply a top down filter
	# sort to match class label order
	groups.sort(key=lambda c: c['sort_key'], reverse=True)

	# if a node appears in a high bw group, we need to remove it from other groups
	for i in range(0, K-1): # maintain top-down order
		for host in groups[i]['exclusive_hosts']:
			for j in range(i+1, K):
				groups[j]['exclusive_hosts'].discard(host)

	# write hostfiles
	if args.output_dir:
		for group in groups:
			filename = '.'.join([group['label'], "hosts"])
			write_hostfile(args.output_dir, filename, group['exclusive_hosts'])

	# write stdout
	if args.stdout_type == 'json':
		pprint(groups)
	elif args.stdout_type == 'csv':
		for group in groups:
			print(group['label']+","+','.join(group['exclusive_hosts']))

def cluster_by_proximity(items, K, class_means, key):
	if len(class_means) != K:
		raise ValueError("%d class mean values provided for %d clusters." % (len(class_means), K))

	clusters = [[] for _ in range(K)]

	for s in items:
		differences = [abs(seed - s[key]) for seed in class_means]
		min_index = min(range(K), key=differences.__getitem__) # https://stackoverflow.com/a/11825864/3808882
		clusters[min_index].append(s)

	return clusters

def cluster_by_threshold(items, K, class_thresholds, key):
	if len(class_thresholds) != K-1:
		raise ValueError("%d class threshold values provided for %d clusters." % (len(class_thresholds), K))

	thresholds = sorted(class_thresholds, reverse=True)
	clusters = [[] for _ in range(K)]

	for s in items:
		for i in range(K):
			if s[key] >= thresholds[i]:
				clusters[i].append(s)
				break

	return clusters

#def cluster_by_magic(items, K, key, min_distance=None):
##	clusters = cluster_by_kmeans(items, clusters, key)
##	clusters = cluster_by_jenks(items, clusters, key, 1)
#	clusters = cluster_by_stupid(items, clusters, key)
#
#	# recombine clusters that are too close to eachother
#	if min_distance is not None:
#		# start i at the second to last cluster of the list, move from right to left
#		for i in reversed(range(len(clusters)-1)):
#
#			# try to combine with each of the clusters to the right, in right-left order
#			for j in reversed(range(i+1, len(clusters))):
#				mean_i = mean(clusters[i], key) # recompute this every time, since it can change with each combining of i and j
#				mean_j = mean(clusters[j], key)
#				min_dist = max(mean_i, mean_j) * min_distance # always use the maximum mean for the distance
#				dist_ij = abs(mean_i - mean_j)
#
#				if dist_ij < min_dist:
#					clusters[i].extend(clusters.pop(j))
#
#	# sort to match class label order
#	clusters.sort(key=lambda c: mean(c, 'bps') if len(c) > 0 else 0, reverse=True)

# mean of a list of dicts
def mean(l, key):
	return sum([s[key] for s in l]) / float(len(l))

def parse_sample(filename):
	import json

	with open(filename) as f:
		data = json.load(f)
		sample = {
			'hosts':(data['start']['connected'][0]['local_host'],
					data['start']['connected'][0]['remote_host']),
			'bps':data['end']['sum_received']['bits_per_second']
		}

	return sample

def get_fully_connected_hosts(samples):
	import networkx as nx

	edges = [s['hosts'] for s in samples]
	nodes = sum(zip(*edges), ()) # unpack list of (node,node) tuples into a tuple of nodes

	g = nx.Graph()
	g.add_nodes_from(nodes)
	g.add_edges_from(edges)

	# find maximal cliques in graphs
	cliques = list(nx.algorithms.clique.enumerate_all_cliques(g))
	max_clique = set(max(cliques, key=len) if len(cliques) > 0 else [])

	log.info("%d nodes and %d edges contain %d cliques, with the maximal: %s" % (len(nodes), len(edges), len(cliques), max_clique))
	return max_clique

def write_hostfile(output_dir, filename, hosts):
	import os
	with open(os.path.join(output_dir, filename), 'w') as f:
		for host in hosts:
			f.write(host+'\n')

def pprint(structure):
	import pprint
	pp = pprint.PrettyPrinter(indent=4)
	pp.pprint(structure)

def log_init(logfile=None, verbose=False):
	import logging as log
	import sys

	# defaults
	file_level = log.INFO
	stream_level = log.ERROR

	# overrides
	if __debug__:
		file_level = log.DEBUG
		stream_level = log.DEBUG
	elif verbose:
		stream_level = log.INFO

	# init
	handlers = []

	if logfile:
		handler = log.FileHandler(filename=logfile)
		handler.setLevel(file_level)
		formatter = log.Formatter('[%(levelname)s] %(asctime)s - %(message)s')
		handler.setFormatter(formatter)
		handlers.append(handler)

	# create console handler
	handler = log.StreamHandler(sys.stdout)
	handler.setLevel(stream_level)
	formatter = log.Formatter('%(message)s')
	handler.setFormatter(formatter)
	handlers.append(handler)

	log.basicConfig(
		level = log.DEBUG, # filter, lowest level DEBUG allows all
		handlers = handlers
	)

if __name__ == "__main__":
	try:
		main()
	except ValueError as e:
		log.error(str(e))


### OLD


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
def cluster_by_kmeans(items, K, key, max_iter=10):

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

def cluster_by_jenks(items, K, key, target_GVF, max_iter=10):
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
