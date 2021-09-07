# Goestools with Fire Data Layer

![GOES16_FD_FCFIREMAP_20210724T150022Z](https://user-images.githubusercontent.com/47005123/126873911-82257340-8c32-4041-9788-48aaa7c0606a.jpg)
Example fire data (orange dots) on areas of South America

## Scripts

These scripts allows goestools to use the built in map handlers to apply fire data from 

FIRMS Fire Information for Resource Management System US / Canada: https://firms.modaps.eosdis.nasa.gov/ 

I have a windows task scheduler created to run the batch file in this repository every 12 hours then convert that data
to a format that can be processed by goestools. It then uploads the latest fire data json file to the pi I use to run goestools.

Within goestools I have a custom process that reads the imagery, applies geo-political boundaries, then applies the fire hotspot data.
Since I do not intend to run the process all the time, I use the command as needed or seasonally.

Goestools by default utilizes a function that allows the software to apply map data from 
Natural Earth. Originals from https://www.naturalearthdata.com/.

However, the files needed to apply geo-spatial data from FIRMS is of 
a different format. The geo spatial data available for public download is generated in a points based GIS geometry.
Whereas goestools processes with a polygon, or multipolygon geometry.

## Requirements

I run this script on a Windows 10 PC this could easily be adapted to run on an ARM board or similar computer

System dependencies:

* GOESTOOLS  https://github.com/pietern/goestools
* POWERSHELL https://docs.microsoft.com/en-us/powershell/?view=powershell-7.1
* OGR2OGR    https://gdal.org/programs/ogr2ogr.html#ogr2ogr
* WINSCP     https://winscp.net/eng/index.php
 
## Creating the neccesary files

Create a batch file using a text editor such as Notepad or better yet Notepad++
with the following script, changing the directories to match you own:

## Update with MODIS FIRMS file access 09/07/2021
FIRMS has been overwhelmed with data access requests, and they have opened a mirror site to download data
from, you can paste this address in the batch file below if you have issues downloading the data:
 https://firms2.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/shapes/zips/MODIS_C6_1_Global_24h.zip

``` shell
::Batch file to download, unzip, convert geospatial data to polygons, and upload to goestools
::  DEPENDECIES: 
:: 	POWERSHELL
::	OGR2OGR
::	WINSCP
::	GOESTOOLS

:: Change Directory to working folder

	cd C:\USERDIRECTORY
	
:: REMOVE EXISTING fire.json FILE (OGR2OGR DOES NOT ALLOW OVERWRITING FILE.)

	del "F:\FIREDATA\fire.json" /s /f /q
	
:: DOWNLOAD THE 24 HOUR FIRE DATA
:: NOTE THIS IS GLOBAL DATA, A USA (Conterminous) and Hawaii FIRE DATA FILE CAN BE SUBSTITUTED FOR THE ONE IN THE NEXT LINE
:: THAT LINK IS https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/shapes/zips/MODIS_C6_1_USA_contiguous_and_Hawaii_24h.zip
	
	powershell -Command Invoke-WebRequest https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/shapes/zips/MODIS_C6_1_Global_24h.zip -OutFile C:\USERDIRECTORY\global.zip
	
:: UNZIP THE ARCHIVE

	powershell Expand-Archive C:\USERDIRECTORY\global.zip -DestinationPath C:\USERDIRECTORY -force
	
:: CONVERT THE SHAPEFILE MODIS_C6_1_Global_24h.shp TO fire.json

	ogr2ogr -f "GeoJSON" -dialect SQLite -sql "select ST_Buffer(geometry,0.01) from MODIS_C6_1_Global_24h" fire.json MODIS_C6_1_Global_24h.shp


@echo off

:: UPLOAD THE MOST RECENT fire.json TO GOESTOOLS

:: NOTE: Winscp can auto generate this script by runnung winscp GUI looging into your pi, then
:: select 'Session' 'Generate URL/code"

"C:\Program Files (x86)\WinSCP\WinSCP.com" ^
  /log="C:\USERDIRECTORY\FireDatausradioguy.log" /ini=nul ^
  /command ^
    "open sftp://piusername:piuserpassword@pi_IP adress/ -hostkey=""your pi host key""" ^
    "put -latest ""C:\USERDIRECTORY\fire.json" " ^

    "exit"

set WINSCP_RESULT=%ERRORLEVEL%
if %WINSCP_RESULT% equ 0 (
  echo Success
) else (
  echo Error
)

exit /b %WINSCP_RESULT%



```
Save the file as a batch script, such as shp2json.bat

I run the batch automatically by calling it from within windows using the Windows Task scheduler. https://docs.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page

The script can also be run as needed by running the batch file.

## Creating the New Goestools Process
Instead of editing goesr-goesproc.conf file within goestools I chose to write a shourt handler that, again, can be run as needed (during fire season).

Create a .conf  file using a text editor such as Notepad or better yet Notepad++.  This process creates imagery using bands 02 and 13

The output files are saved inthe usual fashion, but under a 'fire' directory under M1, M2 and FD directories. You can change this to work with differnt bands if needed.
This will generate Full Color Imagery, with the fire hotspots appearing as Orange dots or clusters
Insert the following into the file:

```
# GOES-16 ABI FIRE HOTSPOT LAYERING
# FIRE DATA FROM https://firms.modaps.eosdis.nasa.gov/usfs/
[[handler]]
type = "image"
origin = "goes16"
regions = [ "fd", "m1", "m2" ]
channels = [ "ch02", "ch13" ]
directory = "./goes16/{region:short|lower}/fire/{time:%Y-%m-%d}"
filename = "GOES16_{region:short}_FCFIREMAP_{time:%Y%m%dT%H%M%SZ}"
format = "jpg"
json = false

  [handler.remap.ch02]
  path = "/usr/share/goestools/wxstar/wxstar_goes16_ch02_curve.png"

  [handler.lut]
  path = "usr/share/goestools/wxstar/wxstar_goes16_lut.png"

  [[handler.map]]
  path = "/usr/share/goestools/ne/ne_50m_admin_0_countries_lakes.json"

  [[handler.map]]
  path = "/usr/share/goestools/ne/ne_50m_admin_1_states_provinces_lakes.json"

  [[handler.map]]
  path = "/home/pi/fire.json"
  color = "#FF6700"

```


NOTE: You will need to change the 'origin', 'directory', and  'filename' to 17 to work with GOES 17.

Save the file as goesfireproc.conf

Copy the file to /home/pi/

Make sure you sudo reboot the pi to enable the new handler,

Then use the command
```
goesproc -c goesfireproc.conf -m packet --subscribe tcp://127.0.0.1:5004 --out /home/pi/goes
```
On the pi to start the process.

## Future Ideas

Use the plotting function to maybe plot hurricanes, cyclones, etc using geo spatial data.

## Acknowledgments

Thanks to Pieter Noordhuis (https://github.com/pietern/goestools) for building
an open source utility -goestools-  for receiving, and decoding signals from GOES satellites.

Thanks to Keith Jenkins from Cornell University GIS & Geospatial Applications Librarian for assistance with the ogr2ogr conversion.

Thanks to Dr. Michele Tobias Geospatial Data Specialist, UC Davis Library with assistance on testing with QGIS software.


![GOES16_FD_FCFIREMAP_20210723T180023Z](https://user-images.githubusercontent.com/47005123/126876022-823ac295-2e06-487e-bfe0-670df0c906c2.jpg)

Fires in Onterio and Quebec Canada



![GOES17_M1_FCFIREMAP_20210723T182224Z](https://user-images.githubusercontent.com/47005123/126876118-990af964-403b-4353-be27-c999a1f9b00c.jpg)

Fires in Western USA  A lot of smoke from the Bootleg fire 7.24.2021 On July 19th, the Log and Bootleg Fires merged into one fire.


## Other Satellites

I have tested this with both GK-2A and Himawari 8 and it appears to be functional
![Himawari8_FD_VS_20210724T025100Z](https://user-images.githubusercontent.com/47005123/126876857-5ef52f22-7fa3-44da-b539-cdc500654c10.jpg)

Himawari 8 with MODIS fire data

## Disclaimer
## DO NOT use this information to make decisions relating to active fires.
