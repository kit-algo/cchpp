#!/usr/bin/env python3

import numpy as np
import matplotlib as mpl
from matplotlib import pyplot as plt
import seaborn as sns
sns.set()

import pandas as pd

import json
import glob
import os
import re

from shared import *

base = "exp/"
paths = glob.glob(base + "knn/num_pois/*.json")
data = [json.load(open(path)) for path in paths]

queries = pd.DataFrame.from_records([{
    'graph': path_to_graph(run['args'][1]),
    'experiment': exp['experiment'],
    'target_set_size_exp': exp['target_set_size_exp'],
    'num_targets_to_find': exp['num_targets_to_find'],
    'ball_size_exp': exp['ball_size_exp'],
    **algo }
    for run in data for exp in run['experiments'] for algo in exp['algo_runs']])

queries['family'] = queries['algo'].map({
    'sep_based_cch_nearest_neighbor_selection': 'CCH',
    'sep_based_cch_nearest_neighbor_query': 'CCH',
    'lazy_rphast_nearest_neighbor': 'Lazy RPHAST',
    'bcch_nearest_neighbor_selection': 'BCCH',
    'bcch_nearest_neighbor_query': 'BCCH',
    'dijkstra_nearest_neighbor_selection': 'Dijkstra',
    'dijkstra_nearest_neighbor_query': 'Dijkstra',
})
queries['phase'] = queries['algo'].map({
    'sep_based_cch_nearest_neighbor_selection': 'select',
    'sep_based_cch_nearest_neighbor_query': 'query',
    'lazy_rphast_nearest_neighbor': 'query',
    'bcch_nearest_neighbor_selection': 'select',
    'bcch_nearest_neighbor_query': 'query',
    'dijkstra_nearest_neighbor_selection': 'select',
    'dijkstra_nearest_neighbor_query': 'query',
})

fig = plt.figure(figsize=(11,6))
plot = sns.lineplot(data=queries.query('num_targets_to_find == 4 & graph == "Europe"'), x='target_set_size_exp', y='running_time_ms', hue='family', style='phase', dashes={'select': '', 'query': ''}, markers={'select': 'o', 'query': 'X'}, ci=None, legend=None)
plot.set_yscale('log')
plot.set_xlabel('Number of POIs')
plot.set_ylabel('Running Time [ms]')
plot.yaxis.set_major_locator(mpl.ticker.LogLocator(base=10,numticks=10))
plot.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda val, pos: f"{val if val < 1.0 else int(val)}"))
plot.xaxis.set_major_locator(mpl.ticker.IndexLocator(base=1, offset=0))
plot.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda val, pos: f"$2^{{{int(val)}}}$"))
permutation = [6,5,4,3,1,0,2]
plot.legend([plot.lines[idx] for idx in permutation],
            [['CCH select', 'CCH query', 'Lazy RPHAST', 'BCCH select', 'BCCH query', 'Dijkstra select', 'Dijkstra query'][idx] for idx in permutation],
            title=None, ncol=4)

fig.tight_layout()
fig.savefig('paper/fig/knn.pdf')
