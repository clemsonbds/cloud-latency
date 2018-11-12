#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""converts the output of ib_{read,write,send,atomic}_lat from ugly parse format to a csv format"""

import argparse
import csv
import re

def parse_args():
    """parse arguements"""
    parser = argparse.ArgumentParser()
    parser.add_argument("-q", "--quiet", action="store_true", help="do not print the header")
    parser.add_argument("infile", type=argparse.FileType(), help="input file")
    parser.add_argument("-o", "--outfile", type=argparse.FileType('w'), default="-", help="output file")
    return parser.parse_args()

def parse_output(infile):
    """takes an input file and yields a list of tuples"""
    #matches lines of the form:
    #2, 1.90734
#    latency_line = re.compile(r'(?P<id>\d+),\s+(?P<usec>\d+\.?\d*)\s*$')

    #matches lines of the form:
    # Time in seconds =                    40.21
    # 2       16000          1.91           13.79        1.95
    summary_line = re.compile(r'\s*Time in seconds =\s+(?P<time>\d+\.?\d*)\s*$')
#    summary_line = re.compile(r'\s*(?P<bytes>\d+)\s+(?P<iterations>\d+)\s+'
#                              r'(?P<t_min>\d+\.\d+)\s+(?P<t_max>\d+\.\d+)\s+'
#                              r'(?P<t_typical>\d+\.\d+)\s*$')

    trials = []
    trial_number = 0
    for line in infile:
        s_match = summary_line.match(line)

        if s_match:
            tm = s_match.group("time")
            trials.append(tm)

    for trial, tm in enumerate(trials):
        yield {
            "trial": trial,
            "time": tm,
            "iterations": len(trials),
        }

def output_results(results, outfile, quiet):
    """output results to a csv file"""
    fieldnames = ["trial", "time", "iterations"]
    writer = csv.DictWriter(outfile, fieldnames)
    if not quiet:
        writer.writeheader()
    writer.writerows(results)

def main():
    """main method"""
    args = parse_args()
    results = parse_output(args.infile)
    output_results(results, args.outfile, args.quiet)

if __name__ == "__main__":
    main()
