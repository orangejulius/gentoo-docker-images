#!/bin/bash

DATE=`date +%Y-%m-%d`

docker build -t "orangejulius/gentoo-baseimage:$DATE" -t "orangejulius/gentoo-baseimage:latest" -f "gentoo-baseimage.Dockerfile" .
