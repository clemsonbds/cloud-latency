#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""converts a list of measurements to a csv format"""

import argparse
import csv

def parse_args():
    """parse arguements"""
    parser = argparse.ArgumentParser()
    parser.add_argument("-q", "--quiet", action="store_true", help="do not print the header")
    parser.add_argument("-s", "--skip", type=int, default=0,
                        help="skip this many entries in the raw file")
    parser.add_argument("infile", type=argparse.FileType(), help="input file")
    parser.add_argument("-o", "--outfile", type=argparse.FileType('w'), default="-", help="output file")
    return parser.parse_args()

def parse_output(infile, skip_count):
    """takes an input file and yields a list of tuples"""

    trial_number = 0
    skipped = 0
    jitter = 0.0

    for line in infile:
        if skipped < skip_count:
            skipped += 1
            continue

        if len(line.strip()) == 0:
            continue

        parts = line.split(",", 1)
        timestamp = float(parts[0].strip())
        latency = float(parts[1].strip())
        jitter = (abs(latency - jitter) / 16.0)

        yield {
            "trial": trial_number,
            "ts": timestamp,
            "latency": latency,
            "jitter": jitter,
        }

        trial_number += 1

def output_results(results, outfile, quiet):
    """output results to a csv file"""
    fieldnames = ["trial", "ts", "latency", "jitter"]
    writer = csv.DictWriter(outfile, fieldnames)
    if not quiet:
        writer.writeheader()
    writer.writerows(results)

def main():
    """main method"""
    args = parse_args()
    results = parse_output(args.infile, args.skip)
    output_results(results, args.outfile, args.quiet)

if __name__ == "__main__":
    main()
