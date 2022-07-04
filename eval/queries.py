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

base = "exp/"
paths = glob.glob(base + "queries/*.json")
queries = pd.DataFrame.from_records([{
    **algo,
    'perfect_customization': run['perfect_customization'],
    'graph': path_to_graph(run['args'][1]),
    'hostname': run['hostname'],
    'weights': run['weight_file'],
} for path in paths for run in [json.load(open(path))] for algo in run['queries']])

table = queries.loc[lambda x: x['hostname'] == 'compute11'].groupby(['graph', 'weights', 'perfect_customization'])[['num_nodes_in_searchspace', 'num_relaxed_edges', 'running_time_ms', 'unpacking', 'num_nodes_on_path']].mean().unstack()

table['running_time_ms'] *= 1000
table['unpacking'] *= 1000

table = table.reindex(['travel_time', 'live_travel_time', 'geo_distance'], level=1)
table = table.reindex(['Stuttgart', 'Germany', 'Europe'], level=0)
table = table.rename(index={ 'travel_time': 'Travel time', 'live_travel_time': 'Heavy traffic', 'geo_distance': 'Geo distance'})

table = table.drop(('num_nodes_in_searchspace', False), axis='columns')
table = table.drop(('num_nodes_on_path', False), axis='columns')

lines = table.round(1).to_latex().split("\n")

lines = lines[:2] + [
R'& {}      & \multicolumn{3}{c}{Search space}     & \multicolumn{4}{c}{Running time [$\mu$s]}               & \# Path    \\ \cmidrule(lr){3-5} \cmidrule(lr){6-9}',
R'& {} & \multirow{2}{*}{Vertices} & \multicolumn{2}{c}{Edges} & \multicolumn{2}{c}{Distance} & \multicolumn{2}{c}{Path} & Vertices \\ \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}',
R'\multicolumn{2}{r}{Perfect Customization} & &                  \xmark &      \cmark &           \xmark &   \cmark &     \xmark &   \cmark &         \\',
] + lines[5:8] + ['\\addlinespace'] + lines[8:11] + ['\\addlinespace'] + lines[11:]

output = add_latex_big_number_spaces("\n".join(lines) + "\n")

with open("paper/table/queries.tex", 'w') as f:
  f.write(output)
