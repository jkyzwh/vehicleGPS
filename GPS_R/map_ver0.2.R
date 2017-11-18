
# 0. 加载使用的软件包---------------------------------------------------------------

library(ggplot2)
library(ggthemes)
library(ggmap)
library(REmap) #百度地图
library(leaflet) #R标准地图包
library(leafletCN)
library(baidumap)#百度地图包
options(baidumap.key = 'kvfrFNTcOQWVFUmhwqZhYzxxVj088NuW') #百度地图API访问key

library(leaflet)
library(stringr)
library(bitops)

# 1. 百度地图BD09坐标转换未高德地图的火星坐标---------------------------------------
bdToGaoDecoords = function(baiduData){
  #构造一个空数据框，共19列，行数量为驾驶人数量，列名为data_colnames
  col.names = c ('lon','lat')
  Gaode.coords = data.frame(matrix(0, ncol = length(col.names),nrow = length(baiduData$lon)))
  names(Gaode.coords) = col.names
  PI = pi * 3000.0 / 180.0
  baiduData$x = baiduData$lon-0.0065
  baiduData$y = baiduData$lat-0.006
  baiduData$z = sqrt(baiduData$x * baiduData$x + baiduData$y * baiduData$y) - 0.00002 * sin(baiduData$y * PI)
  baiduData$theta = atan2(baiduData$y, baiduData$x) - 0.000003 * cos(baiduData$x * PI)
  Gaode.coords$lon = baiduData$z * cos(baiduData$theta)
  Gaode.coords$lat = baiduData$z * sin(baiduData$theta)
  return(Gaode.coords)
}
# 1.1 测试百度地图坐标转换至高德火星坐标---------------------------------------------------
baiduData = getRoute('常州','常熟') 
GaodeData = bdToGaoDecoords (baiduData)
map = leaflet(GaodeData)
map = amap(map)  #使用高德地图
#map = addTiles(map)
map = addCircleMarkers(map,lng=~lon,lat=~lat,radius = ~2, color = ~'red' , fillOpacity = 0.5)
#map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = "red" , fillOpacity = 0.5)
print(map)




# 2. 将GPS坐标转换为高德火星坐标，主函数是GPSToGaoDecoords( GPSData)----------------------------
transformLon = function(x, y) {
  ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
  ret = ret + (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
  ret = ret + (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
  ret = ret + (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
  return (ret)
}

transformLat = function(x, y) {
  ret = (-100.0) + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 *sqrt(abs(x))
  ret = ret + (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
  ret = ret + (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
  ret = ret + (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0
  return (ret)
}

GPSToGaoDecoords = function( GPSData) {
  a = 6378245.0
  ee = 0.00669342162296594323
  colnames(GPSData) = c("vehicleID","lon","lat","GPS_Speed","direction","elevation","GpsTime" )
  GPSData$dLat = transformLat(GPSData$lon - 105.0, GPSData$lat - 35.0) 
  GPSData$dLon = transformLon(GPSData$lon - 105.0, GPSData$lat - 35.0) 
  GPSData$radLat = GPSData$lat / 180.0 * pi  
  GPSData$magic = sin(GPSData$radLat) 
  GPSData$magic = 1 - ee * GPSData$magic * GPSData$magic 
  GPSData$sqrtMagic = sqrt(GPSData$magic)  
  GPSData$dLat = (GPSData$dLat * 180.0) / ((a * (1 - ee)) / (GPSData$magic * GPSData$sqrtMagic) * pi)  
  GPSData$dLon = (GPSData$dLon * 180.0) / (a / GPSData$sqrtMagic * cos(GPSData$radLat) * pi) 
  GPSData$latitude = GPSData$lat + GPSData$dLat  
  GPSData$longitude = GPSData$lon + GPSData$dLon  
  return(subset(GPSData,select = c("vehicleID","longitude","latitude",
                                   "GPS_Speed","direction","elevation","GpsTime" )))
}

# 2.1 测试GPS坐标转换至高德火星坐标------------------------------------------------------------------
GPSData2 = GPSToGaoDecoords(GPSData)
map = leaflet(GPSData2)
map = amap(map)  #使用高德地图
map = addTiles(map)
map = addCircles(map,lng=~longitude,lat=~latitude,color = "red" , fillOpacity = 0.5) # 绘制圆点
map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = "red" , fillOpacity = 0.5) #绘制圆环点
map = addPolylines(map,lng=~longitude,lat=~latitude,color = "red" , fillOpacity = 0.5) #绘制路线
print(map)

# 3. 将高德火星坐标转换为百度BD09坐标----------------------------------------------------------------------

GaodeToBaidu = function(GaodeData) {
  x_pi = pi * 3000.0 / 180.0
  GaodeData$x = GaodeData$lon
  GaodeData$y = GaodeData$lat  
  GaodeData$z = sqrt(GaodeData$x * GaodeData$x + GaodeData$y * GaodeData$y) + 0.00002 * sin(GaodeData$y * x_pi)  
  GaodeData$theta = atan2(GaodeData$y, GaodeData$x) + 0.000003 * cos(GaodeData$x * x_pi) 
  GaodeData$longitude = GaodeData$z * cos(GaodeData$theta) + 0.0065  
  GaodeData$latitude = GaodeData$z * sin(GaodeData$theta) + 0.006
  return(subset(GaodeData,select = c("longitude","latitude")))
}

baiduData2 =  GaodeToBaidu(GaodeData)

# 4. 利用百度地图在静态地图上绘制路线的实例-------------------------------------------------------


bjMap = getBaiduMap('北京', color='color')
df = getRoute('首都国际机场', '北京南苑机场', region = '北京',tactics = 12)
ggmap(bjMap) + geom_path(data = df, aes(lon, lat), alpha = 0.5, col = 'red')

# 5. 利用百度地图获取GPS信息的地址和路径信息--------------------------------------------------
library(data.table)
dataName = 'D:/PROdata/Data/dangerous good transport/sichuan-xcar-2016080810.csv'
colname = c("vehicleID","longitude","latitude",
            "GPS_Speed","direction","elevation",
            "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)

# 生成一个vehicleID列表，存储关于每一个车辆ID的信息
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID

ID = vehicleIDList[sample(1:length(vehicleIDList), 1)] #随即抽样一个车辆数据
GPSData=subset(GPSData_initial,vehicleID == ID) #随机抽样一个GPS车辆数据
length(GPSData$vehicleID)

#利用百度地图获取起终点地名信息
len =length(GPSData$vehicleID)
begin = getLocation(c(GPSData$longitude[1],GPSData$latitude[1]), output = "json", formatted = F, pois = 0)
end = getLocation(c(GPSData$longitude[len],GPSData$latitude[len]), output = "json", formatted = F, pois = 0)
library(rjson)
begin = fromJSON(begin)$result$formatted_address
end = fromJSON(end)$result$formatted_address

# 5.1 利用百度地图获取起终点的百度地图路径信息，绘制高德地图--------------------------------------
baiduData = getRoute(begin,end, region = '四川',tactics = 12)

GaodeData = bdToGaoDecoords (baiduData) #百度地图坐标转换至火星坐标

map = leaflet(GaodeData)
map = amap(map)  #使用高德地图
map = addPolylines(map,lng=~lon,lat=~lat,color = "red" , fillOpacity = 0.5) #绘制路线
print(map)

# 5.2 利用原始GPS坐标绘制高德路径地图-----------------------------------------------------------------
map = leaflet(GPSData)
map = amap(map)  #使用高德地图
map = addPolylines(map,lng=~longitude,lat=~latitude,color = "red" , fillOpacity = 0.5) #绘制路线
print(map)

# 5.3 原始坐标转换为火星坐标，绘制高德地图---------------------------------------------------------
GPSData2 = GPSToGaoDecoords(GPSData)

map = leaflet(GPSData2)
map = amap(map)  #使用高德地图
map = addCircles(map,lng=~longitude,lat=~latitude,color = "red" , fillOpacity = 0.5) # 绘制圆点
#map = addPolylines(map,lng=~longitude,lat=~latitude,color = "red" , fillOpacity = 0.5) #绘制路线
print(map)

# 5.4 GPS坐标修正后的展示--------------------------------------------------------------------------------
GPSData2 = GPSToGaoDecoords(GPSData)
GPSData$longitude.gaode = GPSData2$longitude
GPSData$latitude.gaode = GPSData2$latitude
map = leaflet(GPSData)
map = amap(map)  #使用高德地图
map = addPolylines(map,lng=~longitude.gaode,lat=~latitude.gaode,color = "red" , fillOpacity = 0.5) #修正后
map = addPolylines(map,lng=~longitude,lat=~latitude,color = "blue" , fillOpacity = 0.5) #修正前
print(map)








