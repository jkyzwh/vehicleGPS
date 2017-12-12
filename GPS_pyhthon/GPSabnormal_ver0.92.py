# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 16:14:31 2017
本程序用于利用两客一危数据分析异常驾驶行为（主要是加减速）特征
多维标度分析
聚类分析
@author: Zhwh-notbook
"""
import os
import random
import pandas as pd
import fun
import time

# import math
# import numpy as np
# import datetime as dt


os.chdir("D:\\GitHubTree\\vehicleGPS\\GPS_pyhthon")   # 修改当前工作目录
os.getcwd()    # 获取当前工作目录

# ==============================================================================
# 导入原始数据，对原始数据的列进行标准化命名
# ==============================================================================
dataName = 'D:\\PROdata\\Data\\dangerous good transport\\sichuan-xcar-2016080810.csv'
# dataName = '/home/zhwh/Data/sichuan-xcar-2016080810.csv'
colname = ["vehicleID", "longitude", "latitude", "GPS_Speed", "direction", "elevation", \
           "GpsTime"]
print('读入两客一危数据')
GPSData_initial = pd.read_csv(dataName, header=0)
GPSData_initial.columns = colname

# =============================================================================
# 对所有车辆的数据基本属性进行描述
# =============================================================================
'''
记录函数运行时间，vehicleinfo()与vehicleinfo2()函数执行效率基本相当
'''
#import time
#start = time.time()
#vehicle_information =  vehicleinfo2(GPSData_initial)
#end = time.time()
#print (end-start)

vehicle_information = fun.vehicleinfo2(GPSData_initial)

'''
筛选速度非零数据行大于100，GPS数据采样间隔小于60S的数据
'''
effectiveData_info = vehicle_information[(vehicle_information['unzerospeedNum'] >= 100) & \
                                         (vehicle_information['timespaceMode'] <= 60)]

for i in range(len(effectiveData_info.index)):
    IDn = effectiveData_info['ID'].values[i]
    print("i=", i)
    if i == 1:
        effectiveData = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
    if i > 1:
        effectiveData = effectiveData.append(GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn])

# =============================================================================
# 筛选有使用价值的数据，抓取高德地图道路信息
# =============================================================================

col_name = ["vehicleID", "longitude", "latitude", "GPS_Speed", "direction", "elevation", "GpsTime",\
            'lon_fix', 'lat_fix', 'lon_GD', 'lat_GD', 'dis_to_GD', 'city',\
            'roadName', 'roadType', 'roadWidth', 'lon_roadbegin', 'lat_roadbegin', 'dis_to_BP',\
            'roadpath']

effectiveData = effectiveData.reindex(columns=col_name)

'''
为便于计算，将数据框指定为字符型
'''
effectiveData = effectiveData.astype(str)

'''
抓取高德地图信息
'''
t_star0 = time.time()  # 开始处理数据，以此时为数据处理起点时间
# i=0#数据条数
for i in range(len(effectiveData.index)):  # 开始数据处理大循环
    # print(row['longitude'])
    # i+=1
    # Index = GPSData.index[i]
    t_star = time.time()  # 本条数据开始处理的时间,大批处理数据时可以注释掉
    longitude = effectiveData["longitude"].values[i]  # 取经度，肯定是东经
    latitude = effectiveData["latitude"].values[i]  # 取纬度，肯定是北纬
    roads_info = fun.regeocode(longitude, latitude)  # 调用函数，取回结果

    '''以下对返回结果进行字符串解析。解析方式和结果定义形式有关。
    如一个取回的结果“106.749118,31.86048,106.749,31.8613,105,巴中市,云台街,省道,8,106.747231,31.860627,473;106.747231,31.860627,106.749465,31.861792”，
    分号把“道路全坐标”和其他数据分开了，其他数据之间用逗号分隔'''
    roads0 = roads_info.split(';')  # 分离“道路全坐标”和其他数据
    roads = roads0[0].split(',')
    if str(roads[0]).find('没有取到结果') < 0:
        effectiveData['lon_fix'].values[i] = roads[0]
        effectiveData['lat_fix'].values[i] = roads[1]
        effectiveData['lon_GD'].values[i] = roads[2]
        effectiveData['lat_GD'].values[i] = roads[3]
        effectiveData['dis_to_GD'].values[i] = roads[4]
        effectiveData['city'].values[i] = roads[5]
        effectiveData['roadName'].values[i] = roads[6]
        effectiveData['roadType'].values[i] = roads[7]
        effectiveData['roadWidth'].values[i] = roads[8]
        effectiveData['lon_roadbegin'].values[i] = roads[9]
        effectiveData['lat_roadbegin'].values[i] = roads[10]
        effectiveData['dis_to_BP'].values[i] = roads[11]
    if len(roads0) > 1:
        effectiveData['roadpath'].values[i] = str(roads0[1].split('@'))
        # 道路全坐标长度不定，有的道路坐标点很多，有的道路很少，如果每个坐标单独储存，反而不好用。这里全部保存在一个单元格，split不是要解析字符串，而是转换成列表
    else:
        effectiveData['roadpath'].values[i] = ['导航数据出现问题']
    # 在原数据的末尾，添加我们的结果
    t_end = time.time()  # 处理本条数据的结束时间,大批处理数据时可以注释掉
    print(i, t_end - t_star)

# =============================================================================
# 筛选异常驾驶行为点
# =============================================================================
'''
将GPS时间转换为time类型
'''
GPSData_initial['GpsTime'] = pd.to_datetime(GPSData_initial['GpsTime'])
vehicleNum = 50  #vehicleNum是有效ID数据中速度大于零的最小数量
ID = GPSData_initial.drop_duplicates(['vehicleID'])['vehicleID']    #提取车辆ID
print('分析驾驶人异常驾驶行为，当前已经处理的数据数量为：')
map_ab = pd.DataFrame()
for i in range(len(ID.index)):
    IDn = ID.iloc[i]
    GPSData = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
    GPSData = fun.vehicleDataINI(GPSData)
    if len(GPSData.loc[GPSData['spacing'] > 0]) > vehicleNum  and \
    len(GPSData.loc[GPSData["GPS_Speed"] > 0]) > vehicleNum:

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

    print(i)
    #if i>1000:
     #   break
map_ab = fun.IndependentPoint(map_ab,L=300,Nclusters=2)





