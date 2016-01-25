import json
import sys
from pprint import pprint


def loadData(probefile):
    timestamps = []
    client_mac = []
    rssi = []

    json_data = open(probefile).read()
    data = json.loads(json_data)
    for item in data:
        timestamps = item.get["numberLong"]
        a = item.get["a"]
    b = item.get["b"]
    c = item.get["c"]
    pprint(data)  # return timestamps, client_mac,rssi


probefile = sys.argv[1]
loadData(probefile);
