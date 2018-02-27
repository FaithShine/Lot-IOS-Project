#!/bin/bash

DATE=$1

fswebcam -r 1280x720 --no-banner /home/pi/as3/webcam/$DATE.jpg

