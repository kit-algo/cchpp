#!/usr/bin/env python3.8

# Inputs
# - Eur + restrictions
# - Stuttgart + costs
# - London + costs
# - Chicago + forbidden U-turns

# Measure
# - Query running time
# - Customization running time
# - Order running time
# - Num Triangles
# - Num Triangles/Level
# - Num Shortcuts

# Ordnungen
# - InertialFlow
# - InertialFlowCutter
#   - auf original Graph ohne turns
#   - Naiv Ordnung expandieren
#   - auf expandiertem Graph
#   - Cut based

# Optimierungen
# - Undirected Always Infinity
# - Links Rechts umsortieren
# - Directed
#
# Maschine
# 3/5/11

import numpy as np
import pandas as pd

import re
import sys
import os

def parse_ifc(file):
  runtime_pattern = re.compile("running time : (\\d+)musec")
  runtimes = []

  with open(file, "r") as f:
    for line in f:
      line = line.strip()
      if (match := runtime_pattern.search(line)) is not None:
          runtimes.append(int(match[1]))

    return pd.Series(runtimes).mean()

def parse_if(file):
  runtime_pattern = re.compile("Finished recursion, needed (\\d+)musec")
  runtimes = []

  with open(file, "r") as f:
    for line in f:
      line = line.strip()
      if (match := runtime_pattern.search(line)) is not None:
          runtimes.append(int(match[1]))

    return pd.Series(runtimes).mean()

def parse_results(file):
  line_handler = lambda l: None

  runtime_pattern = re.compile("(\\d+) micro seconds")

  contraction_runtime_pattern = re.compile("Finished building chordal supergraph, needed (\\d+)musec")
  contraction_runs = []
  shortcuts_pattern = re.compile("Chordal supergraph contains (\\d+) arcs")
  shortcuts = None

  def parse_contraction_line(line):
    nonlocal shortcuts
    if (match := contraction_runtime_pattern.search(line)) is not None:
      contraction_runs.append(int(match[1]))
    if (match := runtime_pattern.search(line)) is not None:
      contraction_runs.append(int(match[1]))
    elif (match := shortcuts_pattern.search(line)) is not None:
      shortcuts = int(match[1])

  customization_runs = []
  triangles_pattern = re.compile("triangles: (\\d+)")
  triangles = None
  triangles_per_level_pattern = re.compile("(\\d+)\\s+(\\d+)")
  triangles_per_level = {}

  def parse_customziation_line(line):
    nonlocal triangles
    if (match := triangles_per_level_pattern.search(line)) is not None:
      triangles_per_level[int(match[1])] = int(match[2])
    elif (match := runtime_pattern.search(line)) is not None:
      customization_runs.append(int(match[1]))
    elif (match := triangles_pattern.search(line)) is not None:
      triangles = int(match[1])

  query_runs = []

  def parse_query_line(line):
    if (match := runtime_pattern.search(line)) is not None:
      query_runs.append(int(match[1]))

  with open(file, "r") as f:
    for line in f:
      line = line.strip()
      if line.startswith('contraction: '):
        line_handler = parse_contraction_line
      elif line.startswith('customizsation: '):
        line_handler = parse_customziation_line
      elif line.startswith('queries: '):
        line_handler = parse_query_line
      else:
        line_handler(line)

  return {
    "avg_contraction_running_time": pd.Series(contraction_runs).mean(),
    "num_shortcuts": shortcuts,
    "num_triangles": triangles,
    "triangles_per_level": triangles_per_level,
    "avg_customization_running_time": pd.Series(customization_runs).mean(),
    "avg_query_time": pd.Series(query_runs).mean()
  }

base = '/algoDaten/mzuendorf/sea_paper/graph'

all_results = []

for machine in ['compute5', 'compute11', 'compute12', 'compute_5', 'compute_11', 'compute_12']:
  for graph in ['chicago', 'europe', 'london', 'stuttgart', 'chicago_urestricted', 'chicago_u100', 'europe_u100']:
    for partition in ['ifc', 'if']:
      for order in ['orig', 'order_expansion', 'order_on_expanded', 'cuts', 'cuts_reorder']:
        order_file = "{}/{}{}/{}{}{}.txt".format(
          base,
          graph.split('_')[0],
          "" if order in ['orig', 'order_expansion'] else '_'.join(["_exp"] + graph.split('_')[1:]),
          machine.replace('_', ''),
          "_inertialflow" if partition == 'if' else '',
          { 'orig': '', 'order_expansion': '', 'order_on_expanded': '', 'cuts': '_cuts_normal', 'cuts_reorder': '_cuts_reorder' }[order],
        )

        if os.path.isfile(order_file):
          order_running_time = parse_ifc(order_file) if partition == 'ifc' else parse_if(order_file)
        else:
          order_running_time = np.nan
          print("Missing order file: {}".format(order_file))

        for opt in ['none', 'undirected_inf', 'directed_inf']:
          results_file = "{}/{}{}/cch_perm_compute11_{}{}result_{}{}.txt".format(
            base,
            graph.split('_')[0],
            "" if order == 'orig' else '_'.join(["_exp"] + graph.split('_')[1:]),
            "inertialFlow_" if partition == 'if' else '',
            { 'orig': '', 'order_expansion': 'expanded_', 'order_on_expanded': '', 'cuts': 'cuts_normal_', 'cuts_reorder': 'cuts_reorder_' }[order],
            machine,
            { 'none': '', 'undirected_inf': '_undirected_inf_arcs', 'directed_inf': '_directed' }[opt]
          )

          if os.path.isfile(results_file):
            results = parse_results(results_file)

            results['order_running_time'] = order_running_time
            results['machine'] = machine.replace('_', '')
            results['graph'] = graph
            results['partition'] = partition
            results['order'] = order
            results['optimizations'] = opt

            all_results.append(results)

          else:
            print("Missing result file: {}".format(results_file))

        if order == 'orig':
          for table_order in ['random', 'inorder']:
            results_file = "{}/{}{}/cch_perm_compute11_{}result_{}_table_{}.txt".format(
              base,
              graph.split('_')[0],
              '_'.join(["_turns"] + graph.split('_')[1:]),
              "inertialFlow_" if partition == 'if' else '',
              machine,
              table_order
            )

            if os.path.isfile(results_file):
              results = parse_results(results_file)

              results['order_running_time'] = order_running_time
              results['machine'] = machine.replace('_', '')
              results['graph'] = graph
              results['partition'] = partition
              results['order'] = table_order
              results['optimizations'] = 'tables'

              all_results.append(results)

            else:
              print("Missing result file: {}".format(results_file))

results = pd.DataFrame(all_results)
