#!/bin/bash

DATE=`date +%Y-%m-%d`

docker build -t "orangejulius/gentoo-baseimage:$DATE" -f "gentoo-baseimage.Dockerfile" .
