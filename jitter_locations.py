# inspired by https://gis.stackexchange.com/questions/25877/generating-random-locations-nearby

import csv
import random
import sys
import math

def round25(n):
    return round(round(n * 4000) / 4000, 4)

taken = {}
for row in csv.DictReader(iter(sys.stdin.readline, ''), fieldnames=['name', 'postcode', 'lat', 'lon']):

    name = row['name']
    postcode = row['postcode']
    orig_lat = float(row['lat'])
    orig_lon = float(row['lon'])
    lat = orig_lat
    lon = orig_lon
    r = 5
    while True:
        lat = round25(lat)
        lon = round25(lon)
        key = f"{lat}/{lon}"
        if not key in taken:
            taken[key] = True
            print(f"{name},{postcode},{lat},{lon}")
            break
        else:
            radiusDeg = r / 111000 
            u = random.random()
            v = random.random()
            w = radiusDeg * math.sqrt(u)
            t = 2 * math.pi * v
            x = w * math.cos(t)
            y = w * math.sin(t)

            x_adjusted = x / math.cos(math.radians(orig_lat))
            lon = orig_lon + x_adjusted
            lat = orig_lat + y
            r += 1
