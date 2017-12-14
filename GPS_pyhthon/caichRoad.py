# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 16:14:31 2017
本程序用于利用两客一危数据分析异常驾驶行为（主要是加减速）特征
多维标度分析
聚类分析
@author: Zhwh-notebook
"""
__author__ = "张巍汉"

import urllib3
import time

# 定义函数计算Unix时间戳
def timestamp(local_st):
    local_st = str(local_st)
    timeArray = time.strptime(local_st, "%Y-%m-%d %H:%M:%S")
    # 转换为时间戳:
    timeStamp = int(time.mktime(timeArray))
    return timeStamp

begin = "http://restapi.amap.com/v3/autograsp?"
carid = "&carid="+"7458"+str(data['vehicleID'].values[0])
output = "&output=json"
key = "&key=2aaa2fd1515f77aa9a6061a202737458"

for i in range(len(data.index)-2):
    time1 = timestamp(data['GpsTime'].iloc[i])
    time2 = timestamp(data['GpsTime'].iloc[i+1])
    time3 = timestamp(data['GpsTime'].iloc[i+2])
    time = "&time="+str(time1)+","+str(time2)+","+str(time3)

    drc1 = data['direction'].iloc[i]
    drc2 = data['direction'].iloc[i+1]
    drc3 = data['direction'].iloc[i+2]
    direction = "&direction="+str(drc1)+','+str(drc2)+','+str(drc3)

    speed1 = data['GPS_Speed'].iloc[i]
    speed2 = data['GPS_Speed'].iloc[i+1]
    speed3 = data['GPS_Speed'].iloc[i+2]
    speed = "&speed="+str(speed1)+','+str(speed2)+','+str(speed3)

    lat1 = data['latitude'].iloc[i]
    lat2 = data['latitude'].iloc[i+1]
    lat3 = data['latitude'].iloc[i+2]

    long1 = data['longitude'].iloc[i]
    long2 = data['longitude'].iloc[i+1]
    long3 = data['longitude'].iloc[i+2]

    location1 = str(long1)+','+str(lat1)
    location2 = str(long2)+','+str(lat2)
    location3 = str(long3)+','+str(lat3)
    location = "&locations="+location1+'|'+location2+'|'+location3

    url = begin+key+carid+location+time+direction+speed+output

    http = urllib3.PoolManager()
    r = http.request('GET', url)
    print(r.status)
    print(r.data)

