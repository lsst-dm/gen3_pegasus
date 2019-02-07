#!/usr/bin/env python

import sys
import pickle
import networkx

print(sys.argv[1])
wffile = sys.argv[1]

with open(wffile, 'rb') as infile:
    wfgraph = pickle.load(infile)

print(wfgraph)
print(networkx.number_of_nodes(wfgraph))

for node in wfgraph.nodes(data=True): 
    print(node)
