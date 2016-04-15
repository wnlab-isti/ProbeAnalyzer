#! /bin/bash

mv --force --backup=numbered c4wsense c4wsense~

SQLquery="
  SELECT created, client_id, mac, dbm FROM mac
  WHERE created >= '2016-03-04 00:00:00' AND created <= '2016-03-23 23:59:59'
  GROUP by created, client_id, mac, dbm
  ORDER by created, client_id, mac, dbm
"

mysql --quick --user=cloud4wi --password="clwn" \
    --host=cloud4wi-server --port=3306 proxibox <<<$SQLquery > c4wsense

chmod -w c4wsense

#echo "select id, timestamp, x, y, z from fingerprint_ids order by id" | \
#    mysql --user=localization --password="!localization_2k15!" \
#    --host=casuario --port=3306 localization >wnlab.txyz
