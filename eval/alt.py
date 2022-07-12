#!/usr/bin/env python3

import numpy as np
import matplotlib as mpl
from matplotlib import pyplot as plt

import pandas as pd

import json
import glob
import os
import re

from shared import *
from functools import reduce

base = "exp/"
paths = glob.glob(base + "alternatives/*.json")

queries = pd.DataFrame.from_records([{
    **algo,
    'graph': path_to_graph(run['args'][1]),
    'hostname': run['hostname'],
} for path in paths for run in [json.load(open(path))] for algo in run['algo_runs'] if 'algo' in algo])

alternatives = pd.DataFrame.from_records([{
    **algo,
    **alt,
    'alt_idx': idx + 1,
    'graph': path_to_graph(run['args'][1]),
    'hostname': run['hostname'],
} for path in paths for run in [json.load(open(path))] for algo in run['algo_runs'] if 'algo' in algo for idx, alt in enumerate(algo.get('alternatives', []))])

query_counts = queries.groupby('graph')['base_dist'].count()
alt_stats = alternatives.groupby(['graph', 'alt_idx']).agg(success=('running_time_ms', 'count'), running_time_ms=('running_time_ms', 'mean'), iteration=('iteration', 'mean'), sharing_percent=('sharing_percent', 'mean'))
alt_stats['success'] /= query_counts
alt_stats['success'] *= 100
lines = add_latex_big_number_spaces(alt_stats.loc[['Stuttgart', 'Germany', 'Europe']].reindex([1,2,3,4], level=1).round(1).to_latex()).split('\n')

lines = lines[:2] + [
r' & \# Alt. & Success   & Running   & \# Iterations & Sharing \\',
r' &         & rate [\%] & time [ms] &               &    [\%] \\',
] + lines[4:]
output = '\n'.join(lines) + '\n'
output = output.replace('Germany', r'\addlinespace Germany')
output = output.replace('Europe', r'\addlinespace Europe')

with open("paper/table/alt_stats.tex", 'w') as f:
  f.write(output)

