import csv
import json

csvfile = open('dashboards.csv', 'r')
jsonfile = open('dashboards.json', 'w')

reader = csv.DictReader( csvfile)
rows = []
for row in reader:
    rows.append(row);
json.dump(rows, jsonfile)
