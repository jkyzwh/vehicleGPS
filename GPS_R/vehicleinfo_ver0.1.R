# 计算序列的众数---------------------------------------------------------------------------------
getmode = function(v) {
  uniqv = unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

#按照车辆ID汇总数据集特征------------------------------------------------------------------------
vehicleinfo = function(GPSData_initial){
  # 生成一个vehicleID列表，存储关于每一个车辆ID的信息
  vehicleIDList = GPSData_initial[!duplicated(GPSData_initial$vehicleID),]$vehicleID
  colnames = c("ID","AlldataNum","unzerospeedNum",
               "speed_min","speed_max",
               "begintime","endtime","timeAll", "drivingtime",
               "timespaceMax","timespaceMode","roadNum","distance")
  info = data.frame(matrix(0, ncol = length(colnames),nrow = length(vehicleIDList)))
  names(info) = colnames
  for(i in 1:length(info$ID)){
    print(paste("i=",i))
    ID = vehicleIDList[i]
    GPSData = subset(GPSData_initial,vehicleID == ID)
    # 将时间列转化为时间类型
    GPSData$GpsTime  =  as.POSIXlt(GPSData$GpsTime)
    GPSData$GpsTime_UTC = as.numeric(GPSData$GpsTime)
    # 按照GPS时间对原始数据重新排序
    GPSData = GPSData[order(GPSData$GpsTime),] 
    #增加相邻数据行之间的时间差
    GPSData$GpsTime_diff = c(0,abs(diff(GPSData$GpsTime_UTC )))
    #计算相邻两数据之间的间距
    GPSData$spacing = 0 #两数据行之间行驶距离 Lat_A, Lng_A, Lat_B, Lng_B
    for (j in 1:length(GPSData$vehicleID)){
      if(j>1) {
        Lng_A = GPSData$longitude[j-1]
        Lat_A = GPSData$latitude[j-1]
        Lng_B = GPSData$longitude[j]
        Lat_B = GPSData$latitude[j]
        GPSData$spacing[j] = calcDistance(Lat_A, Lng_A, Lat_B, Lng_B)*1000 #计算相邻点之间的距离
      }
    }
    GPSData$spacing[is.nan(GPSData$spacing)] = 0
    info$ID[i] = ID
    info$AlldataNum[i] = length(GPSData$GPS_Speed)
    info$begintime[i] =as.character( GPSData$GpsTime[1])
    info$endtime[i] = as.character(GPSData$GpsTime[length(GPSData$vehicleID)-1])
    info$distance[i] = sum(GPSData$spacing)/1000
    info$timeAll[i] = (max(GPSData$GpsTime_UTC)-min(GPSData$GpsTime_UTC))/3600
    info$timespaceMax[i] = max(GPSData$GpsTime_diff)
    info$timespaceMode[i] = getmode(GPSData$GpsTime_diff)
    a =subset(GPSData,GPS_Speed>0)
    if (length(a$vehicleID) == 0){
      info$speed_min[i] = 0
      info$speed_max[i] = 0
      info$unzerospeedNum[i] = 0
      info$drivingtime[i] = 0
      info$roadNum[i] = 0
    }
    if (length(a$vehicleID) > 0){
      info$speed_min[i] = min(GPSData$GPS_Speed)
      info$speed_max[i] = max(a$GPS_Speed)
      info$unzerospeedNum[i] = length(a$GPS_Speed)
      info$drivingtime[i] = sum(a$GpsTime_diff)/3600
      info$roadNum[i] = 0
    }
    if(i >=200){break()}
  }
  return(info)
}

info = vehicleinfo(GPSData_initial)
