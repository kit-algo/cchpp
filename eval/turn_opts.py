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

runtime_pattern = re.compile(".*running time : (\\d+)musec.*")

def parse_flowcutter_partition_output(path):
    stats = { 'cch_ordering_running_time_s': 0.0 }

    with open(path, 'r') as f:
        for line in f:
            if not 'graph' in stats:
                parts = line.split(' ')
                stats['graph'] = path_to_graph(parts[0])
                stats['expanded'] = '_exp' in parts[0]
                if len(parts) == 2:
                    stats['hostname'] = parts[1].strip()
                    stats['cut_order'] = False
                else:
                    stats['hostname'] = parts[2].strip()
                    stats['cut_order'] = True
            else:
                match = runtime_pattern.match(line)
                if match:
                    stats['cch_ordering_running_time_s'] += int(match[1]) / 1000000

    return stats

cch_ordering = pd.DataFrame.from_records([parse_flowcutter_partition_output(path) for path in glob.glob(base + "turns/partitioning/*.out")])

ord_expander = pd.DataFrame.from_records([{ 'expanded': False, 'cut_order': False, 'variant': 'no turns', },
    { 'expanded': True,  'cut_order': False, 'variant': 'naive expanded', },
    { 'expanded': True,  'cut_order': True, 'variant': 'cut order', },
    { 'expanded': True,  'cut_order': True, 'variant': 'remove inf', },
    { 'expanded': True,  'cut_order': True, 'variant': 'directed', },
    { 'expanded': True,  'cut_order': True, 'variant': 'sep reorder', },
    { 'expanded': False, 'cut_order': False, 'variant': 'cch pot', },])

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

paths = glob.glob(base + "turns/customization/*.json")
data = [json.load(open(path)) for path in paths]

customs = queries = pd.DataFrame.from_records([{
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
    for run in data for algo in run['customizations']])

customs['variant'] = 'no turns'
customs.loc[customs['expanded'], 'variant'] = 'naive expanded'
customs.loc[customs['order'] == "cch_perm_cuts", 'variant'] = 'cut order'
customs.loc[customs['remove_always_infinity'], 'variant'] = 'remove inf'
customs.loc[customs['directed_hierarchies'], 'variant'] = 'directed'
customs.loc[customs['order'] == "cch_perm_cuts_reorder", 'variant'] = 'sep reorder'

customs['total_perfect_customization_running_time_ms'] = customs['perfect_customization_running_time_ms'] + customs['graph_build_running_time_ms']
customs['total_basic_customization_running_time_ms'] = customs['respecting_running_time_ms'] + customs['basic_customization_running_time_ms']

customs['combined_cch_edge_count'] = customs['num_cch_edges'] * 2
customs.loc[customs['num_cch_fw_edges'].notna(), 'combined_cch_edge_count'] = (customs['num_cch_fw_edges'] + customs['num_cch_bw_edges'])


paths = glob.glob(base + "turns/queries/*.json")
queries = pd.DataFrame.from_records([{
    **algo,
    'remove_always_infinity': run.get('remove_always_infinity'),
    'directed_hierarchies': run.get('directed_hierarchies'),
    'perfect_customization': run.get('perfect_customization'),
    'graph': path_to_graph(run['args'][1]),
    'expanded': '_exp'  in run['args'][1],
    'order': run['args'][2],
    'hostname': run['hostname'],
} for path in paths for run in [json.load(open(path))] for algo in run.get('queries', run.get('algo_runs'))])

queries['remove_always_infinity'] = queries['remove_always_infinity'].fillna(False)
queries['directed_hierarchies'] = queries['directed_hierarchies'].fillna(False)
queries['variant'] = 'no turns'
queries.loc[queries['expanded'], 'variant'] = 'naive expanded'
queries.loc[queries['order'] == "cch_perm_cuts", 'variant'] = 'cut order'
queries.loc[queries['remove_always_infinity'], 'variant'] = 'remove inf'
queries.loc[queries['directed_hierarchies'], 'variant'] = 'directed'
queries.loc[queries['order'] == "cch_perm_cuts_reorder", 'variant'] = 'sep reorder'
queries.loc[queries['algo'] == 'Virtual Topocore Bidirectional Core Query', 'variant'] = 'cch pot'
queries.loc[queries['algo'] == 'Virtual Topocore Bidirectional Core Query', 'perfect_customization'] = True

ordering = pd.merge(cch_ordering.query('hostname == "compute11"'), ord_expander, on=['expanded', 'cut_order']).groupby(['graph', 'variant'])['cch_ordering_running_time_s'].mean()
cust = customs.query('hostname == "compute11" & num_threads == 16').groupby(['graph', 'variant'])[['combined_cch_edge_count', 'total_basic_customization_running_time_ms', 'total_perfect_customization_running_time_ms']].mean()
cust = pd.concat([cust.reindex(['no turns'], level=1).rename(index={'no turns': 'cch pot'}), cust]).sort_index()
quer = queries.query('hostname == "compute11"').groupby(['graph', 'variant', 'perfect_customization'])['running_time_ms'].mean().unstack() * 1000
table = pd.merge(ordering, pd.merge(cust, quer, how='right', left_index=True, right_index=True), left_index=True, right_index=True)

topo_prepros_table = topo_prepros.query('hostname == "compute11"').groupby(['graph', 'variant'])['total_preprocessing_ms'].mean()
topo_prepros_table = pd.concat([topo_prepros_table.reindex(['no turns'], level=1).rename(index={'no turns': 'cch pot'}), topo_prepros_table]).sort_index()

table['total_phase1_s'] = table['cch_ordering_running_time_s'] + (topo_prepros_table / 1000)
table['combined_cch_edge_count'] /= 1000
table = table[['combined_cch_edge_count', 'total_phase1_s', 'total_basic_customization_running_time_ms', 'total_perfect_customization_running_time_ms', False, True]] \
    .loc[['Stuttgart', 'Germany', 'Europe']] \
    .reindex(['no turns', 'cch pot', 'naive expanded', 'cut order', 'remove inf', 'directed', 'sep reorder'], level=1) \
    .rename(index={ 'no turns': 'No turns', 'naive expanded': 'Naive exp.', 'cut order': 'Cut order', 'remove inf': 'Infinity', 'directed': 'Directed', 'sep reorder': 'Reorder', 'cch pot': 'CCH-Pot.' })

lines = add_latex_big_number_spaces(table.to_latex(na_rep='--')).split('\n')

lines = lines[:2] + [
r' &         &     CCH Edges & Prepro. & \multicolumn{2}{c}{Customization [ms]} & \multicolumn{2}{c}{Query [$\mu$s]} \\ \cmidrule(lr){5-6} \cmidrule(lr){7-8}',
r' &         & [$\cdot 10^3$] &   [s] & Basic & Perfect &  Basic & Perfect \\',
] + lines[4:]
output = '\n'.join(lines) + '\n'
output = output.replace('nan', '--')
output = output.replace('Stuttgart', r'\multirow{7}{*}{\rotatebox[origin=c]{90}{Stuttgart}}')
output = output.replace('Germany', r'\addlinespace \multirow{7}{*}{\rotatebox[origin=c]{90}{Germany}}')
output = output.replace('Europe', r'\addlinespace \multirow{7}{*}{\rotatebox[origin=c]{90}{Europe}}')

with open("paper/table/turn_opts.tex", 'w') as f:
  f.write(output)
