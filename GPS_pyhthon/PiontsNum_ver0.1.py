# -*- coding: utf-8 -*-
"""
Created on Fri Sep  8 11:14:58 2017

@author: Zhwh-notbook
"""
import pandas as pd
import math
#==============================================================================
# 根据经纬度计算两点见距离的函数
#==============================================================================
def calcDistance(Lat_A, Lng_A, Lat_B, Lng_B):
    ra = 6378.140  # 赤道半径 (km)
    rb = 6356.755  # 极半径 (km)
    flatten = (ra - rb) / ra  # 地球扁率
    rad_lat_A = math.radians(Lat_A)
    rad_lng_A = math.radians(Lng_A)
    rad_lat_B = math.radians(Lat_B)
    rad_lng_B = math.radians(Lng_B)
    pA = math.atan(rb / ra * math.tan(rad_lat_A))
    pB = math.atan(rb / ra * math.tan(rad_lat_B))
    ss = math.sin(pA) * math.sin(pB) + math.cos(pA) * math.cos(pB) * math.cos(rad_lng_A - rad_lng_B)
    if ss>1:
        ss = 1
    if ss<-1:
        ss = -1    
    xx = math.acos(ss)
    c1 = (math.sin(xx) - xx) * (math.sin(pA) + math.sin(pB)) ** 2 / math.cos(xx / 2) ** 2
    if math.sin(xx/2) == 0:
        c2 = 0
    else:
        c2 = (math.sin(xx) + xx) * (math.sin(pA) - math.sin(pB)) ** 2 /\
        math.sin(xx/2) ** 2
    dr = flatten/8 * (c1 - c2)
    distance = ra * (xx + dr)
    return (distance)
# =============================================================================
# 给定范围内的做表现的数量
# =============================================================================
def Numcoordinate(GPSData,L=100):
    colnames = ["sectionID","BPlongitude","BPlatitude","EPlongitude","EPlatitude","distance","pointNum"]
    Numpoints = pd.DataFrame(columns=colnames)
    GPSData = GPSData.sort_values(by=['longitude','latitude'],ascending=True)
    GPSData['spacing'] = 0
    # 重新计算相邻点之间的距离
    for i in range(len(GPSData.index)):
         if i==0:
             GPSData['spacing'].values[i] = 0
         else:
             k = i-1
             Lat_A = GPSData['latitude'].iloc[k]
             Lng_A = GPSData['longitude'].iloc[k]
             Lat_B = GPSData['latitude'].iloc[i]
             Lng_B = GPSData['longitude'].iloc[i]
             GPSData['spacing'].values[i] = calcDistance(Lat_A, Lng_A, Lat_B, Lng_B)*1000
    #计算距离第一点的行驶距离
    GPSData['distance'] = 0
    for i in range(len(GPSData.index)):
         if i==0:
             GPSData['distance'].values[i] = 0
         else:
             temp = GPSData['distance'].iloc[i-1]
             GPSData['distance'].values[i] = temp + GPSData['spacing'].iloc[i]
    '''
    增加secction列，用于描述每行数据所属的道路路段编号
    1. 以第一行数据开始，逐行比较与第一行点的里程距离，如果n行数据距离大于L，则0-（n-1）为第一路段
    2. 以第n行为起点计算下一个距离大于L的数据行
    3. 以此类推
    '''                  
    a = GPSData.copy()
    a['sectionID'] = 0
    #b = pd.Series()
    nextpoint = 0
    for i in range(len(a.index)):
        #print("i=",i)
        #IDn = a['vehicleID'].iloc[i]
        if i == 0:
            for k in range(len(a.index)):
                if a['distance'].iloc[k] <= L:
                    a['sectionID'].values[k] = i
                if a['distance'].iloc[k] > L:
                    nextpoint = k
                    break
        if i > 0:
            #i = nextpoint
            print("i=",i)
            BP = a['distance'].iloc[nextpoint]
            print('BP=',BP)
            print('nextpoint=',nextpoint)
            a['sectionID'].values[nextpoint] = i
            if i>= nextpoint:
                for k in range(nextpoint,len(a.index)):
                    print("k=",k)
                    if a['distance'].iloc[k]-BP <= L :
                        a['sectionID'].values[k] = i
                        
                    if a['distance'].iloc[k]-BP > L :
                        if k > i:
                            nextpoint = k
                        if k < i:
                            nextpoint = i
                        break
        if i == nextpoint:
            break
            
            
            
                    
            
            
            
    
    
   