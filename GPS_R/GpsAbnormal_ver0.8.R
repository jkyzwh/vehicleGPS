# 说明：########################################################################
# 本程序用于分析两客一危GPS数据，提取运行帖子是那个
# 结合leaflet地图，绘制异常驾驶行为分布图
# 利用MDS或者其他方法，对驾驶人异常行为进行聚类分析
# ver0.5不包含利用地图绘制风险地图的内容
# Ver0.5着眼于基于驾驶行为的聚类分析
#library(devtools)
#install_github('badbye/baidumap')
#install_github('lchiffon/REmap')

# 0. 加载需要的程序包------------
library(data.table)
library(psych)
library(ggplot2)
library(dplyr)
library(stats)
library(MASS)
library(plyr)
library(lubridate)  #时间数据处理包
library(stringr)
#library(xlsx)  #  导入excel文件
library(readr)
library(ggplot2)
library(ggthemes)
#library(REmap) #百度地图
library(leaflet) #R标准地图包
library(leafletCN)
library(lattice) #调入函数包  
library(nnet)  
library(mice) #前三个包是mice的基础  
#library(ggmap)
#library(baidumap)#百度地图包
#options(baidumap.key = 'kvfrFNTcOQWVFUmhwqZhYzxxVj088NuW') #百度地图API访问key

# 0.1 调用函数以及定义常量-------------------------------------------------------------------------

source("D:/GitHub/vehicleGPS/GPS_R/GPS_function_ver0.6.R")
setwd ("D:/PROdata/vehicle GPS/GPS")
col = colors()   #调用R语言颜色空间
vehicleNum = 30  #vehicleNum是有效ID数据中速度大于零的最小数量

# 1.导入以及初始化数据--------------------------------------------------------------------------------
dataName = 'D:/PROdata/Data/dangerous good transport/sichuan-xcar-2016080810.csv'
colname = c("vehicleID","longitude","latitude",
           "GPS_Speed","direction","elevation",
           "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)

# 生成一个vehicleID列表，存储关于每一个车辆ID的信息
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID

map_ab = data.frame()

for (i in 1:length(vehicleIDList))
{
  ID = vehicleIDList[i]
  GPSData = subset(GPSData_initial,vehicleID == ID)
  if(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed) > vehicleNum) #数据过少的不纳入计算
  {
    GPSData = singleDataINI(GPSData,speedStep = 10)
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
  #print(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed))
  if(i>1000){break()}
}

#####################################################################
#绘制异常行为点分布图
#####################################################################
#筛选出只包含经纬度信息的数据框,利用leaflet包绘制地图
GPSSite = subset(map_ab,  ACCabnormal=="ay_DAC" |angleabnormal == "angle_directionRate" )
#GPSSite = GPSData
map = leaflet(GPSSite)
map = amap(map)  #使用高德地图
#map = addTiles(map)
map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = ~col , fillOpacity = 0.5)
#map = addCircleMarkers(map,lng=~longitude,lat=~latitude,radius = ~8, color = "red" , fillOpacity = 0.5)
print(map)


######################################################################
#利用mds方法，对驾驶人异常行为标准进行聚类分析
#####################################################################

#构造一个空数据框，共9列，行数量为驾驶人数量，列名为data_colnames
#使用异常行为识别函数，对减加速度进行聚类分析
vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID
vehicleIDList = vehicleIDList[c(1:500)] #测试用，筛选车辆ID的一部分

MDS_colnames = c("ID","Acc_23","Acc_34","Acc_45","Acc_56","Acc_67","Acc_78",
                   "Dac_23","Dac_34","Dac_45","Dac_56","Dac_67","Dac_78")

#mdsData = data.frame(matrix(0, ncol = length(MDS_colnames),nrow = length(vehicleIDList)))
mdsData = data.frame(matrix(0, ncol = length(MDS_colnames),nrow = 0))
names(mdsData) = MDS_colnames
#mdsData$ID = vehicleIDList

#生成驾驶人特征数据框，行为驾驶人ID，列为特征项
quant = 0.85 #日常特征，取85位
for (i in 1:length(vehicleIDList))
{
  ID = vehicleIDList[i]
  GPSData = subset(GPSData_initial,vehicleID == ID)
  if(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed) > vehicleNum) #数据过少的不纳入计算
  {
    GPSData = singleDataINI(GPSData)
    abnormalStandard = fun_abnormalACC(GPSData,quant)
    Stdlen = length(abnormalStandard$speed_split)
    if(Stdlen>8){Stdlen = 8}
    if(Stdlen>2)
    {
      temp = data.frame(matrix(0, ncol = length(MDS_colnames),nrow = 0))
      names(temp) = MDS_colnames
      temp[1,c(2:(Stdlen -1))] = abnormalStandard$ay_abnormalAAC[c(3:Stdlen)]
      temp[1,c(8:(Stdlen +5))] = abnormalStandard$ay_abnormalDAC[c(3:Stdlen)]
      temp$ID = i
      mdsData = rbind(mdsData,temp)
    }
  }
    
  print(i)
  print(length(subset(GPSData,GPS_Speed > 0)$GPS_Speed))
}
rm(temp,abnormalStandard,Stdlen)

# 将明显大于加速度可能值的异常数据提出
aymax = 6.0 #根据经验指定的最大加速度值
order <- c()
for(i in 1:length(mdsData$ID))
{
  if(i==1)
  {
    k=1
    order[1]=1
  }
  else if(max(mdsData[i,c(2:13)],na.rm=TRUE) < aymax)
  {k=k+1
  order[k]=i
  }      
}
mdsData = mdsData[order,]

# 处理NA值
# 利用mice包的函数，利用线形预测模型填充NA值

imp=mice(mdsData,m=4,meth = 'norm.predict') #4重插补，即生成4个无缺失数据集  
mdsData = complete(imp)


#绘制加速度标准统计图
mdsDataT = data.frame(t(as.matrix(mdsData)))
mdsDataT = mdsDataT[c(2:7),]
mdsDataT$speed = seq(20,70,10)
for (i in 1:(length(mdsDataT)-2)) 
{
  X = mdsDataT$speed
  Y = mdsDataT[,i]
  tempData = data.frame(X,Y)
  tempData$ID = i
  if (i==1)
  {
    plotData = tempData
  }
  else
  {
    plotData = rbind(plotData,tempData)
  }
  print(i)
}
rm(tempData,X,Y,i,imp)

ggplot(plotData,aes(X,Y,colour=ID,group=ID))+
  geom_point(size=1.0)+
  stat_smooth(method="lm")+
  ylim(0,6)+
  theme_bw()

#+facet_wrap(~ID)
  
#绘制减加速度图示
mdsDataT = data.frame(t(as.matrix(mdsData)))
mdsDataT = mdsDataT[c(8:13),]
mdsDataT$speed = seq(20,70,10)
for (i in 1:(length(mdsDataT)-2)) 
{
  X = mdsDataT$speed
  Y = mdsDataT[,i]
  tempData = data.frame(X,Y)
  tempData$ID = i
  if (i==1)
  {
    plotData = tempData
  }
  else
  {
    plotData = rbind(plotData,tempData)
  }
  print(i)
}
rm(tempData,X,Y,i)

ggplot(plotData,aes(X,Y,colour=ID,group=ID))+
  geom_point(size=1.0)+
  stat_smooth(method="lm")+
  ylim(0,10)+
  theme_bw()
#+facet_wrap(~ID)

rm(mdsDataT,plotData)
#利用多维定标方法进行聚类分析
mdsID = mdsData$ID
mdsData = mdsData[,c(-1)]
mds_data.matrix<-as.matrix(mdsData) #将驾驶人特征数据框转化为矩阵

#ID_dist<-mds_data.matrix %*% t(mds_data.matrix) #采用矩阵相乘的方式
ID_dist<-(mds_data.matrix)  #不采用矩阵相乘的方式
ID_dist<-dist(ID_dist,method="euclidean" ) #计算欧式距离
ID_MDS<-cmdscale(ID_dist,k=2,eig=T) #采用标准MDS分析
#ID_MDS<-isoMDS(ID_dist) #非参数iso分析


#这是为了检测能否用两个维度的距离来表示高维空间中距离，如果达到了0.8左右则表示是合适的。
paste('两个维度的距离来表示高维空间中距离的比例为',sum(abs(ID_MDS$eig[1:2]))/sum(abs(ID_MDS$eig)))
paste('两个维度的距离来表示高维空间中距离的比例平方为',sum((ID_MDS$eig[1:2])^2)/sum((ID_MDS$eig)^2))

#利用ggplot2输出可视化的MDS分析结果
library(ggrepel)
x<-ID_MDS$points[,1]
y<-ID_MDS$points[,2]
z = mdsID
ggplot(data.frame(x,y,z),aes(x,y))+
  geom_point(shape=16,size=3,colour=z)+
  geom_text(hjust=0.1,vjust=0.5,alpha=0.5,label=z)
  #+geom_text_repel(alpha=0.5,label=z) #避免文字标签遮挡

IDdist = data.frame(x,y)

#利用均值聚类，区分不同类别驾驶员
model2=kmeans(IDdist,centers=4,nstart=10)
IDdist$ID = mdsID
IDdist$IDkmean = model2$cluster

ggplot(IDdist,aes(x,y,colour=IDkmean))+
  geom_point(shape=16,size=3)+
  geom_text(hjust=0.1,vjust=0.5,alpha=0.5,label=z)







