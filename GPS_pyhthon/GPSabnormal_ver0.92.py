# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 16:14:31 2017
本程序用于利用两客一危数据分析异常驾驶行为（主要是加减速）特征
多维标度分析
聚类分析
@author: Zhwh-notbook
"""
import os
os.chdir("D:\\GitHubTree\\vehicleGPS\\GPS_pyhthon")   #修改当前工作目录
os.getcwd()    #获取当前工作目录


#import math
import pandas as pd
import numpy as np
import random 
import fun
#import datetime as dt
#import time
    
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
'''
记录函数运行时间，vehicleinfo()与vehicleinfo2()函数执行效率基本相当
'''
#import time
#start = time.time()
#vehicle_information =  vehicleinfo2(GPSData_initial)
#end = time.time()
#print (end-start)

vehicle_information =  fun.vehicleinfo2(GPSData_initial)


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


#==============================================================================
# 利用MDS方法判断异常驾驶员
#==============================================================================
from sklearn.manifold import MDS

'''
构造一个空数据框，共13列，行数量为驾驶人数量，列名为MDS_colnames

'''
MDS_colnames = ["ID","Acc_23","Acc_34","Acc_45","Acc_56","Acc_67","Acc_78",
                   "Dac_23","Dac_34","Dac_45","Dac_56","Dac_67","Dac_78"]

testNum = 200
vehicleIDList = GPSData_initial.drop_duplicates(['vehicleID'])['vehicleID']    #提取车辆ID
vehicleIDList = vehicleIDList[0:testNum]
mdsData = pd.DataFrame(index=np.arange(0,len(vehicleIDList)),columns=MDS_colnames)


#生成驾驶人特征数据框，行为驾驶人ID，列为特征项
quant = 0.85 #日常特征，取85位
for i in range(len(vehicleIDList)):
    print(i)
    IDn = vehicleIDList.iloc[i]
    GPSData = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
    if len(GPSData.loc[GPSData["GPS_Speed"] > 0]) > vehicleNum : #数据过少的不纳入计算
        GPSData = fun.vehicleDataINI(GPSData)
        acc = GPSData.loc[GPSData['Acc']>0 ]
        dac = GPSData.loc[GPSData['Acc']<0 ]
        if len(acc)>0 and len(dac)>0:
            abnormalStandard = fun.fun_abnormalACC(GPSData,quant)
            Stdlen = len(abnormalStandard['speed_split'])
            if Stdlen>8 :
                Stdlen = 8
            if Stdlen>2:    
                temp = [IDn]
                temp.extend(abnormalStandard.T.iloc[0,:][2:Stdlen].tolist())
                for k in range(8-Stdlen): 
                    temp.append('nan')
                temp.extend(abnormalStandard.T.iloc[2,:][2:Stdlen].tolist())
                for k in range(8-Stdlen):
                    temp.append('nan')
                mdsData.iloc[i]=temp

mdsData = mdsData.loc[pd.isnull(mdsData["ID"]) == False] #剔除ID为‘nan’的数据

'''
利用拉格朗日插值法填充缺失数据
'''
from scipy.interpolate import lagrange

def lagrangeFillnan(y,n,k=2):
   # y = s[list(range(n-k, n)) + list(range(n+1, n+1+k))] #取数
    y = y[y.notnull()]
    result = lagrange(y.index, list(y))(n) #插值并返回插值结果
    return(result)


mdsfillnan = mdsData[["Dac_23","Dac_34","Dac_45","Dac_56","Dac_67","Dac_78"]].T
mdsfillnan = mdsfillnan.apply(lambda x: pd.to_numeric(x, errors='coerce'))
mdsfillnan.index = list(range(2, 8))

#逐个元素判断是否需要插值
for i in mdsfillnan:
    #print('i=',i)
    for j in range(len(mdsfillnan)):
        #print('j=',j)
        #print(mdsfillnan[i].isnull().iloc[j])
        if (mdsfillnan[i].isnull().iloc[j]): #如果为空即插值。
            print('i=',i)
            print('j=',j)
            y = mdsfillnan[i]
            y = y[y.notnull()]
            mdsfillnan[i].values[j] = lagrange(y.index, list(y))(j)

mdsfillnan = mdsfillnan.T            
            
'''
利用df.interpolate方法填充缺失值(按行填充不成功，只能按列填充)

mdsfillnan = mdsData[["Dac_23","Dac_34","Dac_45","Dac_56","Dac_67","Dac_78"]]

#mdsfillnan = mdsData[["Acc_23","Acc_34","Acc_45","Acc_56","Acc_67","Acc_78",
#                   "Dac_23","Dac_34","Dac_45","Dac_56","Dac_67","Dac_78"]]

mdsfillnan = mdsfillnan.apply(lambda x: pd.to_numeric(x, errors='coerce'))
#a = a.interpolate(method='spline', order=2)    
mdsfillnan = mdsfillnan.interpolate(method='values', axis=0,
                                   limit=testNum, limit_direction='both') 
'''
  
'''
sklearn
'''
mds = MDS()
mds.fit(mdsfillnan)
mdsResult = mds.embedding_
mdsResult = pd.DataFrame(mdsResult)
mdsResult['ID'] = mdsData['ID'].values
mdsResult = mdsResult.rename(columns={0:'x',1:'y'})
mdsLen = len(mdsResult['ID'])

import matplotlib.pyplot as plt
plt.rcParams['font.sans-serif']=['SimHei'] #用来正常显示中文标签
plt.rcParams['axes.unicode_minus']=False #用来正常显示负号

#plt.hist(mdsData['Acc_23'], bins=6)
plt.scatter(mdsResult['x'],mdsResult['y'],color='turquoise')
plt.scatter(mdsResult['x'],mdsResult['y'],color='turquoise')

import seaborn as sns
sns.set_style('darkgrid')

sns.jointplot(x=mdsResult['x'],y=mdsResult['y'],kind='kde') #核密度估计
sns.stripplot(x='x',y='y',data=mdsResult) #绘制散点图
sns.regplot(x='x',y='y',data=mdsResult)

sns.stripplot(x="latitude",y="longitude",data=GPSData_ab) #绘制路由图



# =============================================================================
# 测试matplotlib绘图
# =============================================================================
labels='frogs','hogs','dogs','logs'
sizes=15,20,45,10
colors='yellowgreen','gold','lightskyblue','lightcoral'
explode=0,0.1,0,0
plt.pie(sizes,explode=explode,labels=labels,colors=colors,autopct='%1.1f%%',shadow=True,startangle=50)
plt.axis('equal')
plt.show()

plt.plot([1, 2, 3, 4], [1, 4, 9, 16])

# =============================================================================
# 利用Kmeans聚类，筛选高危异常驾驶行为驾驶人
# =============================================================================



