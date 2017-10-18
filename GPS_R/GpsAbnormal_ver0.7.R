#####################################################
# 本程序用于分析两客一危GPS数据，提取运行帖子是那个
# 结合leaflet地图，绘制异常驾驶行为分布图
# 利用MDS或者其他方法，对驾驶人异常行为进行聚类分析
#ver0.5不包含利用地图绘制风险地图的内容
# Ver0.5着眼于基于驾驶行为的聚类分析
#####################################################
#library(devtools)
#install_github('lchiffon/REmap')

# 0. 加载需要的程序包------------
library(data.table)
library(psych)
library(plyr)
library(dplyr)
library(stats)
library(MASS)
library(lubridate)  #时间数据处理包
library(stringr)
library(readr)
library(ggplot2)
library(ggthemes)
library(REmap) #百度地图
library(leaflet) #R标准地图包
library(leafletCN)
library(lattice) #调入函数包  
library(nnet)  
library(mice) #前三个包是mice的基础  

#library(ggmap)
#library(baidumap)#百度地图包
#options(baidumap.key = 'kvfrFNTcOQWVFUmhwqZhYzxxVj088NuW') #百度地图API访问key

#调用函数

#source("D:/GitHub/vehicleGPS/GPS_R/GPS_function_ver0.4.R")
source("/home/zhwh/文档/Github/vehicleGPS/GPS_R/GPS_function_ver0.4.R")
#setwd("D:/PROdata/vehicle GPS/GPS")
# 导入初始化数据
#dataName = 'D:/PROdata/Data/dangerous good transport/sichuan-xcar-2016080810.csv'
dataName = '/home/zhwh/Data/sichuan-xcar-2016080810.csv'
#GpsData_initial =  read.xlsx(GpsData_initial  =  read_csv(dataName),sheetIndex = 1,header = F,encoding = "UTF-8")
#GpsData_initial  =  read_csv(dataName)
colname = c("vehicleID","longitude","latitude",
           "GPS_Speed","direction","elevation",
           "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)

# 生成一个vehicleID列表
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID
col = colors()   #调用R语言颜色空间
vehicleNum = 100  #vehicleNum是有效ID数据中速度大于零的最小数量
map_ab = data.frame()

for (i in 1:length(vehicleIDList))
{
  ID = vehicleIDList[i]
  GPSData = subset(GPSData_initial,vehicleID == ID)
  if(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed) > vehicleNum) #数据过少的不纳入计算
  {
    GPSData = singleDataINI(GPSData)
    GPSData_ab = funAbnormalData(GPSData,0.95)
    #增加颜色属性，使用随机函数随机选择颜色
    #Pointcol  =  round(runif(1,min=1,max=length(col)))
    #Pointcol  =  col[Pointcol]
    Pointcol  =  col[i]
    if(length(GPSData_ab$vehicleID)>0){GPSData_ab$col  =  Pointcol}
    if (i == 1) {map_ab  =  GPSData_ab}
    if (i > 1)  {map_ab  =  rbind(map_ab,GPSData_ab) }
  }
  print(i)
  print(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed))
  if(i>100){break()}
}

# =============================================================================
# 给定范围内的异常点的数量计算:
# 1.计算输入数据框中相对固定里程道路区间内的坐标点数量
# =============================================================================
vehicleID_ab = map_ab[!duplicated(map_ab$vehicleID),]$vehicleID
i = 1
temp = subset(map_ab,vehicleID == vehicleID_ab[i])
stepLen = 100

# 按照GPS时间对原始数据重新排序
temp = temp[order(temp$GpsTime),] 

temp_DAC = subset(temp,ACCabnormal == 'ay_DAC')

#增加相邻数据行之间的时间差
temp_DAC$GpsTime_diff = c(0,abs(diff(temp_DAC$GpsTime)))
temp_DAC = subset(temp_DAC,GpsTime_diff<=100)




kOut = kmeans(temp_DAC$GpsTime_diff,centers = 2,nstart = 20,iter.max = 20)
temp_DAC$cluster = kOut$cluster

a = subset(temp_DAC,select = c('GpsTime_diff','cluster'))



ggplot(temp_DAC,aes(longitude,latitude,colour=cluster))+
  geom_point(shape=16,size=3)+
  geom_text(hjust=1,vjust=1,alpha=0.5,label=(temp_DAC$GpsTime_diff))














