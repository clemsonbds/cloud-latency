#!/usr/bin/env python

import sys
import os
import argparse
import json
import glob

import networkx as nx

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

def cluster_by_closest(items, class_seeds, key):
	clusters = [[]]*len(class_seeds)

	for s in items:
		differences = [abs(seed - s[key]) for seed in class_seeds]
		min_index = min(xrange(len(class_seeds)), key=differences.__getitem__) # https://stackoverflow.com/a/11825864/3808882
		clusters[min_index].append(s)

	return clusters

# return list of lists of sample dicts
def cluster_by_stupid(items, K, key):
	if K>2:
		sys.exit("no stupid, no time")

	mx = max(items, key=lambda c: c[key])[key]
	mn = min(items, key=lambda c: c[key])[key]
	threshold = ((mx - mn)/2) + mn
	return [[x for x in items if x[key] < threshold], [x for x in items if x[key] >= threshold]]

# return generator for dicts like { 'pair': (local_host, remote_host), 'bps': bps }
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
	parser.add_argument('--sample_files', required=True, nargs='+', help='JSON result files from iperf')
	parser.add_argument('--output_dir', help='in addition to stdout, write hostfiles named <class>.hosts')
	parser.add_argument('--descending', default=False, action='store_true', help='use if the first class name should match largest cluster median value')

	group = parser.add_mutually_exclusive_group(required=False)
	group.add_argument('--verbose', action='store_true', help='clusters and values will be described, rather than minimal CSV')
	group.add_argument('--quiet', action='store_true', help='suppress stdout')

	group = parser.add_mutually_exclusive_group(required=True)
	group.add_argument('--K', type=int, help='the number of clusters to divide samples into')
	group.add_argument('--class_labels', type=str, nargs='+', help='two or more class labels, determines the number of clusters K')

	group = parser.add_mutually_exclusive_group(required=False)
	group.add_argument('--min_distance', type=float, help='recombine clusters whose means are within a factor of X of eachother,\n   i.e. 10 and 9 are within factor of 0.1 of eachother')
	group.add_argument('--class_means', type=float, nargs='+', help='list of mean values, must match K or length of class_labels')

	args = parser.parse_args()

	# sanity checking on input
	if args.class_labels:
		class_labels = args.class_labels
		K = len(class_labels)
	else:
		K = args.K
		class_labels = ['class%d'%(i+1) for i in range(K)]

	if len(args.sample_files) < K:
		print("Warning: ", args.sample_files, " samples provided, reducing K to match.")
		K = len(args.sample_files)

	if args.class_means and len(args.class_means) != K:
		sys.exit("Error: %d class labels provided for %d clusters." % (len(args.class_means), K))

	# parse the samples for host pairs and receive rate
	samples = list(parse_samples(args.sample_files))

	if not args.quiet:
		print("Parsed %d samples from %d files." % (len(samples), len(args.sample_files)))

#	clusters = cluster_by_kmeans(samples, K, 'bps')
#	clusters = cluster_by_jenks(samples, K, 'bps', 1)

	if args.class_means:
		clusters = cluster_by_closest(samples, args.class_means, 'bps')
	else:
		clusters = cluster_by_stupid(samples, K, 'bps')

	# recombine clusters that are too close to eachother
	if args.min_distance:
		# start i at the second to last cluster of the list, move from right to left
		for i in reversed(range(len(clusters)-1)):

			# try to combine with each of the clusters to the right, in right-left order
			for j in reversed(range(i+1, len(clusters))):
				mean_i = mean(clusters[i], 'bps') # recompute this every time, since it can change with each combining of i and j
				mean_j = mean(clusters[j], 'bps')
				min_dist = max(mean_i, mean_j) * args.min_distance # always use the maximum mean for the distance
				dist_ij = abs(mean_i - mean_j)

				if dist_ij < min_dist:
					clusters[i].extend(clusters.pop(j))

	# sort to match class label order
	clusters.sort(key=lambda c: mean(c, 'bps'), reverse=args.descending)

	# group classes with their names
	classes = dict((name, {'cluster':cluster}) for name, cluster in [(class_labels[i], clusters[i]) for i in range(len(clusters))])

	# build graphs
	for c in classes.values():
		edges = [s['pair'] for s in c['cluster']]
		nodes = [host for t in edges for host in t] # unpack

		g = nx.Graph()
		g.add_nodes_from(nodes)
		g.add_edges_from(edges)
		c['graph'] = g

		# find maximal cliques in graphs
		c['all_cliques'] = nx.algorithms.clique.enumerate_all_cliques(g)
		c['max_clique'] = max(c['all_cliques'], key=len)

	# write output
	if args.verbose:
		pp.pprint(classes)

	elif not args.quiet:
		for c in classes.values():
			print(','.join(c['max_clique']))

	if args.output_dir:
		for class_name in classes:
			fn = '.'.join([class_name, "hosts"])

			with open(os.path.join(args.output_dir, fn), 'w') as f:
				for host in classes[class_name]['max_clique']:
					f.write(host+'\n')

if __name__ == "__main__":
	main()
