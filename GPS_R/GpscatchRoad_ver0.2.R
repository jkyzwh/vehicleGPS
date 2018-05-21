#####################################################
# 本程序用于调用高德API匹配道路信息
# 结合地图，绘制运行图
#####################################################
# install yesterday's version of checkpoint, by date
#packageurl <- "https://mran.microsoft.com/snapshot/2017-07-30/bin/windows/contrib/3.4/dplyr_0.7.2.zip"
#packageurl <- "https://mran.microsoft.com/snapshot/2017-07-30/bin/windows/contrib/3.4/readr_1.1.1.zip"
#install.packages(packageurl, repos=NULL, type="source")
#require(devtools)
#install_version("dplyr", version = "0.7.3", repos = "http://cran.us.r-project.org")
#install_version("readr", version = "1.1.0", repos = "http://cran.us.r-project.org")


# 0. 加载需要的程序包------------
library(data.table)
library(psych)
library(ggplot2)
library(dplyr)
library(stats)
library(plyr)
library(lubridate)  #时间数据处理包
library(stringr)
library(readr)
library(rjson)
library(RCurl)
library(httr)

source("D:/GitHub/vehicleGPS/GPS_R/GPS_function_ver0.6.R")
setwd("D:/PROdata/vehicle GPS/GPS")
# 导入初始化数据
dataName = 'D:/PROdata/Data/dangerous good transport/sichuan-xcar-2016080810.csv'
colname = c("vehicleID","longitude","latitude",
           "GPS_Speed","direction","elevation",
           "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID
#vehicleNum = 100  #vehicleNum是有效ID数据中速度大于零的最小数量

# 生成一个vehicleID列表，存储关于每一个车辆ID的信息
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID

ID = vehicleIDList[sample(1:length(vehicleIDList), 1)] #随即抽样一个车辆数据
GPSData = subset(GPSData_initial,vehicleID == ID) #随机抽样一个GPS车辆数据
#GPSData = GPSToGaoDecoords(GPSData)
GPSData = singleDataINI(GPSData)
length(GPSData$vehicleID)
length(subset(GPSData,GPS_Speed > 0)$vehicleID)

######################################################################
#抓取高德地图的道路坐标信息
#http://restapi.amap.com/v3/autograsp?carid=abcd123456&locations=116.496167,39.917066|116.496149,39.917205|116.496149,39.917326&time=1434077500,1434077501,1434077510&direction=1,1,2&speed=1,1,2&output=xml&key=0db8f3c425720344c18169820cc77d1a
#####################################################################
catch_Road = function(data){
  begin = "http://restapi.amap.com/v3/autograsp?"
  carid = paste("&carid=",'7458',as.character(data$vehicleID[1]),sep = "")
  output = "&output=json"
  key = "&key=2aaa2fd1515f77aa9a6061a202737458"
  data$roadname = "na"
  data$roadlevel = 0
  data$speedlimit = 0
  data$lon_gaode = 'na'
  data$lat_gaode = ''
  
  for(i in 1:(length(data$vehicleID)-2))  {
    time1 = data$GpsTime_UTC[i];time2 = data$GpsTime_UTC[i+1];time3 = data$GpsTime_UTC[i+2]
    time = paste(time1,time2,time3,sep = ',')
    time = paste("&time=",time,sep = '')
    drc1 = data$direction[i];drc2 = data$direction[i+1];drc3 = data$direction[i+2];
    direction = paste(drc1,drc2,drc3,sep = ',')
    direction = paste("&direction=",direction,sep = '')
    
    speed1 = data$GPS_Speed[i];speed2 = data$GPS_Speed[i+1];speed3 = data$GPS_Speed[i+2];
    speed = paste(speed1,speed2,speed3,sep = ',')
    speed = paste("&speed=",speed,sep = '')
    
    lat1 = data$latitude[i];lat2 = data$latitude[i+1];lat3 = data$latitude[i+2];
    long1 = data$longitude[i];long2 = data$longitude[i+1];long3 = data$longitude[i+2];
    location1 = paste(long1,lat1,sep = ',')
    location2 = paste(long2,lat2,sep = ',')
    location3 = paste(long3,lat3,sep = ',')
    location = paste(location1,location2,location3,sep = '|')
    location = paste("&locations=",location,sep = '')
    url = paste(begin,key,carid,location,time,direction,speed,output,sep = "")
    connect  =  getURL(url,.encoding="utf-8")
    x  =  fromJSON(connect)
    x1 =  x$roads
    print(paste('i=',i))
    if( length(x1)>0){
      x11 = x1[[1]]
      if ( length(x11$roadname)>0){
        data$roadname[i] = x11$roadname; data$roadlevel[i] = x11$roadlevel; data$speedlimit[i] = x11$maxspeed
        a1 = x11$crosspoint;l1 = str_locate(a1,",")
        data$lon_gaode[i] = str_sub(a1,1,l1[1]-1);  data$lat_gaode[i] = str_sub(a1,l1[1]+1,str_length(a1))
      }
      x12 = x1[[2]]
      if ( length(x12$roadname)>0){
        data$roadname[i+1] = x12$roadname;  data$roadlevel[i+1] = x12$roadlevel;  data$speedlimit[i+1] = x12$maxspeed
        a2 = x12$crosspoint;  l2 = str_locate(a2,",")
        data$lon_gaode[i+1] = str_sub(a2,1,l2[1]-1);data$lat_gaode[i+1] = str_sub(a2,l2[1]+1,str_length(a2))
      }
      x13 = x1[[3]]
      if ( length(x13$roadname)>0){
        data$roadname[i+2] = x13$roadname;  data$roadlevel[i+2] = x13$roadlevel;  data$speedlimit[i+2] = x13$maxspeed
        a3 = x13$crosspoint;  l3 = str_locate(a3,",")
        data$lon_gaode[i+2] = str_sub(a3,1,l3[1]-1);data$lat_gaode[i+2] = str_sub(a3,l3[1]+1,str_length(a3))
      }
    }
    
  }
  return(data)
}

GPSData = catch_Road(GPSData)








