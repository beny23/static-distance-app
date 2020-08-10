#!/bin/bash
set -ex

mkdir -p target

curl --fail https://raw.githubusercontent.com/beny23/static-distance/gh-pages/named_pubs.csv.gz | gunzip -dc > target/filtered_restaurants_with_lat_lon.csv

cat <(echo name,postcode,lat,lon) target/filtered_restaurants_with_lat_lon.csv | node_modules/csv2geojson/csv2geojson --lat lat --lon lon | jq -c . | gzip -c > target/restaurants.geojson.gz

rm target/*.csv