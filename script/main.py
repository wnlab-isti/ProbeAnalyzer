import json
import sys
from pprint import pprint


def loadData(probefile):
    timestamps = []
    client_mac = []
    rssi = []

    json_data = open(probefile).read()



    with open(probefile) as file:
        for line in file:
            data = json.loads(line)

    #     #data.append(json.loads(json_data))
    #     #pprint(data)
            timestamps = data["probe_date"]["$numberLong"] #.get("probe_date")
            pprint(timestamps)
    #     a = item.get["a"]
    #     b = item.get["b"]
    #     c = item.get["c"]
    #     pprint(item)  # return timestamps, client_mac,rssi


probefile = sys.argv[1]
loadData(probefile);
