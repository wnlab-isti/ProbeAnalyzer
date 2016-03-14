import MySQLdb
import json
import sys
import time
import string
import numpy as np
import calendar
#import pandas as pd
#from collections import Counter

def mysqlConnection():
    """

    :rtype: cursor
    """
    db = MySQLdb.connect(host="cloud4wi-server.isti.cnr.it",
                         user="cloud4wi",
                         passwd="clwn",
                         db="proxibox")

    cur = db.cursor()
    cur.execute("select *, count(*) from proxibox.mac where created >= '2016-03-04 00:00:00' and created < '2016-03-04 00:01:00' group by mac,dbm,client_id,created,modified order by created ")
    #cur.execute("select * from (select *, count(*) from proxibox.mac group by mac,dbm,client_id,created,modified order by created desc limit 5000) sub order by created asc")


    #df_mysql = pd.read_sql('select id, mac, dbm, client_id, created from proxibox.mac group by mac,dbm,client_id,created order by created', con=db)
    #print 'loaded dataframe from MySQL. records:', len(df_mysql)

    #print df_mysql.shape
    #print len(df_mysql)
    #print df_mysql.columns

    #print df_mysql
    #print df_mysql[''][5]
    db.close()

    return cur.fetchall()
    #return


start_time = time.time()

dataset = list(mysqlConnection())

mysqlConnection()
flagarray = np.zeros((len(dataset),1))

#statisticsNoProbe = {0:0,1:0,2:0,3:0,4:0}
#statisticsProbe = {0:0,1:0,2:0,3:0,4:0}
probeList = {'70:b3:d5:45:f0:8A','70:b3:d5:45:f0:CA','70:b3:d5:45:f2:78','70:b3:d5:45:f1:9E','70:b3:d5:45:f2:2B','70:b3:d5:45:f3:98',
             '70:b3:d5:45:f1:BA','70:b3:d5:45:f4:21','70:b3:d5:45:f2:21','70:b3:d5:45:f0:AC','70:b3:d5:45:f3:97','70:b3:d5:45:f2:27',
             '70:b3:d5:45:f3:1E','70:b3:d5:45:f0:FE','70:b3:d5:45:f0:DE','70:b3:d5:45:f3:27','70:b3:d5:45:f0:88','70:b3:d5:45:f0:FA',
             '70:b3:d5:45:f3:1A','70:b3:d5:45:f1:88','70:b3:d5:45:f1:19','70:b3:d5:45:f1:B8','70:b3:d5:45:f0:84','70:b3:d5:45:f3:9D',
             '70:b3:d5:45:f3:A8','70:b3:d5:45:f4:19','70:b3:d5:45:f3:23','70:b3:d5:45:f1:B4','70:b3:d5:45:f1:D4','70:b3:d5:45:f2:28',
             '70:b3:d5:45:f3:B5','70:b3:d5:45:f4:69','70:b3:d5:45:f3:E0','70:b3:d5:45:f2:85'}

probeList_pt1 = {'70:b3:d5:45:f0:FA','70:b3:d5:45:f3:1E','70:b3:d5:45:f2:21'} # corridoio (c62)
probeList_pt2 = {'70:b3:d5:45:f3:B5','70:b3:d5:45:f0:FE','70:b3:d5:45:f1:19'} # corridoio (c64)
probeList_pt3 = {'70:b3:d5:45:f1:D4','70:b3:d5:45:f0:DE','70:b3:d5:45:f3:97'} # corridorio (c67)
probeList_pt4 = {'70:b3:d5:45:f3:98','70:b3:d5:45:f0:CA','70:b3:d5:45:f0:8A'} # stanza C62
probeList_pt5 = {'70:b3:d5:45:f1:BA','70:b3:d5:45:f2:2B','70:b3:d5:45:f1:9E'} # stanza c63
probeList_pt6 = {'70:b3:d5:45:f0:88','70:b3:d5:45:f3:1A','70:b3:d5:45:f0:AC'} # stanza c64
probeList_pt7 = {'70:b3:d5:45:f3:9D','70:b3:d5:45:f2:85','70:b3:d5:45:f1:88'} # stanza c65
probeList_pt8 = {'70:b3:d5:45:f3:A8','70:b3:d5:45:f4:19','70:b3:d5:45:f0:84'} # stanza c66
probeList_pt9 = {'70:b3:d5:45:f4:21','70:b3:d5:45:f1:B8','70:b3:d5:45:f2:78'} # stanza c69
probeList_pt10 = {'70:b3:d5:45:f2:28','70:b3:d5:45:f1:B4','70:b3:d5:45:f3:27'} # stanza c70a
probeList_pt11 = {'70:b3:d5:45:f2:27'} # stanza c72
probeList_pt12 = {'70:b3:d5:45:f3:23','70:b3:d5:45:f3:E0','70:b3:d5:45:f4:69'} # stanza c74

mapFogGroup = {'70:b3:d5:45:f0:FA':'1',}

secondsRange = 2
f=open('./results/0304_0309/eventsDetection_'+str(secondsRange)+'sec_MAC_Data_NoFogsense.txt', 'a')
f_fog=open('./results/0304_0309/eventsDetection_'+str(secondsRange)+'sec_MAC_Data_OnlyFogsense.txt', 'a')

if dataset:
    for index,entry in enumerate(dataset):
        if flagarray[index] == 0:
            toTimestamp = time.mktime(entry[4].timetuple()) + secondsRange # seconds after
            matches = []
            matches.append(entry[3])

            flagarray[index] = 1
            #matches.append(entry)

            for subIndex,x in enumerate(dataset[index+1:]):
                if flagarray[subIndex+index+1] == 0:
                    flagarray[subIndex+index+1] = 1
                    if x[1] == entry[1]:
                        if toTimestamp >= time.mktime(x[4].timetuple()):
                            matches.append(x[3])
                        else:
                            break

            if entry[1] in probeList:
                if matches:
                    c = [ (i,matches.count(i)) for i in set(matches) ]
                    f_fog.write(entry[4].isoformat())
                    f_fog.write(',')
                    f_fog.write(entry[1])
                    f_fog.write(',')
                    f_fog.write(str(c))
                    f_fog.write('\n')
            else:
                if matches:
                    c = [ (i,matches.count(i)) for i in set(matches) ]
                    f.write(entry[4].isoformat())
                    f.write(',')
                    f.write(entry[1])
                    f.write(',')
                    f.write(str(c))
                    f.write('\n')

    #print statisticsNoProbe, statisticsProbe
    f.close()
    f_fog.close()
print("--- %s seconds ---" % (time.time() - start_time))