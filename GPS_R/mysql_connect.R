library("RMySQL", lib.loc="~/R/x86_64-pc-linux-gnu-library/3.4")
library(data.table)

# import data

dataName = '/home/zhwh/Data/sichuan-xcar-2016080810.csv'
colname = c("vehicleID","longitude","latitude",
            "GPS_Speed","direction","elevation",
            "GpsTime")
GPSData_initial = fread(dataName,header=T,sep=",",stringsAsFactors=FALSE,data.table=F,col.names=colname)

# connect database use 
conn <- dbConnect(RMySQL::MySQL(),
                  dbname = 'vehicleGPS',
                  username = 'zhwh',
                  password = '000310',
                  unix.socket = '/var/run/mysqld/mysqld.sock')
