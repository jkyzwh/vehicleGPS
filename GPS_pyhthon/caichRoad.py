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
import math
import json

begin = "http://restapi.amap.com/v3/autograsp?"
output = "&output=json"
key = "&key=2aaa2fd1515f77aa9a6061a202737458"

'''
市政院的key
&key=771f529bb4d20b88fc847b8f1954b737
'''

# 定义函数计算Unix时间戳------------------------------------------------------------------
def timestamp(local_st):
    local_st = str(local_st)
    timeArray = time.strptime(local_st, "%Y-%m-%d %H:%M:%S")
    # 转换为时间戳:
    timeStamp = int(time.mktime(timeArray))
    return timeStamp


# 将GPS坐标转换为高德火星坐标，主函数是GPSToGaoDecoords( GPSData)----------------------------
def transformLon(x, y):
    ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(abs(x))
    ret = ret + (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret = ret + (20.0 * math.sin(x * math.pi) + 40.0 * math.sin(x / 3.0 * math.pi)) * 2.0 / 3.0
    ret = ret + (150.0 * math.sin(x / 12.0 * math.pi) + 300.0 * math.sin(x / 30.0 * math.pi)) * 2.0 / 3.0
    return ret

def transformLat(x, y):
    ret = (-100.0) + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * math.sqrt(abs(x))
    ret = ret + (20.0 * math.sin(6.0 * x * math.pi) + 20.0 * math.sin(2.0 * x * math.pi)) * 2.0 / 3.0
    ret = ret + (20.0 * math.sin(y * math.pi) + 40.0 * math.sin(y / 3.0 * math.pi)) * 2.0 / 3.0
    ret = ret + (160.0 * math.sin(y / 12.0 * math.pi) + 320 * math.sin(y * math.pi / 30.0)) * 2.0 / 3.0
    return ret

def GPSToGaoDecoords(data):
    GPSData = data.copy()
    a = 6378245.0
    ee = 0.00669342162296594323
    colnames = ["vehicleID", "lon", "lat", "GPS_Speed", "direction", "elevation", "GpsTime"]
    GPSData.columns = colnames
    GPSData['latitude'] = 0
    GPSData['longitude'] = 0
    GPSData['latitude'] = GPSData['latitude'].astype(float)
    GPSData['longitude'] = GPSData['longitude'].astype(float)
    for i in range(len(GPSData.index)):
        dLat = transformLat(GPSData['lon'].iloc[i] - 105.0, GPSData['lat'].iloc[i] - 35.0)
        dLon = transformLon(GPSData['lon'].iloc[i] - 105.0, GPSData['lat'].iloc[i] - 35.0)
        radLat = GPSData['lat'].iloc[i] / 180.0 * math.pi
        magic = math.sin(radLat)
        magic = 1 - ee * magic * magic
        sqrtMagic = math.sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * math.pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * math.cos(radLat) * math.pi)
        GPSData['latitude'].values[i] = GPSData['lat'].iloc[i] + dLat
        GPSData['longitude'].values[i] = GPSData['lon'].iloc[i] + dLon
    result = GPSData[["vehicleID", "longitude", "latitude", "GPS_Speed", "direction", "elevation", "GpsTime"]]
    return result


def getgaodeinfo(data):
    data = data.drop_duplicates(['GpsTime'])  # 删除重复的时间
    data = GPSToGaoDecoords(data)
    data['roadname'] = 'nodata'
    data['maxspeed'] = 0
    data['roadlevel'] = '00000'
    for i in range(len(data.index) - 2):
        print('catchgaode,i=', i)
        carid = "&carid=" + "7458" + str(data['vehicleID'].values[0])

        time1 = timestamp(data['GpsTime'].iloc[i])
        time2 = timestamp(data['GpsTime'].iloc[i + 1])
        time3 = timestamp(data['GpsTime'].iloc[i + 2])
        timejoin = "&time=" + str(time1) + "," + str(time2) + "," + str(time3)
        drc1 = data['direction'].iloc[i]
        drc2 = data['direction'].iloc[i + 1]
        drc3 = data['direction'].iloc[i + 2]
        direction = "&direction=" + str(drc1) + ',' + str(drc2) + ',' + str(drc3)
        speed1 = data['GPS_Speed'].iloc[i]
        speed2 = data['GPS_Speed'].iloc[i + 1]
        speed3 = data['GPS_Speed'].iloc[i + 2]
        speed = "&speed=" + str(speed1) + ',' + str(speed2) + ',' + str(speed3)
        lat1 = data['latitude'].iloc[i]
        lat2 = data['latitude'].iloc[i + 1]
        lat3 = data['latitude'].iloc[i + 2]
        long1 = data['longitude'].iloc[i]
        long2 = data['longitude'].iloc[i + 1]
        long3 = data['longitude'].iloc[i + 2]
        location1 = str(long1) + ',' + str(lat1)
        location2 = str(long2) + ',' + str(lat2)
        location3 = str(long3) + ',' + str(lat3)
        location = "&locations=" + location1 + '|' + location2 + '|' + location3
        url = begin + key + carid + location + timejoin + direction + speed + output
        http = urllib3.PoolManager()
        r = http.request('GET', url)

        if json.loads(r.data)['status'] == '1':
            if len(json.loads(r.data)['roads']) > 0:
                crosspoint = json.loads(r.data)['roads'][0]['crosspoint']
                crosspoint = crosspoint.split(',')
                data['longitude'].values[i] = crosspoint[0]
                data['latitude'].values[i] = crosspoint[1]
                data['maxspeed'].values[i] = json.loads(r.data)['roads'][0]['maxspeed']
                data['roadlevel'].values[i] = json.loads(r.data)['roads'][0]['roadlevel']
                data['roadname'].values[i] = json.loads(r.data)['roads'][0]['roadname']
    return data

# 利用地理逆编码API抓取道路信息

def gaodegeocode(gpsdata):
    data = gpsdata.copy()
    begin = "http://restapi.amap.com/v3/geocode/regeo?"
    output = "&output=json"
    key = "key=2aaa2fd1515f77aa9a6061a202737458"
    radius = '&radius=300'
    extensions = '&extensions=all'
    batch = '&batch=false'
    roadlevel = '&roadlevel=0'
    data = data.drop_duplicates(['GpsTime'])  # 删除重复的时间
    data = GPSToGaoDecoords(data)
    data['roadname'] = 'nodata'
    data['road_gaodeID'] = 'noid'
    data['roadlevel'] = '00000'
    data['GDdirection'] = 'direction'

    for i in range(len(data.index)):
        print('逆编码,i=', i)
        lat = data['latitude'].iloc[i]
        long = data['longitude'].iloc[i]
        location = str(long) + ',' + str(lat)
        location = "&location=" + location
        url = begin + key + location + radius + extensions + batch + roadlevel + output
        http = urllib3.PoolManager()
        r = http.request('GET', url)
        if json.loads(r.data)['status'] == '1':
            roadsinfo = json.loads(r.data)['regeocode']['roads'][0]
            if len(roadsinfo) > 0:
                crosspoint = roadsinfo['location']
                crosspoint = crosspoint.split(',')
                data['longitude'].values[i] = crosspoint[0]
                data['latitude'].values[i] = crosspoint[1]
                data['roadname'].values[i] = roadsinfo['name']
                data['road_gaodeID'].values[i] = roadsinfo['id']
                data['GDdirection'].values[i] = roadsinfo['direction']
    return data
