#!/usr/bin/env python3

import numpy as np
import matplotlib as mpl
from matplotlib import pyplot as plt
import seaborn as sns
sns.set()

import pandas as pd
pd.options.display.float_format = '{:.1f}'.format

import json
import glob
import os
import re

base = "exp/"
paths = glob.glob(base + "knn/repr/num_pois/*.json")
data = [json.load(open(path)) for path in paths]

queries = pd.DataFrame.from_records([{
    'graph': run['args'][1],
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

valentin_base = "/algoDaten/zeitz/projects/valentin_base_dir/Experiments/NearestNeighbors/"

times = []

data = pd.read_csv(valentin_base + f"SEA21/POIs/VaryingPOISetSize_CCH.index.csv")
data['phase'] = 'select'
data['family'] = 'CCH [orig]'
data['algo'] = 'cch_orig_select'
times.append(data)
data = pd.read_csv(valentin_base + f"SEA21/POIs/VaryingPOISetSize_CCH.query.csv")
data['phase'] = 'query'
data['family'] = 'CCH [orig]'
data['algo'] = 'cch_orig_query'
times.append(data)

times = pd.concat(times, ignore_index=True)
times['running_time_ms'] = times['time'] / 1000000
times['num_targets_to_find'] = times['max_pois'].fillna(4.0).astype(int)
times['ball_size_exp'] = np.log2(times['ball_size']).astype(int)
times['target_set_size_exp'] = np.log2(times['num_pois']).astype(int)

combined = pd.concat([queries, times], ignore_index=True)

fig = plt.figure(figsize=(11,6))
plot = sns.lineplot(data=combined.query('num_targets_to_find == 4 & target_set_size_exp >= 2'), x='target_set_size_exp', y='running_time_ms', hue='family', style='phase', dashes={'select': '', 'query': ''}, markers={'select': 'o', 'query': 'X'}, ci=None)
plot.set_yscale('log')
plot.set_xlabel('Number of POIs')
plot.set_ylabel('Running Time [ms]')
plot.yaxis.set_major_locator(mpl.ticker.LogLocator(base=10,numticks=10))
plot.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda val, pos: f"{val if val < 1.0 else int(val)}"))
plot.xaxis.set_major_locator(mpl.ticker.IndexLocator(base=1, offset=0))
plot.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda val, pos: f"$2^{{{int(val)}}}$"))
permutation = [6,5,4,3,1,0,7,8,2]
plot.legend([plot.lines[idx] for idx in permutation],
            [['CCH select', 'CCH query', 'Lazy RPHAST', 'BCCH select', 'BCCH query', 'Dijkstra select', 'Dijkstra query', 'CCH [orig] select', 'CCH [orig] query'][idx] for idx in permutation],
            title=None, ncol=5, loc='upper left')
fig.tight_layout()
fig.savefig('paper/fig/repr_knn_num_pois.pdf')
