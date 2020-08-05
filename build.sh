#!/bin/bash
set -ex

mkdir -p target
rm -rf target/*

gunzip -c ukpostcodes.csv.gz | awk -F, -f reduce_precision.awk | awk -F, -f filter_postcodes.awk > target/ukpostcodes.csv

curl --fail https://raw.githubusercontent.com/hmrc/eat-out-to-help-out-establishments/master/data/participating-establishments/restaurants.csv > target/restaurants.csv
python parse_restaurants.py target/restaurants.csv | sort -u > target/restaurant_postcodes.csv

join -t , -1 2 -2 2 -o 1.1,0,2.3,2.4 <(sort -k 2 -t , target/restaurant_postcodes.csv) <(sort -k 2 -t , target/ukpostcodes.csv) > target/restaurants_with_lat_lon.csv

awk -F, -f filter_postcodes.awk target/restaurants_with_lat_lon.csv | awk -F, -f reduce_precision.awk > target/filtered_restaurants_with_lat_lon.csv

cat <(echo name,postcode,lat,lon) target/filtered_restaurants_with_lat_lon.csv | csv2geojson --lat lat --lon lon | jq -c . | gzip -c > target/restaurants.geojson.gz

rm target/*.csv