# Installing on a Raspberry Pi

You can use the `get_fires.sh` script with a crontab to regularly fetch the latest fire data. This script saves everything in /tmp to avoid straining the RPi flash
even more than usual.

The service file can be used to run a separate goesproc instance that only creates fire overlays in the `incoming` directory.
