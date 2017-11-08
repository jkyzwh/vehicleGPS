

library(ggplot2)
library(ggthemes)
library(REmap) #百度地图
library(leaflet) #R标准地图包
library(leafletCN)
library(baidumap)#百度地图包
options(baidumap.key = 'kvfrFNTcOQWVFUmhwqZhYzxxVj088NuW') #百度地图API访问key

library(leaflet)
library(stringr)
library(bitops)

route = getRoute('常州','常熟')
map = leaflet(route)
map = amap(map)  #使用高德地图
#map = addTiles(map)
map = addCircleMarkers(map,lng=~lon,lat=~lat,radius = ~8, color = ~col , fillOpacity = 0.5)
#map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = "red" , fillOpacity = 0.5)
print(map)