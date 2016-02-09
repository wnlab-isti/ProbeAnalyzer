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
    cur.execute("select *, count(*) from proxibox.mac group by mac,dbm,client_id,created,modified order by created")
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
probeList = {'70:b3:d5:45:f1:d4','70:b3:d5:45:f3:b5','70:b3:d5:45:f1:de','70:b3:d5:45:f0:fa','70:b3:d5:45:f1:c6'}

f=open('eventsDetection_3sec_MAC_Data.txt', 'a')
secondsRange = 3

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
                    if toTimestamp >= time.mktime(x[4].timetuple()) >= time.mktime(entry[4].timetuple()) and x[1] == entry[1]:
                        matches.append(x[3])
                    if time.mktime(x[4].timetuple()) > toTimestamp:
                        break

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
print("--- %s seconds ---" % (time.time() - start_time))