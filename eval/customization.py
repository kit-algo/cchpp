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
paths = glob.glob(base + "preprocessing/*.json")
data = [json.load(open(path)) for path in paths]

runs = pd.DataFrame.from_records([{
    **run,
    'graph': path_to_graph(run['args'][1])
} for run in data])

runs['total_basic_customization_running_time_ms'] = runs['basic_customization_running_time_ms'] + runs['respecting_running_time_ms']
runs['total'] = runs['total_basic_customization_running_time_ms'] + runs['perfect_customization_running_time_ms'] + runs['graph_build_running_time_ms']

cols = ['total_basic_customization_running_time_ms', 'perfect_customization_running_time_ms', 'graph_build_running_time_ms', 'total']
table = runs.groupby(['graph', 'num_threads'])[cols].mean().unstack(0).swaplevel(axis='columns').sort_index(axis='columns')[['Stuttgart', 'Europe']].reindex(cols, level=1, axis='columns')
table['Europe'] /= 1000
table.rename(inplace=True, columns={'total_basic_customization_running_time_ms': 'Basic', 'perfect_customization_running_time_ms': 'Perfect', 'graph_build_running_time_ms': 'Construct', 'total': 'Total'})

lines = table.round(2).to_latex().split("\n")

output = r'''\begin{tabular}{llrrrrrrrr}
\toprule
& & \multicolumn{4}{c}{Stuttgart [ms]} & \multicolumn{4}{c}{Europe [s]} \\ \cmidrule(lr){3-6} \cmidrule(lr){7-10}
Impl & Threads &     Basic & Perfect & Construct &  Total &  Basic & Perfect & Construct &  Total \\
\midrule
\cite{DibbeltSW16}
& 1           &           &         &           &        &  10.88 &   22.02 & $\approx$ 9.39 & $\approx$ 42.35 \\
& 16          &           &         &           &        & \multicolumn{2}{c}{5.47} & $\approx$ 9.39 & $\approx$ 14.86 \\
\addlinespace
\cite{BuchholdSW19}
& 1           &     20.51 &   20.77 &     48.64 &  89.93 &   5.60 &    6.48 &      9.39 &  21.47 \\
& 16          &      4.91 &    4.41 &      4.35 &  13.66 &   1.11 &    0.63 &      0.80 &   2.54 \\
\addlinespace
{[ours]}
''' + "\n".join(['& ' + l for l in lines[6:11]] + lines[11:]) + "\n"

with open("paper/table/customization.tex", 'w') as f:
  f.write(output)
