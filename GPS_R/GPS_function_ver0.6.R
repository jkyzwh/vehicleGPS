# 0. 导入需要的package-----------------------------------------------------

library(plyr)
library(lubridate)
library(zoo)

# 1. 高精度计算两个经纬度之间的距离-----------------------------------------
# 经度一致时，得到的是水平方向相对坐标；纬度一致时得到的是垂直方向相对坐标

library(plyr)
library(lubridate)

hageodist  = function(L1, phi1, L2, phi2) #只考虑地球半径，假设地球是个球体
  {
    a = 6378.14
    f = 1/298.257
    F = (phi1+phi2)/2
    G = (phi1 - phi2)/2
    ramda  =  (L1 - L2)/2
    S = (sin(G*pi/180)^2)*(cos(ramda*pi/180)^2) + (cos(F*pi/180)^2)*(sin(ramda*pi/180)^2)
    C= (cos(G*pi/180)^2)*(cos(ramda*pi/180)^2) + (sin(F*pi/180)^2)*(sin(ramda*pi/180)^2)
    omega = atan(sqrt(S/C))
    R = sqrt(S*C)/omega
    D = 2*omega*a
    H1 = (3*R-1)/(2*C)
    H2 = (3*R+1)/(2*S)
    res = D*(1 + f*H1*(sin(F*pi/180)^2)*(cos(G*pi/180)^2) - f*H2*(cos(F*pi/180)^2)*(sin(G*pi/180)^2))
    return(round(res,3))
  }

calcDistance = function(Lat_A, Lng_A, Lat_B, Lng_B) #考虑赤道与两极半径不同，地球是个椭球体
{
  ra  =  6378.140  # 赤道半径 (km)
  rb  =  6356.755  # 极半径 (km)
  flatten  =  (ra - rb) / ra  # 地球扁率
  rad_lat_A  =  Lat_A * pi/180
  rad_lng_A  =  Lng_A * pi/180
  rad_lat_B  =  Lat_B * pi/180
  rad_lng_B  =  Lng_B * pi/180
  pA  =  atan(rb / ra * tan(rad_lat_A))
  pB  =  atan(rb / ra * tan(rad_lat_B))
  ss = sin(pA) * sin(pB) + cos(pA) * cos(pB) * cos(rad_lng_A - rad_lng_B)
  if (ss>=1) {ss = 1}
  if (ss<=(-1)){ss = -1}
  xx  =  acos(ss)
  c1  =  (sin(xx) - xx) * (sin(pA) + sin(pB)) ** 2 / cos(xx / 2) ** 2
  if (sin(xx/2) == 0)  {
    c2 = 0
  }else{
    c2  =  (sin(xx) + xx) * (sin(pA) - sin(pB)) ** 2 / sin(xx / 2) ** 2
    }
  dr  =  flatten / 8 * (c1 - c2)
  distance  =  ra * (xx + dr)
  return (distance)
}

# 2. 导入的两客一危数据初始化处理 singleDataINI---------------
# 函数功能
# 本函数仅针对单一ID数据的初始化工作
# 1. 补全时间字符串的秒
# 2. GPS信号缺失路段数据速度插值
# 3. 提取时间信息，将所有数据从起始位置开始按秒排序
# 4. 计算各位置相对起始位置的距离坐标
# 5. 计算加速度
# 6. 计算坡度

singleDataINI = function(GPSData,speedStep=10)
{
  # 删除重复的数据
  GPSData = GPSData[!duplicated(GPSData$GpsTime),]
  # 将时间列转化为时间类型
  GPSData$GpsTime  =  as.POSIXlt(GPSData$GpsTime)
  GPSData$GpsTime_UTC = as.numeric(GPSData$GpsTime)
  # 按照GPS时间对原始数据重新排序
  GPSData = GPSData[order(GPSData$GpsTime),] 
  #增加相邻数据行之间的时间差
  GPSData$GpsTime_diff = c(0,abs(diff(GPSData$GpsTime_UTC )))
  
  # 利用插值法处理GPS无信号导致的经纬度和速度值为零
  GPSData$GPSsignal = "GPSsignal_OK"
  #当存在零值时进行三次样条插值
  if( length( subset( GPSData,longitude==0)$longitude) >0)  {
    for(i in 1:length(GPSData$vehicleID))  {
      if(GPSData$longitude[i]==0){
        GPSData$GPSsignal[i] = "GPSsignal_No"
        }
    }
    # 利用zoo包的na.spline()函数，进行三次样条插值
    GPSData$longitude = na.spline(GPSData$longitude)
    GPSData$latitude = na.spline(GPSData$latitude)
  }
  
  #计算相对于起点的距离坐标 Lat_A, Lng_A, Lat_B, Lng_B
  begin_longitude = GPSData$longitude[1]
  begin_latitude = GPSData$latitude[1]
  for (i in 1:length(GPSData$vehicleID)){
    GPSData$coords_y[i] = calcDistance(begin_latitude,begin_longitude,begin_latitude,GPSData$longitude[i])*1000
    GPSData$coords_x[i] = calcDistance(begin_latitude,begin_longitude,GPSData$latitude[i],begin_longitude)*1000 
  }
  GPSData$SpeedChange = c(0,diff(GPSData$GPS_Speed))  #速度变化
  GPSData$Acc = GPSData$SpeedChange/GPSData$GpsTime_diff   #加速度
  GPSData$speed_split = GPSData$GPS_Speed%/%speedStep+1           #速度分组
  #计算相邻两数据之间的间距
  GPSData$spacing = 0 #两数据行之间行驶距离 Lat_A, Lng_A, Lat_B, Lng_B
  for (i in 1:length(GPSData$vehicleID)){
    if(i>1) {
      Lng_A = GPSData$longitude[i-1]
      Lat_A = GPSData$latitude[i-1]
      Lng_B = GPSData$longitude[i]
      Lat_B = GPSData$latitude[i]
      GPSData$spacing[i] = calcDistance(Lat_A, Lng_A, Lat_B, Lng_B)*1000 #计算相邻点之间的距离
      if(is.nan(GPSData$spacing[i])) {GPSData$spacing[i] = 0}
    }
  }
  GPSData$angleChange = c(0,diff(GPSData$direction))  #方位角变化
  GPSData$angleChangeRate = abs(GPSData$angleChange/GPSData$spacing) #方位角相对行驶距离变化率
  #清除Nan数值
  GPSData$spacing[is.nan(GPSData$spacing)] = 0
  GPSData$Acc[is.nan(GPSData$Acc)] = 0
  GPSData$coords_x[is.nan(GPSData$coords_x)]  = 0
  GPSData$coords_y[is.nan(GPSData$coords_y)]  = 0
  GPSData$angleChangeRate[is.nan(GPSData$angleChangeRate)]  = 0
  # 利用library(lubridate)包的函数提取日期和时间
  GPSData$year = year( GPSData$GpsTime)
  GPSData$month = month( GPSData$GpsTime)
  GPSData$day = day( GPSData$GpsTime)
  GPSData$hour = hour( GPSData$GpsTime)
  GPSData$weekDay = lubridate::wday(GPSData$GpsTime,label = TRUE)
  return(GPSData)
}

#3.1 定义函数fun_abnormalACC函数，计算加速和减速异常值标准-----------------------
fun_abnormalACC = function(data,probs=0.95)
{
  AAC = subset(data,Acc>0)
  DAC = subset(data,Acc<0)
  b1 = subset(AAC,select = c("speed_split","Acc"))
  b1 = ddply(b1,.(speed_split),numcolwise(quantile),probs=c(probs),na.rm = TRUE)
  b2 = subset(DAC,select = c("speed_split","Acc"))
  b2 = ddply(abs(b2),.(speed_split),numcolwise(quantile),probs=c(probs),na.rm = TRUE)
  names(b1) = c("speed_split","ay_abnormalAAC")
  names(b2) = c("speed_split","ay_abnormalDAC")
  c = merge(b1,b2,all=T)
  c$speed_bottom = (c$speed_split-1)*10
  c$speed_top = c$speed_split*10
  return(c)
}

#3.2 定义函数fun_abnormalDirection函数，计算方位角变化率异常值标准-----------------------
fun_abnormalDirection = function(data,probs=0.95)
{
  angleChange = subset(data,angleChangeRate>0)
  a = subset(angleChange,select = c("speed_split","angleChangeRate"))
  a = ddply(a,.(speed_split),numcolwise(quantile),probs=c(probs),na.rm = TRUE)
  names(a) = c("speed_split","angle_abnormalStandard")
  a$speed_bottom = (a$speed_split-1)*10
  a$speed_top = a$speed_split*10
  return(a)
}

#4. 生成加减速异常驾驶行为点计算
ACCab_type  =  function(x,y,z)
{
  ab = "normal"
  if(x>0 & x>y){ab = "ay_AAC"}
  if(x<0 & x<z){ab = "ay_DAC"}
  return(ab)
}

Angelab_type = function(x,y)
{
  ab = "normal"
  if(x>0 & x>y){ab = "angle_directionRate"}
  return(ab)
}

funAbnormalData = function(GPSData,probs = 0.95)
{
  #定义因子类型变量，区分异常驾驶行为状态,初始值为normal
  GPSData$ACCabnormal = "normal"
  #计算异常加速与减速标准
  accStandard = fun_abnormalACC(GPSData,probs)
  accStandard$ay_abnormalDAC = (0-accStandard$ay_abnormalDAC)
  #计算方位角变化率异常标准
  angleStandard = fun_abnormalDirection(GPSData,probs)
  #加减速异常行为的筛选
  SDacc = subset(accStandard,select = c("speed_split","ay_abnormalAAC"))
  SDdac = subset(accStandard,select = c("speed_split","ay_abnormalDAC"))
  GPSData = merge(GPSData,SDacc,by="speed_split",all = T,sort = F)
  GPSData = merge(GPSData,SDdac,by="speed_split",all = T,sort = F)
  #利用mapply函数筛选加减速异常值
  GPSData$ACCabnormal = mapply(ACCab_type,GPSData$Acc,GPSData$ay_abnormalAAC,GPSData$ay_abnormalDAC,SIMPLIFY = F)
  # 方位角变化异常筛选
  Sangle = subset(angleStandard,select = c("speed_split","angle_abnormalStandard"))
  GPSData = merge(GPSData,Sangle,by="speed_split",all = T,sort = F)
  GPSData$angleabnormal = "normal"
  GPSData$angleabnormal = mapply(Angelab_type,GPSData$angleChangeRate,GPSData$angle_abnormalStandard,SIMPLIFY = F)
  #筛选异常行为数据
  GPSData_ab<-subset(GPSData,ACCabnormal!="normal" | angleabnormal!="normal")
  #对异常行为点重新按时间排序，计算相邻距离，以及相邻的时间，用做聚类分析
  GPSData_ab = GPSData_ab[order(GPSData_ab$GpsTime),] #按时间顺序排序
  # 重新计算两个异常点之间的间距
  for (i in 1:length(GPSData_ab$GpsTime))
  {
    if(i>1)
    {
      Lng_A = GPSData_ab$longitude[i-1]
      Lat_A = GPSData_ab$latitude[i-1]
      Lng_B = GPSData_ab$longitude[i]
      Lat_B = GPSData_ab$latitude[i]
      GPSData_ab$spacing[i] = calcDistance(Lat_A,Lng_A,Lat_B, Lng_B) #计算相邻点之间的距离
      if(is.nan(GPSData_ab$spacing[i])) {GPSData_ab$spacing[i] = 0}
    }
  }
  GPSData_ab$spacing = GPSData_ab$spacing*1000 #将两点之间距离换算为以m为单位
  return(GPSData_ab)
}

