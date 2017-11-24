# -*- coding: utf-8 -*-
"""
Created on nov 23 14:51:31 2017
对获取的两客一危GPS数据进行初始化，具体任务包括：
1. 对数据进行描述性汇总，筛选有计算意义的数据
2. 抓取高德地图信息，补充GPS车辆轨迹信息
@author: Zhwh-notbook
"""
import math
import pandas as pd
import numpy as np
#import random 
#import datetime as dt
#import time
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

#==============================================================================
# 定义函数，将每个ID的数据整理为可以进行异常行为识别的数据
#==============================================================================
def vehicleDataINI(GPSData):    
     GPSData['year'] = GPSData.loc[:,'GpsTime'].dt.year      #计算年份
     GPSData['month'] = GPSData.loc[:,'GpsTime'].dt.month    #计算月份
     GPSData['day'] = GPSData.loc[:,'GpsTime'].dt.day        #计算日期
     GPSData['hour'] = GPSData.loc[:,'GpsTime'].dt.hour      #计算小时
     GPSData['dayofweek'] = GPSData.loc[:,'GpsTime'].dt.weekday_name  #计算星期几
     '''
     按照时间顺序排序，去除时间重复的数据行，然后计算各项数据值
     '''
     GPSData = GPSData.drop_duplicates(['GpsTime'])   #删除重复的时间
     GPSData = GPSData.sort_values(by=['GpsTime'],ascending=True) #按照时间值排序
     '''
     计算两行之间的时间差，以秒计算
     Pandas计算出的时间间隔数据的类型是np.timedelta64, 不是Python标准库中的timedelta类型，
     因此没有total_seconds()函数，需要除以np.timedelta64的1秒来计算间隔了多少秒。
     '''
     GPSData['Time_diff'] = GPSData['GpsTime'].diff().map(lambda x: x/np.timedelta64(1,'s'))
     GPSData['Time_diff'].values[0] = 0
     GPSData['Speed_diff'] = GPSData['GPS_Speed'].diff()  #速度差值
     GPSData['Speed_diff'].values[0] = 0
     GPSData['direction_diff'] = GPSData['direction'].diff() #方位角变化
     GPSData['direction_diff'].values[0] = 0
     GPSData['Acc'] = GPSData['Speed_diff']/GPSData['Time_diff']  #加速度计算
     GPSData['Acc'].values[0] = 0
     '''
     调用函数，计算相邻点之间的距离
     '''
     GPSData['spacing'] = 0
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
     
     GPSData['angleChangeRate'] = abs(GPSData['direction_diff']/GPSData['spacing'])  
     GPSData['angleChangeRate'].values[0] = 0
     GPSData['speed_split'] = round(GPSData['GPS_Speed']/10)      
     return(GPSData)
 
# =============================================================================
# 对不同车辆的基本特征进行整理
# =============================================================================
def vehicleinfo(GPSData_initial):
    GPSData_initial['GpsTime'] = pd.to_datetime(GPSData_initial['GpsTime'])
    ID = GPSData_initial.drop_duplicates(['vehicleID'])['vehicleID']
    
    colnames = ["ID","AlldataNum","unzerospeedNum",
               "speed_min","speed_max",
               "begintime","endtime","timeAll", "drivingtime",
               "timespaceMax","timespaceMode","roadNum","distance"]
    vehicle_information = pd.DataFrame(index=np.arange(0,len(ID)),columns=colnames)
    
    for i in range(len(ID.index)):
        print("i=",i)
        IDn = ID.iloc[i]
        GPSData = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
        GPSData = vehicleDataINI(GPSData)
        vehicle_information['ID'].values[i] = IDn
        vehicle_information['AlldataNum'].values[i] = len(GPSData)
        vehicle_information["begintime"].values[i] = GPSData['GpsTime'].iloc[0]
        vehicle_information["endtime"].values[i] = GPSData['GpsTime'].iloc[len(GPSData)-1]
        #vehicle_information["timeAll"].values[i] = sum(GPSData['Time_diff'])
        vehicle_information["distance"].values[i] = sum(GPSData['spacing'])
        vehicle_information["timespaceMax"].values[i] = max(GPSData['Time_diff'])
        vehicle_information["timespaceMode"].values[i] = GPSData['Time_diff'].mode()[0] #众数
        
        a = GPSData.loc[GPSData['GPS_Speed'] > 0].copy()
        if len(a) == 0:
            vehicle_information['speed_min'].values[i] = 0
            vehicle_information['speed_max'].values[i] = 0
            vehicle_information['unzerospeedNum'].values[i] = 0
            vehicle_information["drivingtime"].values[i] = 0
            vehicle_information["roadNum"].values[i] = 0
                        
        if len(a) > 0:
            vehicle_information['speed_min'].values[i] = min(a['GPS_Speed'])
            vehicle_information['speed_max'].values[i] = max(a['GPS_Speed'])
            vehicle_information['unzerospeedNum'].values[i] = len(a['GPS_Speed'])
            vehicle_information["drivingtime"].values[i] = sum(a['Time_diff'])
             
        if i>19:
            break
    vehicle_information["timeAll"] = (vehicle_information["endtime"]-vehicle_information["begintime"])/np.timedelta64(1, 's')
    return(vehicle_information)
    
#==============================================================================
# 导入原始数据，对原始数据的列进行标准化命名
#==============================================================================
dataName = 'D:\\PROdata\\Data\\dangerous good transport\\sichuan-xcar-2016080810.csv'
#dataName = '/home/zhwh/Data/sichuan-xcar-2016080810.csv'
colname = ["vehicleID","longitude","latitude",\
           "GPS_Speed","direction","elevation",\
           "GpsTime"]
print('读入两客一危数据')
GPSData_initial = pd.read_csv(dataName,header=0) 
GPSData_initial.columns = colname

# =============================================================================
# 对所有车辆的数据基本属性进行描述
# =============================================================================
vehicle_information =  vehicleinfo(GPSData_initial)

# =============================================================================
# 筛选有使用价值的数据
# =============================================================================



