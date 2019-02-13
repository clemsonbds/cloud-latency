#!/usr/bin/env python3

from functools import reduce
import math

# return a list of all factors of n
# going from 1 to sqrt(n), adding pairs, and reducing does this in O(2*sqrt(n)) rather than O(n)
# https://stackoverflow.com/a/6800214/3808882
def get_factors(n):
	return set(
		reduce(list.__add__, ([i, n//i]
		for i in range(1, int(math.sqrt(n)) + 1)
		if not n % i))
	)

def get_triplets(product):
	factors = get_factors(product)

	for x in factors:
		for y in factors:
			z, mod = divmod(product, x*y)

			if not mod and z in factors:
				yield (x, y, z)

# get three numbers that multiply together to equal 'product', with the least difference between them (close to cube)
def get_min_triplet(product):
	min_triplet = (product, 1, 1) # worst case

	for t in get_triplets(product):
		if sum(t) < sum(min_triplet):
			min_triplet = t

	return min_triplet

if __name__ == "__main__":
	import sys
	product = int(sys.argv[1])

	print(','.join(str(x) for x in get_min_triplet(product)))
