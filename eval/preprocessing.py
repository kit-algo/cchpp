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

runtime_pattern = re.compile(".*running time : (\\d+)musec.*")

def parse_flowcutter_partition_output(path):
  stats = { 'cch_ordering_running_time_s': 0.0 }

  with open(path, 'r') as f:
    for line in f:
      if not 'graph' in stats:
        stats['graph'] = path_to_graph(line.strip())
      else:
        match = runtime_pattern.match(line)
        if match:
          stats['cch_ordering_running_time_s'] += int(match[1]) / 1000000

  return stats

cch_ordering = pd.DataFrame.from_records([parse_flowcutter_partition_output(path) for path in glob.glob(base + "partitioning/*.out")])

paths = glob.glob(base + "turns/preprocessing/*.json")
data = [json.load(open(path)) for path in paths]
topo_prepros = pd.DataFrame.from_records([{
    **algo,
    'num_threads': run['num_threads'],
    'remove_always_infinity': run['remove_always_infinity'],
    'directed_hierarchies': run['directed_hierarchies'],
    'perfect_customization': run['perfect_customization'],
    'graph': path_to_graph(run['args'][1]),
    'expanded': '_exp'  in run['args'][1],
    'order': run['args'][2],
    'hostname': run['hostname']
    }
    for run in data for algo in run['preprocessings']])

topo_prepros['variant'] = 'no turns'
topo_prepros.loc[topo_prepros['expanded'], 'variant'] = 'naive expanded'
topo_prepros.loc[topo_prepros['order'] == "cch_perm_cuts", 'variant'] = 'cut order'
topo_prepros.loc[topo_prepros['remove_always_infinity'], 'variant'] = 'remove inf'
topo_prepros.loc[topo_prepros['directed_hierarchies'], 'variant'] = 'directed'
topo_prepros.loc[topo_prepros['order'] == "cch_perm_cuts_reorder", 'variant'] = 'sep reorder'
topo_prepros_table = topo_prepros.query('hostname == "compute11" & variant == "no turns"').groupby('graph')['total_preprocessing_ms'].mean()

contraction = runs.groupby('graph')['contraction_running_time_ms'].mean() / 1000
ordering = cch_ordering.groupby('graph')['cch_ordering_running_time_s'].mean()
table = pd.merge(ordering, contraction, left_index=True, right_index=True)
table.at['Europe', 'cont_graph'] = 15.5
table.at['Europe', 'adj_array_s'] = 305.8
table['total_phase1_s'] = table['cch_ordering_running_time_s'] + (topo_prepros_table / 1000)

table = table.reindex(['Stuttgart', 'Germany', 'Europe'])

lines = table.round(1).to_latex(na_rep='--').split("\n")

lines = lines[0:2] + [r'''{} &  Ordering & \multicolumn{3}{c}{Contraction} & Total \\ \cmidrule(lr){3-5}
{} &  {} &  Chordal &  Contraction & Dyn. adjacency & \\
{} &  {} &  completion & graph \cite{DibbeltSW16} & array \cite{DibbeltSW16} & \\'''] + lines[4:]

output = "\n".join(lines) + "\n"

with open("paper/table/preprocessing.tex", 'w') as f:
  f.write(output)
