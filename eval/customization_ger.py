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
paths = glob.glob(base + "customization/*.json")
data = [json.load(open(path)) for path in paths]

runs = pd.DataFrame.from_records([{
  **algo,
  'num_threads': run['num_threads'],
  'graph': path_to_graph(run['args'][1]),
  'hostname': run['hostname']
} for run in data for algo in run['customizations']])

runs['total_basic_customization_running_time_ms'] = runs['basic_customization_running_time_ms'] + runs['respecting_running_time_ms']
runs['total'] = runs['total_basic_customization_running_time_ms'] + runs['perfect_customization_running_time_ms'] + runs['graph_build_running_time_ms']

cols = ['total_basic_customization_running_time_ms', 'perfect_customization_running_time_ms', 'graph_build_running_time_ms', 'total']
table = runs.groupby(['graph', 'num_threads'])[cols].mean().unstack(0).swaplevel(axis='columns').sort_index(axis='columns')['Germany'].reindex(cols, axis='columns')
table /= 1000
table.rename(inplace=True, columns={'total_basic_customization_running_time_ms': 'Basic', 'perfect_customization_running_time_ms': 'Perfect', 'graph_build_running_time_ms': 'Construct', 'total': 'Total'})

lines = table.round(2).to_latex().split("\n")

output = r'''\begin{tabular}{lrrrr}
\toprule
& \multicolumn{4}{c}{Germany [s]} \\ \cmidrule(lr){2-5}
Threads & Basic & Perfect & Construct &  Total \\
''' + "\n".join(lines[4:]) + "\n"

with open("paper/table/customization_ger.tex", 'w') as f:
  f.write(output)
