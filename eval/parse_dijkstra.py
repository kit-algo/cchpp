#!/usr/bin/env python3.8

import pandas as pd

import re
import sys

runtime_pattern = re.compile("^(\\d+) micro seconds")
queue_pops_pattern = re.compile("^pops: (\\d+)")
query_runs = []
pops = []

with open(sys.argv[1], "r") as f:
  for line in f:
    line = line.strip()
    if (match := runtime_pattern.search(line)) is not None:
      query_runs.append(int(match[1]) / 1000.0)
    if (match := queue_pops_pattern.search(line)) is not None:
      pops.append(int(match[1]))

print("ms")
print(pd.Series(query_runs).describe())
print(pd.Series(pops).describe())
