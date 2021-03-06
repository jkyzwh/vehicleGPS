# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 16:14:31 2017
本程序用于利用两客一危数据分析异常驾驶行为（主要是加减速）特征
多维标度分析
聚类分析
@author: Zhwh-notbook
"""
import math
import pandas as pd
import numpy as np
#import datetime as dt
#import time
#==============================================================================
# 调用R内置颜色
#==============================================================================
col= ["white","aliceblue","antiquewhite","antiquewhite1","antiquewhite2","antiquewhite3","antiquewhite4","aquamarine","aquamarine1","aquamarine2","aquamarine3","aquamarine4","azure","azure1","azure2","azure3","azure4","beige","bisque","bisque1","bisque2","bisque3","bisque4","black","blanchedalmond","blue","blue1","blue2","blue3","blue4","blueviolet","brown","brown1","brown2","brown3","brown4","burlywood","burlywood1","burlywood2","burlywood3","burlywood4","cadetblue","cadetblue1","cadetblue2","cadetblue3","cadetblue4","chartreuse","chartreuse1","chartreuse2","chartreuse3","chartreuse4","chocolate","chocolate1","chocolate2","chocolate3","chocolate4","coral","coral1","coral2","coral3","coral4","cornflowerblue","cornsilk","cornsilk1","cornsilk2","cornsilk3","cornsilk4","cyan","cyan1","cyan2","cyan3","cyan4","darkblue","darkcyan","darkgoldenrod","darkgoldenrod1","darkgoldenrod2","darkgoldenrod3","darkgoldenrod4","darkgray","darkgreen","darkgrey","darkkhaki","darkmagenta","darkolivegreen","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen4","darkorange","darkorange1","darkorange2","darkorange3","darkorange4","darkorchid","darkorchid1","darkorchid2","darkorchid3","darkorchid4","darkred","darksalmon","darkseagreen","darkseagreen1","darkseagreen2","darkseagreen3","darkseagreen4","darkslateblue","darkslategray","darkslategray1","darkslategray2","darkslategray3","darkslategray4","darkslategrey","darkturquoise","darkviolet","deeppink","deeppink1","deeppink2","deeppink3","deeppink4","deepskyblue","deepskyblue1","deepskyblue2","deepskyblue3","deepskyblue4","dimgray","dimgrey","dodgerblue","dodgerblue1","dodgerblue2","dodgerblue3","dodgerblue4","firebrick","firebrick1","firebrick2","firebrick3","firebrick4","floralwhite","forestgreen","gainsboro","ghostwhite","gold","gold1","gold2","gold3","gold4","goldenrod","goldenrod1","goldenrod2","goldenrod3","goldenrod4","gray","gray0","gray1","gray2","gray3","gray4","gray5","gray6","gray7","gray8","gray9","gray10","gray11","gray12","gray13","gray14","gray15","gray16","gray17","gray18","gray19","gray20","gray21","gray22","gray23","gray24","gray25","gray26","gray27","gray28","gray29","gray30","gray31","gray32","gray33","gray34","gray35","gray36","gray37","gray38","gray39","gray40","gray41","gray42","gray43","gray44","gray45","gray46","gray47","gray48","gray49","gray50","gray51","gray52","gray53","gray54","gray55","gray56","gray57","gray58","gray59","gray60","gray61","gray62","gray63","gray64","gray65","gray66","gray67","gray68","gray69","gray70","gray71","gray72","gray73","gray74","gray75","gray76","gray77","gray78","gray79","gray80","gray81","gray82","gray83","gray84","gray85","gray86","gray87","gray88","gray89","gray90","gray91","gray92","gray93","gray94","gray95","gray96","gray97","gray98","gray99","gray100","green","green1","green2","green3","green4","greenyellow","grey","grey0","grey1","grey2","grey3","grey4","grey5","grey6","grey7","grey8","grey9","grey10","grey11","grey12","grey13","grey14","grey15","grey16","grey17","grey18","grey19","grey20","grey21","grey22","grey23","grey24","grey25","grey26","grey27","grey28","grey29","grey30","grey31","grey32","grey33","grey34","grey35","grey36","grey37","grey38","grey39","grey40","grey41","grey42","grey43","grey44","grey45","grey46","grey47","grey48","grey49","grey50","grey51","grey52","grey53","grey54","grey55","grey56","grey57","grey58","grey59","grey60","grey61","grey62","grey63","grey64","grey65","grey66","grey67","grey68","grey69","grey70","grey71","grey72","grey73","grey74","grey75","grey76","grey77","grey78","grey79","grey80","grey81","grey82","grey83","grey84","grey85","grey86","grey87","grey88","grey89","grey90","grey91","grey92","grey93","grey94","grey95","grey96","grey97","grey98","grey99","grey100","honeydew","honeydew1","honeydew2","honeydew3","honeydew4","hotpink","hotpink1","hotpink2","hotpink3","hotpink4","indianred","indianred1","indianred2","indianred3","indianred4","ivory","ivory1","ivory2","ivory3","ivory4","khaki","khaki1","khaki2","khaki3","khaki4","lavender","lavenderblush","lavenderblush1","lavenderblush2","lavenderblush3","lavenderblush4","lawngreen","lemonchiffon","lemonchiffon1","lemonchiffon2","lemonchiffon3","lemonchiffon4","lightblue","lightblue1","lightblue2","lightblue3","lightblue4","lightcoral","lightcyan","lightcyan1","lightcyan2","lightcyan3","lightcyan4","lightgoldenrod","lightgoldenrod1","lightgoldenrod2","lightgoldenrod3","lightgoldenrod4","lightgoldenrodyellow","lightgray","lightgreen","lightgrey","lightpink","lightpink1","lightpink2","lightpink3","lightpink4","lightsalmon","lightsalmon1","lightsalmon2","lightsalmon3","lightsalmon4","lightseagreen","lightskyblue","lightskyblue1","lightskyblue2","lightskyblue3","lightskyblue4","lightslateblue","lightslategray","lightslategrey","lightsteelblue","lightsteelblue1","lightsteelblue2","lightsteelblue3","lightsteelblue4","lightyellow","lightyellow1","lightyellow2","lightyellow3","lightyellow4","limegreen","linen","magenta","magenta1","magenta2","magenta3","magenta4","maroon","maroon1","maroon2","maroon3","maroon4","mediumaquamarine","mediumblue","mediumorchid","mediumorchid1","mediumorchid2","mediumorchid3","mediumorchid4","mediumpurple","mediumpurple1","mediumpurple2","mediumpurple3","mediumpurple4","mediumseagreen","mediumslateblue","mediumspringgreen","mediumturquoise","mediumvioletred","midnightblue","mintcream","mistyrose","mistyrose1","mistyrose2","mistyrose3","mistyrose4","moccasin","navajowhite","navajowhite1","navajowhite2","navajowhite3","navajowhite4","navy","navyblue","oldlace","olivedrab","olivedrab1","olivedrab2","olivedrab3","olivedrab4","orange","orange1","orange2","orange3","orange4","orangered","orangered1","orangered2","orangered3","orangered4","orchid","orchid1","orchid2","orchid3","orchid4","palegoldenrod","palegreen","palegreen1","palegreen2","palegreen3","palegreen4","paleturquoise","paleturquoise1","paleturquoise2","paleturquoise3","paleturquoise4","palevioletred","palevioletred1","palevioletred2","palevioletred3","palevioletred4","papayawhip","peachpuff","peachpuff1","peachpuff2","peachpuff3","peachpuff4","peru","pink","pink1","pink2","pink3","pink4","plum","plum1","plum2","plum3","plum4","powderblue","purple","purple1","purple2","purple3","purple4","red","red1","red2","red3","red4","rosybrown","rosybrown1","rosybrown2","rosybrown3","rosybrown4","royalblue","royalblue1","royalblue2","royalblue3","royalblue4","saddlebrown","salmon","salmon1","salmon2","salmon3","salmon4","sandybrown","seagreen","seagreen1","seagreen2","seagreen3","seagreen4","seashell","seashell1","seashell2","seashell3","seashell4","sienna","sienna1","sienna2","sienna3","sienna4","skyblue","skyblue1","skyblue2","skyblue3","skyblue4","slateblue","slateblue1","slateblue2","slateblue3","slateblue4","slategray","slategray1","slategray2","slategray3","slategray4","slategrey","snow","snow1","snow2","snow3","snow4","springgreen","springgreen1","springgreen2","springgreen3","springgreen4","steelblue","steelblue1","steelblue2","steelblue3","steelblue4","tan","tan1","tan2","tan3","tan4","thistle","thistle1","thistle2","thistle3","thistle4","tomato","tomato1","tomato2","tomato3","tomato4","turquoise","turquoise1","turquoise2","turquoise3","turquoise4","violet","violetred","violetred1","violetred2","violetred3","violetred4","wheat","wheat1","wheat2","wheat3","wheat4","whitesmoke","yellow","yellow1","yellow2","yellow3","yellow4","yellowgreen"]
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
# 计算异常加减速标准
#==============================================================================
def fun_abnormalACC(GPSData,probs=0.95):
    acc = GPSData.loc[GPSData['Acc']>0 ][['speed_split','Acc']]
    dac = GPSData.loc[GPSData['Acc']<0 ][['speed_split','Acc']]
    dac['Acc'] = abs(dac['Acc'])
    acc['split'] = acc['speed_split']
    dac['split'] = dac['speed_split']
    acc = acc.groupby('speed_split').quantile(q=0.95, axis=0, numeric_only=True, interpolation='linear')
    dac = dac.groupby('speed_split').quantile(q=0.95, axis=0, numeric_only=True, interpolation='linear')
    AccStandard = pd.merge(acc,dac,on='split',how='outer')
    AccStandard = AccStandard.sort_values(by=['split'],ascending=True)
    AccStandard = AccStandard.rename(columns=\
                                     {'split':'speed_split','Acc_x':'ay_abnormalAAC','Acc_y':'ay_abnormalDAC'})
    AccStandard['ay_abnormalDAC'] = 0-AccStandard['ay_abnormalDAC']
    return(AccStandard)

# =============================================================================
# 计算异常方位角变化率标准
# =============================================================================
def fun_abnormalDirection (data,probs=0.95):
    angleChange = GPSData.loc[GPSData['angleChangeRate']>0 ][['speed_split','angleChangeRate']]
    angleChange['split'] = angleChange['speed_split']
    a = angleChange.groupby('speed_split').quantile(q=0.95, axis=0, numeric_only=True, interpolation='linear')
    a = a.sort_values(by=['split'],ascending=True)
    a = a.rename(columns={'split':'speed_split','angleChangeRate':'angleChange_abnormal'})
    return(a)

#==============================================================================
# 筛选数据中属于异常驾驶行为的数据
#==============================================================================
def funAbnormalData(GPSData,probs = 0.95):
    GPSData['ACCabnormal'] = "normal"
    GPSData['angleabnormal'] = "normal"
    AccStandard = fun_abnormalACC(GPSData,probs=0.95)
    DirectionStandard = fun_abnormalDirection(GPSData,probs=0.95)
    
    #加减速、方位角异常行为的筛选
    SDacc = AccStandard[["speed_split","ay_abnormalAAC"]]
    SDdac =  AccStandard[["speed_split","ay_abnormalDAC"]]
    SDdirection = DirectionStandard[["speed_split","angleChange_abnormal"]]
    
    GPSData = pd.merge(GPSData,SDacc,on="speed_split",how='outer')
    GPSData = pd.merge(GPSData,SDdac,on="speed_split",how='outer')
    GPSData = pd.merge(GPSData,SDdirection,on="speed_split",how='outer')
    
    for i in range(len(GPSData.index)):
        if GPSData.Acc.iloc[i] > 0 and GPSData.Acc.iloc[i] > GPSData.ay_abnormalAAC.iloc[i]:
            GPSData.ACCabnormal.values[i] = "ay_AAC"
        if GPSData.Acc.iloc[i] < 0 and GPSData.Acc.iloc[i] < GPSData.ay_abnormalDAC.iloc[i]:
            GPSData.ACCabnormal.values[i] = "ay_DAC"
        if GPSData.angleChangeRate.iloc[i] > 0 and GPSData.angleChangeRate.iloc[i] < GPSData.angleChange_abnormal.iloc[i]:
            GPSData.angleabnormal.values[i] = "angle_directionRate"    
            
    GPSData_ab = GPSData.loc[(GPSData['ACCabnormal'] != "normal") |
                             (GPSData['angleabnormal'] != "normal")].copy()
    #对异常行为点重新按时间排序，计算相邻距离，以及相邻的时间，用做聚类分析
    GPSData_ab = GPSData_ab.sort_values(by=['GpsTime'],ascending=True)
    for i in range(len(GPSData_ab.index)):
        if i>1:
            Lng_A = GPSData_ab.longitude.iloc[i-1]
            Lat_A = GPSData_ab.latitude.iloc[i-1]
            Lng_B = GPSData_ab.longitude.iloc[i]
            Lat_B = GPSData_ab.latitude.iloc[i]
            GPSData_ab.spacing.values[i] = calcDistance(Lat_A, Lng_A, Lat_B, Lng_B)*1000 #计算相邻点之间的距离
    return(GPSData_ab)


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
     GPSData['Time_diff'] = GPSData.GpsTime.diff().map(lambda x: x/np.timedelta64(1, 's'))
     GPSData['Speed_diff'] = GPSData.GPS_Speed.diff()        #速度差值
     GPSData['direction_diff'] = GPSData.direction.diff()        #方位角变化
     GPSData['Acc'] = GPSData['Speed_diff']/GPSData['Time_diff']     #加速度计算
     '''
     调用函数，计算相邻点之间的距离
     '''
     GPSData['spacing'] = 0
     for i in range(len(GPSData.index)):
         if i==0:
             GPSData.spacing.values[i] = 0
         else:
             k = i-1
             Lat_A = GPSData.latitude.iloc[k]
             Lng_A = GPSData.longitude.iloc[k]
             Lat_B = GPSData.latitude.iloc[i]
             Lng_B = GPSData.longitude.iloc[i]
             GPSData.spacing.values[i] = calcDistance(Lat_A, Lng_A, Lat_B, Lng_B)*1000
     
     GPSData['angleChangeRate'] = abs(GPSData['direction_diff']/GPSData['spacing'])     
     GPSData['speed_split'] = round(GPSData.GPS_Speed/10)      
     return(GPSData)
     
#==============================================================================
# 导入原始数据，对原始数据的列进行标准化命名
#==============================================================================
dataName = 'D:\\PROdata\\Data\\dangerous good transport\\sichuan-xcar-2016080810.csv'
colname = ["vehicleID","longitude","latitude",\
           "GPS_Speed","direction","elevation",\
           "GpsTime"]
print('读入两客一危数据')
GPSData_initial = pd.read_csv(dataName,header=0) 
GPSData_initial.columns = colname
'''
将GPS时间转换为time类型
'''
GPSData_initial.GpsTime = pd.to_datetime(GPSData_initial.GpsTime)
vehicleNum = 50  #vehicleNum是有效ID数据中速度大于零的最小数量

#==============================================================================
# 构建循环，按照ID筛选异常行为
#==============================================================================
ID = GPSData_initial.drop_duplicates(['vehicleID'])['vehicleID']    #提取车辆ID
print('分析驾驶人异常驾驶行为，当前已经处理的数据数量为：')
map_ab = pd.DataFrame()
for i in range(len(ID.index)):
    IDn = ID.iloc[i]
    GPSData = GPSData_initial.loc[GPSData_initial['vehicleID'] == IDn].copy()
    if len(GPSData.loc[GPSData["GPS_Speed"] > 0]) > vehicleNum :
        GPSData = vehicleDataINI(GPSData)
        GPSData_ab = funAbnormalData(GPSData,0.95)
        GPSData_ab['vehicleID'] = IDn
        Pointcol = col[i]
        if len(GPSData_ab.vehicleID)>0:
            GPSData_ab['col'] = Pointcol
        if i == 1:
            map_ab = GPSData_ab
        if i > 1:
            map_ab = pd.concat([map_ab,GPSData_ab],ignore_index=True)
            
    print(i)
    if i>20:
        break
       
#==============================================================================
# 利用MDS方法判断异常驾驶员
#==============================================================================
from sklearn.manifold import MDS
import matplotlib.pyplot as plt
plt.rcParams['font.sans-serif']=['SimHei'] #用来正常显示中文标签
plt.rcParams['axes.unicode_minus']=False #用来正常显示负号

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
        GPSData = vehicleDataINI(GPSData)
        acc = GPSData.loc[GPSData['Acc']>0 ]
        dac = GPSData.loc[GPSData['Acc']<0 ]
        if len(acc)>0 and len(dac)>0:
            abnormalStandard = fun_abnormalACC(GPSData,quant)
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
plt.scatter(mdsResult[0:378,0],mdsResult[0:378,1],color='turquoise')

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



