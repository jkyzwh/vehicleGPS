
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
