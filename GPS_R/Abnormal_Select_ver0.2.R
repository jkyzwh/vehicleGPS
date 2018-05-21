# 说明：########################################################################
# 本程序用于分析两客一危GPS数据，提取运行帖子是那个
# 结合leaflet地图，绘制异常驾驶行为分布图
# 利用MDS或者其他方法，对驾驶人异常行为进行聚类分析
# ver0.5不包含利用地图绘制风险地图的内容
# Ver0.5着眼于基于驾驶行为的聚类分析
#library(devtools)
#install_github('badbye/baidumap')
#install_github('lchiffon/REmap')
#获取当前脚本所在的目录名称------------------------------------------------------------------

library(rstudioapi)    
file_dir = dirname(rstudioapi::getActiveDocumentContext()$path)

# 0. 加载需要的程序包--------------------------------------------------------------------------
library(data.table)
library(psych)
library(ggplot2)
library(dplyr)
library(stats)
library(MASS)
library(plyr)
library(lubridate)  #时间数据处理包
library(stringr)
library(readr)
library(ggplot2)
library(ggthemes)
#library(REmap) #百度地图
library(leaflet) #R标准地图包
library(leafletCN)
library(lattice) #调入函数包  
#library(ggmap)
#library(baidumap)#百度地图包
#options(baidumap.key = 'kvfrFNTcOQWVFUmhwqZhYzxxVj088NuW') #百度地图API访问key

# 0.1 调用函数以及定义常量-------------------------------------------------------------------------

source(paste(file_dir, "GPS_function_ver0.7.R",sep="/"))
setwd (paste(str_sub(file_dir,1,str_locate(file_dir,"vehicleGPS")[1]-1),'/Rdata',sep = ''))
col = colors()   #调用R语言颜色空间
#vehicleNum = 30  #vehicleNum是有效ID数据中速度大于零的最小数量

# 1.导入以及初始化数据--------------------------------------------------------------------------------
dataName = paste(str_sub(file_dir,1,str_locate(file_dir,"vehicleGPS")[1]-1),'data/sichuan-xcar-2016080810.csv',sep = '')
colname = c("vehicleID","longitude","latitude",
           "GPS_Speed","direction","elevation",
           "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)

# 生成一个vehicleID列表，存储关于每一个车辆ID的信息
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID
# 2. 筛选有效数据进行下一步计算------------------------------------------------------------------------
# 对数据按照车辆ID进行描述性统计
info = vehicleinfo(GPSData_initial)
print('筛选有效的数据')
# 筛选有效性较高的ID数据进行下一步分析
nonzero_Num = 100 #定义一个ID中包含的速度非零数据个数
timespace_Mode = 60 #定义允许的GPS数据间隔众数
# 选择满足要求的ID
effectiveID = subset(info,unzerospeedNum>=nonzero_Num & timespaceMode<=timespace_Mode)$ID

for(i in 1:length(effectiveID)){
  IDn = effectiveID[i]
  print(paste("i=",i))
  if(i == 1){
    effectiveData =  subset(GPSData_initial,vehicleID== IDn)
  }
  if( i>1){
    effectiveData =  rbind(effectiveData,subset(GPSData_initial,vehicleID== IDn))
  }
}

# 3. 利用筛选处的数据确定异常驾驶行为点的位置-----------------------------------------------------
map_ab = data.frame()
print('进行异常驾驶行为分析')
for (i in 1:length(effectiveID)){
  ID = effectiveID[i]
  GPSData = subset(effectiveData,vehicleID == ID)
  GPSData = singleDataINI(GPSData,10)
  GPSData_ab = funAbnormalData(GPSData,0.95)
  #增加颜色属性，使用随机函数随机选择颜色
  #Pointcol  =  round(runif(1,min=1,max=length(col)))
  #Pointcol  =  col[Pointcol]
  # Pointcol  =  col[i]
  #if(length(GPSData_ab$vehicleID)>0){GPSData_ab$col  =  Pointcol}
  if (i == 1) {map_ab  =  GPSData_ab}
  if (i > 1)  {map_ab  =  rbind(map_ab,GPSData_ab) }
  print( paste("i=",i))
  #print(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed))
  #if(i>500){break()}
}

map_ab = catch_Road(map_ab)

#4. 按道路名称进行数据筛选----------------------------------------------------------------------------

Roadname_List = map_ab[!duplicated(map_ab$roadname),]$roadname
# 寻找数据量做多的道路
colnames = c("roadname","dataNum","IDNum")
Roadinfo = data.frame(matrix(0, ncol = length(colnames),nrow = length(Roadname_List)))
names(Roadinfo) = colnames
print('统计每条道路数据数量')
for (i in 1:length(Roadname_List)){
  print(paste("i=1",i))
  IDn = Roadname_List[i]
  temp = subset(map_ab,roadname == IDn)
  Roadinfo$roadname[i] = IDn
  Roadinfo$dataNum[i] = length(temp$speed_split)
  Roadinfo$IDNum[i] =  length(temp[!duplicated(temp$vehicleID),]$speed_split)
}
Roadinfo = subset(Roadinfo,roadname != 'na')
Road_ab = subset(map_ab,roadname == Roadinfo$roadname[Roadinfo$dataNum == max(Roadinfo$dataNum)])
Road_ab$lon_gaode = as.numeric(Road_ab$lon_gaode)
Road_ab$lat_gaode = as.numeric(Road_ab$lat_gaode)


#####################################################################
#绘制异常行为点分布图
#####################################################################
#筛选出只包含经纬度信息的数据框,利用leaflet包绘制地图
GPSSite = subset(Road_ab,  ACCabnormal=="ay_DAC" |angleabnormal == "angle_directionRate" )
#GPSSite = GPSData
map = leaflet(GPSSite)
map = amap(map)  #使用高德地图
map = addTiles(map)
map = addCircles(map,lng=~lon_gaode,lat=~lat_gaode,radius = ~8, color = ~col , fillOpacity = 0.5)
#map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = "red" , fillOpacity = 0.5)
print(map)










