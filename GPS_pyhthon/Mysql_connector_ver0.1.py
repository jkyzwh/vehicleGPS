# -*- coding: utf-8 -*-
"""
Created on Mon Oct 30 16:28:52 2017

@author: Zhwh-notbook
"""

import mysql.connector

cnx = mysql.connector.connect(user='zhwh_note',
                              password='000310',
                              host='172.16.90.68',
                              port='3306',
                              database='vehicleGPS')

cnx.close()