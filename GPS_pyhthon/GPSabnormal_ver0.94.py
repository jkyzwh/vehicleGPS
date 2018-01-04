# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 16:14:31 2017
本程序用于利用两客一危数据分析异常驾驶行为（主要是加减速）特征
多维标度分析
聚类分析
@author: Zhwh-notbook
"""
__author__ = "张巍汉"

import os
import random
import pandas as pd
import fun
import caichRoad
import time
from filename import data_file_path, PROJECT_ROOT

# import math
# import numpy as np
# import datetime as dt

os.chdir(PROJECT_ROOT)   # 修改当前工作目录为当前脚本所在目录
# os.getcwd()    # 获取当前工作目录

# ==============================================================================
# 导入原始数据，对原始数据的列进行标准化命名
# ==============================================================================
# dataName = 'D:\\PROdata\\Data\\dangerous good transport\\sichuan-xcar-2016080810.csv'
# dataName = '/home/zhwh/Data/sichuan-xcar-2016080810.csv'
colname = ["vehicleID", "longitude", "latitude", "GPS_Speed", "direction", "elevation", \
           "GpsTime"]
print('读入两客一危数据')
GPSData_initial = pd.read_csv(data_file_path, header=0)
GPSData_initial.columns = colname

# =============================================================================
# 对所有车辆的数据基本属性进行描述
# =============================================================================

vehicle_information = fun.vehicleinfo2(GPSData_initial)

# 筛选速度非零数据行大于200，GPS数据采样间隔小于60S的数据
effectiveData_info = vehicle_information[(vehicle_information['unzerospeedNum'] >= 20) &
                                         (vehicle_information['timespaceMode'] <= 60)]

for i in range(len(effectiveData_info.index)):
    IDn = effectiveData_info['ID'].values[i]
    print("effevtivedata i=", i)
    if i == 0:
        effectiveData = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
        #effectiveData = caichRoad.getgaodeinfo(effectiveData)
        #effectiveData = caichRoad.gaodegeocode(effectiveData)
    if i > 0:
        temp = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
        #temp = caichRoad.getgaodeinfo(temp)
        #temp = caichRoad.gaodegeocode(temp)
        effectiveData = effectiveData.append(temp)

# =============================================================================
# 筛选异常驾驶行为点
# =============================================================================
# 将GPS时间转换为time类型

effectiveData['GpsTime'] = pd.to_datetime(effectiveData['GpsTime'])
#vehicleNum = 50  #vehicleNum是有效ID数据中速度大于零的最小数量
ID = effectiveData_info['ID'] #提取车辆ID
print('分析驾驶人异常驾驶行为，当前已经处理的数据数量为：')
map_ab = pd.DataFrame()
for i in range(len(ID.index)):
    IDn = ID.iloc[i]
    GPSData = effectiveData.loc[effectiveData['vehicleID'] == IDn].copy()
    GPSData = fun.vehicleDataINI(GPSData)
    GPSData_ab = fun.funAbnormalData(GPSData,0.95)
    GPSData_ab['vehicleID'] = IDn
    Pointcol = random.choice(fun.col)
    if len(GPSData_ab['vehicleID'])>0:
        GPSData_ab['col'] = Pointcol
    if i == 1:
        map_ab = GPSData_ab.copy()
            #map_ab = IndependentPoint(map_ab,L=300,Nclusters=2)
    if i > 1:
        map_ab = pd.concat([map_ab,GPSData_ab],ignore_index=True)
            #map_ab = IndependentPoint(map_ab,L=300,Nclusters=2)
    print('异常驾驶行为数据筛选提取',i)

#map_ab = fun.IndependentPoint(map_ab, L=300, Nclusters=2)

# =============================================================================
# 筛选有使用价值的数据，抓取高德地图道路信息
# =============================================================================

ABmap = fun.getregeocode(map_ab)





