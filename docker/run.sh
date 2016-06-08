#!/bin/sh

cd /src/cloudawan/
mkdocs serve -a 0.0.0.0:8000

while :
do
	sleep 1
done

