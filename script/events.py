import MySQLdb
import json
import sys
import time
import calendar

def mysqlConnection():
    """

    :rtype: cursor
    """
    db = MySQLdb.connect(host="cloud4wi-server.isti.cnr.it",
                         user="cloud4wi",
                         passwd="clwn",
                         db="proxibox")

    cur = db.cursor()
    #cur.execute("select *, count(*) from proxibox.mac group by mac,dbm,client_id,created,modified order by created")
    cur.execute("select * from (select *, count(*) from proxibox.mac group by mac,dbm,client_id,created,modified order by created desc limit 5000) sub order by created asc")
    db.close()
    return cur.fetchall()

dataset = list(mysqlConnection())

statisticsNoProbe = {0:0,1:0,2:0,3:0,4:0}
statisticsProbe = {0:0,1:0,2:0,3:0,4:0}
probeList = {'45F1D4','45F3B5','45F1DE','45F0FA','45F1C6'}

if dataset:
    for entry in dataset:

        range = 15; #seconds aftet and before current entry timestamp

        fromTimestamp = time.mktime(entry[4].timetuple()) - range # seconds before
        toTimestamp =  time.mktime(entry[4].timetuple()) + range # seconds after

        matches = []
        matches = [x for x in dataset if time.mktime(x[4].timetuple()) >= fromTimestamp and time.mktime(x[4].timetuple()) <= toTimestamp and x[3] != entry[3]]

        #print matches
        #index = 0
        # for x in dataset:
        #     if time.mktime(x[4].timetuple()) >= fromTimestamp and time.mktime(x[4].timetuple()) <= toTimestamp and x[3] != entry[3]:
        #         matches.append(x)
        #         #dataset.pop(index)
        #         #index += 1
        #     if time.mktime(x[4].timetuple()) > toTimestamp:
        #         break

        if matches:
            i = 0
            for item in matches:
                if item[1] == entry[1] and item[3] != entry[3]:
                    i = i + 1
                    #print i
            if i > 4:
                statisticsNoProbe[4] = statisticsNoProbe[4]+1
            else:
                statisticsNoProbe[i] = statisticsNoProbe[i]+1

    print statisticsNoProbe



