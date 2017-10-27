library(RMySQL)
library(data.table)


DB_name <- "vehicleGPS" #使用的数据库名称
#建立数据库连接
conn <- dbConnect(dbDriver('MySQL'),dbname=DB_name,
                 user = 'root', password = '000000',
                 host = '172.16.90.68',port = 3306) #数据库IP与端口

# 从数据库中读取数据
GPSData_sichuan = dbGetQuery(conn, "SELECT * FROM vehicleGPS.sichuan")
dataName = 'D:/PROdata/Data/dangerous good transport/henan-xcar-2016080810.csv'
colname = c("vehicleID","longitude","latitude",
            "GPS_Speed","direction","elevation",
            "GpsTime")
GPSData_henan = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)

#将数据框写入数据库表
dbWriteTable(conn, "Henan", GPSData_henan)
#关闭数据库连接
dbDisconnect(conn)
