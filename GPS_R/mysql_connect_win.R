library(RMySQL)
library(data.table)


DB_name <- "vehicleGPS" #使用的数据库名称
#建立数据库连接
conn <- dbConnect(dbDriver('MySQL'),dbname=DB_name,
                 user = 'zhwh_note', password = '000310',
                 host = '172.16.90.68',port = 3306) #数据库IP与端口
#获取数据库里的表列表
tableList = dbListTables(conn)
#获取数据表1的列名称列表
colList = dbListFields(conn, tableList[1])

# 从数据库中读取数据
GPSData_sichuan = dbGetQuery(conn, "SELECT * FROM vehicleGPS.sichuan")
dataName1 = 'D:/PROdata/Data/dangerous good transport/sichuan-xcar-2016080810.csv'
dataName2 = 'D:/PROdata/Data/dangerous good transport/henan-xcar-2016080810.csv'

colname = c("vehicleID","longitude","latitude",
            "GPS_Speed","direction","elevation",
            "GpsTime")
sichuan = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname2)

#将数据框写入数据库表
dbWriteTable(conn, "Henan", GPSData_henan)
#关闭数据库连接
dbDisconnect(conn)
