#!/bin/bash

die() {
        echo "ERROR: $1" >&2
        rm -rf "$TMP"
        exit 1
}

# Get latest fire data from Nasa and convert to a GeoJSON that is understood by goestools
TMP=`mktemp -d`

echo "Temp directory: $TMP"

# Note: on a Raspberry Pi, the entire world shapefiles are too heavy and take very long to convert, so it is better to
# download a smaller shapefile that covers the area we are interested in:
#curl -o "$TMP/fires.zip" "https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/shapes/zips/MODIS_C6_1_Global_24h.zip"
curl -o "$TMP/fires.zip" "https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/shapes/zips/MODIS_C6_1_USA_contiguous_and_Hawaii_24h.zip" || die "Failed to get MODIS fire data"

unzip -o -d "$TMP" "$TMP/fires.zip" || die "Failed to decompress MODIS fire data"

echo "Converting fire data to geojson"
ogr2ogr -f "GeoJSON" -dialect SQLite -sql "select ST_Buffer(geometry,0.01) from MODIS_C6_1_USA_contiguous_and_Hawaii_24h" /tmp/fire.json "$TMP/MODIS_C6_1_USA_contiguous_and_Hawaii_24h.shp" || die "Could not convert shapefile to geoJSON"

rm -rf "$TMP"

