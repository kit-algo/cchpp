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

from shared import *

base = "exp/"
paths = glob.glob(base + "knn/repr/num_pois/*.json")
data = [json.load(open(path)) for path in paths]
queries1 = pd.DataFrame.from_records([{
    'graph': run['args'][1],
    'experiment': exp['experiment'],
    'target_set_size_exp': exp['target_set_size_exp'],
    'num_targets_to_find': exp['num_targets_to_find'],
    'ball_size_exp': 25,
    **algo }
    for run in data for exp in run['experiments'] for algo in exp['algo_runs']])

paths = glob.glob(base + "knn/repr/ball_size/*.json")
data = [json.load(open(path)) for path in paths]
queries2 = pd.DataFrame.from_records([{
    'graph': run['args'][1],
    'experiment': exp['experiment'],
    'target_set_size_exp': exp['target_set_size_exp'],
    'num_targets_to_find': exp['num_targets_to_find'],
    'ball_size_exp': exp['ball_size_exp'],
    'sources_in_ball': exp['sources_in_ball'],
    **algo }
    for run in data for exp in run['experiments'] for algo in exp['algo_runs']])

queries = pd.concat([queries1, queries2], ignore_index=True)

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

for (p, b) in [(12, 20), (14, 25)]:
    for algo in ['CCH']:
        data = pd.read_csv(valentin_base + f"SEA21/POIs/b{b}_p{p}_{algo}.index.csv")
        data['algo'] = 'cch_orig_select'
        data['phase'] = 'select'
        data['family'] = 'CCH [orig]'
        data['target_set_size_exp'] = p
        data['ball_size_exp'] = b
        times.append(data)
        data = pd.read_csv(valentin_base + f"SEA21/POIs/b{b}_p{p}_{algo}.query.csv")
        data['algo'] = 'cch_orig_query'
        data['phase'] = 'query'
        data['family'] = 'CCH [orig]'
        data['target_set_size_exp'] = p
        data['ball_size_exp'] = b
        times.append(data)
        
times = pd.concat(times, ignore_index=True)
times['space'] = times['space'] / (2**20)
times['running_time_ms'] = times['time'] / 1000000
times['num_targets_to_find'] = times['max_pois'].astype(int, errors='ignore')

combined = pd.concat([queries, times], ignore_index=True)
subset = combined.query('(target_set_size_exp == 12 & ball_size_exp == 20) | (target_set_size_exp == 14 & ball_size_exp == 25)')

selection_table = subset.query('phase == "select"').groupby(['family', 'target_set_size_exp']).mean()[['space', 'running_time_ms']]
query_table = subset.query('phase == "query"').groupby(['family', 'target_set_size_exp', 'num_targets_to_find']).mean()['running_time_ms'].unstack() * 1000
table = pd.merge(selection_table, query_table, left_index=True, right_index=True, how='right').unstack(1).swaplevel(axis='columns').sort_index(axis='columns')
table.at['BCCH', (12, 'space')] = 85.5
table.at['BCCH', (14, 'space')] = 134.9
table.at['CCH', (12, 'space')] = 0
table.at['CCH', (14, 'space')] = 0
table.at['Dijkstra', (12, 'space')] = 2.1
table.at['Dijkstra', (14, 'space')] = 2.1
table = table.fillna(0.0)
table.at['CRP', (14, 'space')] = 0.0
table.at['CRP', (14, 'running_time_ms')] = 8
table.at['CRP', (14, 4.0)] = 640
table = table.reindex(['Dijkstra', 'CRP', 'CCH [orig]', 'CCH', 'Lazy RPHAST', 'BCCH'])

lines = table.to_latex(na_rep='--').split('\n')

lines = lines[:2] + [r'''& \multicolumn{5}{c}{$|P| = 2^{12}, |B| = 2^{20}$} & \multicolumn{5}{c}{$|P| = 2^{14}, |B| = |V|$} \\ \cmidrule(lr){2-6}\cmidrule(l){7-11}
& \multicolumn{2}{c}{selection} & \multicolumn{3}{c}{query time [$\mu$s]} & \multicolumn{2}{c}{Selection} & \multicolumn{3}{c}{Query time [$\mu$s]} \\ \cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-8}\cmidrule(l){9-11}
& Space & Time & \multicolumn{3}{c}{POIs to be reported} & Space & Time & \multicolumn{3}{c}{POIs to be reported} \\
& [MiB] & [ms] & {$k = 1$} & {$k = 4$} & {$k = 8$} & [MiB] & {[ms]} & {$k = 1$} & {$k = 4$} & {$k = 8$} \\'''] + lines[5:]

output = add_latex_big_number_spaces("\n".join(lines) + "\n")

with open("paper/table/repr_knn_overview.tex", 'w') as f:
  f.write(output)
