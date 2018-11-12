#!/usr/bin/env python3

import glob
import parse_npb
import numpy
import csv

def load_raw_dir():
  d = {}

  for filename in glob.glob('*.raw'):
    # split filenames of form: lognorm.50.ft.C.64.raw
    dist, cong, test, _ = filename.split('.', 3)
    cong = int(cong)

    with open(filename) as f:
      times = [float(p['time']) for p in parse_npb.parse_output(f)]

    if cong not in d.keys():
      d[cong] = {}

    d[cong][test] = times

  return dist, d

def compute_stats(results):
  # find all the test types, some congestion lines may be incomplete
  tests = set()

  for cong in results:
    for test in results[cong]:
      tests.add(test)

  tests = sorted([t for t in tests])

  return { test: [ {
    'congestion': cong,
    'n':    len(results[cong][test]) if test in results[cong] else 0,
    'mean': numpy.mean(results[cong][test]) if test in results[cong] and len(results[cong][test]) > 0 else 0.0,
    'median': results[cong][test][int(len(results[cong][test])/2)] if test in results[cong] and len(results[cong][test]) > 0 else 0.0,
    'std':  numpy.std(results[cong][test]) if test in results[cong] and len(results[cong][test]) > 0 else 0.0,
    'min':  min(results[cong][test]) if test in results[cong] and len(results[cong][test]) > 0 else 0.0,
    'max':  max(results[cong][test]) if test in results[cong] and len(results[cong][test]) > 0 else 0.0,
  } for cong in sorted(results) ] for test in tests}

def output_results(results, outfile):
  """output results to a csv file"""
  fieldnames = ["congestion", 'n', 'mean', 'median', 'std', 'min', 'max']
  writer = csv.DictWriter(outfile, fieldnames)
  writer.writeheader()
  writer.writerows(results)

if __name__ == '__main__':
  dist, results = load_raw_dir()
  st = compute_stats(results)
  for test in st:
    with open('npb.'+test+'.csv', 'w') as f:
      output_results(st[test], f)
