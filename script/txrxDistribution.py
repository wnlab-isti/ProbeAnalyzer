import MySQLdb
import json
import sys
import time
import string
import numpy as np
import calendar
#import pandas as pd
from collections import Counter
from collections import defaultdict

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
    #cur.execute("select * from (select *, count(*) from proxibox.mac group by mac,dbm,client_id,created,modified order by created desc limit 200) sub order by created asc")
    db.close()

    return cur.fetchall()

start_time = time.time()

dataset = list(mysqlConnection())

mysqlConnection()

probeList = {'70:b3:d5:45:f1:d4','70:b3:d5:45:f3:b5','70:b3:d5:45:f1:de','70:b3:d5:45:f0:fa','70:b3:d5:45:f1:c6'}

#f=open('eventsDetection_3sec_MAC_Data.txt', 'a')
my_dict = defaultdict(set)


if dataset:
    for index,entry in enumerate(dataset):
        if entry[1] in probeList:
            tx = entry[1].replace(":","")
            tx = tx[-6:]

            f = open('./results/dist_tx'+tx+'_rx'+entry[3],'a')
            f.write(str(entry[2]))
            f.write('\n')
            #my_dict[entry[1]].add(entry[3],entry[2])
            f.close()
    #print my_dict.items()
    #f.close()
print("--- %s seconds ---" % (time.time() - start_time))