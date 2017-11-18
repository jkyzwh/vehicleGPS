# -*- coding: utf-8 -*-
"""
Created on Sat Nov 18 22:14:18 2017

@author: DS03
"""

import osmnx as ox
G = ox.graph_from_place('beijing,china',which_result=2)
ox.plot_graph(G)
