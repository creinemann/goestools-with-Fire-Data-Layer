
::Batch file to download, unzip, convert geospatial data to polygons, and upload to goestools
::  DEPENDECIES: 
:: 	POWERSHELL
::	OGR2OGR
::	WINSCP
::	GOESTOOLS

:: Change Directory to your working folder

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


# USRADIOGUY.COM
