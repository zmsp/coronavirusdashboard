import csv
import json

csvfile = open('dashboards.csv', 'r')
jsonfile = open('dashboards.json', 'w')

reader = csv.DictReader( csvfile)
for row in reader:
    json.dump(row, jsonfile)
    jsonfile.write('\n')