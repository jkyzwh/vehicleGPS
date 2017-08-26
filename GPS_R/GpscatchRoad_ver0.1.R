#####################################################
# 本程序用于调用高德API匹配道路信息
# 结合地图，绘制运行图
#####################################################

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
library(ggplot2)
library(rjson)
library(RCurl)
library(httr)

source("D:/PROdata/vehicle GPS/GPS/GPS_function_ver0.4.R")
setwd("D:/PROdata/vehicle GPS/GPS")
# 导入初始化数据
dataName = 'D:/PROdata/Data/dangerous good transport/sichuan-xcar-2016080810.csv'
colname = c("vehicleID","longitude","latitude",
           "GPS_Speed","direction","elevation",
           "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID
vehicleNum = 100  #vehicleNum是有效ID数据中速度大于零的最小数量

map_ab = data.frame()
for (i in 1:length(vehicleIDList))
{
  ID = vehicleIDList[i]
  GPSData = subset(GPSData_initial,vehicleID == ID)
  if(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed) > vehicleNum) #数据过少的不纳入计算
  {
    GPSData = singleDataINI(GPSData)
    if (i == 1) {map_ab  =  GPSData}
    if (i > 1)  {map_ab  =  rbind(map_ab,GPSData) }
  }
  print(i)
  if(i>10){break()}
}


######################################################################
#抓取高德地图的道路坐标信息
#####################################################################
begin = "http://restapi.amap.com/v3/autograsp?"
carid = paste("carid=",'7d1a',as.character(GPSData$vehicleID[1]),sep = "")
output = "&output=json"
key = "&key=0db8f3c425720344c18169820cc77d1a"


vehicleID = GPSData$vehicleID[1]

for(i in 1:(length(GPSData$vehicleID)-2))
{
  time1 = GPSData$GpsTime_UTC[i];time2 = GPSData$GpsTime_UTC[i+1];time3 = GPSData$GpsTime_UTC[i+2]
  time = paste(time1,time2,time3,sep = ',')
  time = paste("&time=",time,sep = '')
  drc1 = GPSData$direction[i];drc2 = GPSData$direction[i+1];drc3 = GPSData$direction[i+2];
  direction = paste(drc1,drc2,drc3,sep = ',')
  direction = paste("&direction=",direction,sep = '')
  
  speed1 = GPSData$GPS_Speed[i];speed2 = GPSData$GPS_Speed[i+1];speed3 = GPSData$GPS_Speed[i+1];
  speed = paste(speed1,speed2,speed3,sep = ',')
  speed = paste("&speed=",speed,sep = '')
  
  lat1 = GPSData$latitude[i];lat2 = GPSData$latitude[i+1];lat3 = GPSData$latitude[i+2];
  long1 = GPSData$longitude[i];long2 = GPSData$longitude[i+1];long3 = GPSData$longitude[i+1];
  location1 = paste(long1,lat1,sep = ',')
  location2 = paste(long2,lat2,sep = ',')
  location3 = paste(long3,lat3,sep = ',')
  location = paste(location1,location2,location3,sep = '|')
  location = paste("&locations=",location,sep = '')
  url = paste(begin,carid,location,time,direction,speed,output,key,sep = "")
  connect  =  getURL(url,.encoding="utf-8")
  print('i=');print(i)
  if(i==1){a = c(i,connect)}
  if(i>1){a= rbind(a,c(i,connect))}
}
###############################################
# 利用全部数据抓取道路坐标尝试
##############################################
begin = "http://restapi.amap.com/v3/autograsp?"
carid = paste("carid=",'7d1a',as.character(GPSData$vehicleID[1]),sep = "")
output = "&output=json"
key = "&key=0db8f3c425720344c18169820cc77d1a"

# 处理时间字符串
for(i in 1:length(GPSData$GpsTime_UTC))
{
  GPStime = as.character(GPSData$GpsTime_UTC[i])
  if(i==1){
    time = GPStime}
  else{
    time = paste(time,GPStime,sep=",")}
}
time = paste("&time=",time,sep = '')

# 处理方位角字符串
for(i in 1:length(GPSData$direction))
{
  Direction = as.character(GPSData$direction[i])
  if(i==1){
    direction = Direction}
  else{
    direction = paste(direction,Direction,sep=",")}
}
direction = paste("&direction=",direction,sep = '')

# 处理速度字符串
for(i in 1:length(GPSData$GPS_Speed))
{
  Speed = as.character(GPSData$GPS_Speed[i])
  if(i==1){
    speed = Speed}
  else{
    speed = paste(speed,Speed,sep=",")}
}
speed = paste("&speed=",speed,sep = '')

# 处理经纬度location字符串
for(i in 1:length(GPSData$latitude))
{
  lat = as.character(GPSData$latitude[i]); long = as.character(GPSData$longitude[i])
  Location = paste(long,lat,sep = ',')
  if(i==1){
    location = Location}
  else{
    location = paste(location,Location,sep = '|')}
}
location = paste("&locations=",location,sep = '')


url = paste(begin,carid,location,time,direction,speed,output,key,sep = "")
connect  =  getURL(url,.encoding="utf-8")
amap  =  fromJSON(connect)

############################################################









begin = "http://restapi.amap.com/v3/autograsp?"
carid = "carid=3cf7807acf6ac09f"
location = "&locations=104.0613,29.63833|104.0610,29.63632|104.0613,29.63650"
time = "&time=1470621608,1470621638,1470621668"
direction =  "&direction=171,241,1"
speed = "&speed=36,3,18"
output = "&output=json"
key = "&key=0db8f3c425720344c18169820cc77d1a"

url = paste(begin,carid,location,time,direction,speed,output,key,sep = "")
connect  =  getURL(url,.encoding="utf-8")

# 利用高德地图API抓取所在道路信息，返回值为json格式数据

Amap_getRoad  =  function(url)
{
  msg.load  =  tryCatch(
  {
    #connect  =  getURL(url,httpheader=myheader,.encoding="utf-8")
    connect  =  getURL(url,.encoding="utf-8")
    amap  =  fromJSON(connect)
    msg.load  =  "TRUE"
  }, error = function(e) {"error"}
  )
  if(msg.load=='error'){
    Sys.sleep(runif(1,2,5))
    msg.load  =  tryCatch({
      amap  =  content(GET(url,add_headers(myheader)))
      msg.load  =  "TRUE"
    }, error = function(e) {
      "error"
    }
    )
  }
  return(amap)
}

a1 = Amap_getRoad(url1)
json_data_frame  =  as.data.frame(a)

print(a)
aa = c("104.0613,29.63833","104.0610,29.63632","104.0613,29.63650")
b = c(a$roads[[1]]$crosspoint,a$roads[[2]]$crosspoint,a$roads[[3]]$crosspoint)

latitude = c(29.63833,29.63632,29.63650,29.638342,29.636364,29.636591)
longitude = c(104.0613,104.0610,104.0613,104.06124,104.06076,104.060814)
col = c("red","red","red","black","black","black")
X1 = data.frame(latitude,longitude,col)

map = leaflet(X1)
map = amap(map)  #使用高德地图
map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = ~col , fillOpacity = 0.5)
print(map)


















