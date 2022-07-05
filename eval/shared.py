import os
import re

def path_to_graph(path):
    return {
        'stuttgart': 'Stuttgart',
        'stuttgart_exp': 'Stuttgart',
        'chicago': 'Chicago',
        'chicago_exp': 'Chicago',
        'london': 'London',
        'london_exp': 'London',
        'osm_ger': 'Germany',
        'osm_ger_exp': 'Germany',
        'europe': 'Europe',
        'europe_exp': 'Europe',
        'europe_turns': 'Europe Turns',
        'europe_turns_exp': 'Europe Turns',
    }[[x for x in path.split('/') if x != ''][-1]]


def add_latex_big_number_spaces(src):
  return re.sub(re.compile('([0-9]{3}(?=[0-9]))'), '\\g<0>,\\\\', src[::-1])[::-1]

graph_selection = ['Stuttgart', 'Germany','Europe']
