# -*- coding: utf-8 -*-
"""
Created on Fri Sep  8 11:14:58 2017

@author: Zhwh-notbook
"""
import pandas as pd
# =============================================================================
# 给定范围内的做表现的数量
# =============================================================================
def Numcoordinate(GPSData,R=100):
    colnames = ["sectionID","BPlongitude","BPlatitude","EPlongitude","EPlatitude","distance","pointNum"]
    Numpoints = pd.DataFrame(columns=colnames)
    GPSDdata = GPSData.sort_values(by=['longitude','latitude'],ascending=True) 
    
   