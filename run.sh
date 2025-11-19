#!/bin/bash

if [[ ! $(docker volume ls -q | grep leginon3x-db) ]]; then
  echo Creating Docker volume for mariadb-database...
  docker volume create leginon3x-db
else
  echo Using existing leginon3x-db volume for MyISAM.
fi
echo Done.

# Change these if you already have other services running on default ports
WEBPORT=8000
VNCPORT=5901
DBPORT=53306
PTOLEMYPORT=8001

docker run -d -t \
  --privileged \
  -v $(pwd)/emg/data:/emg/data \
  -v leginon3x-db:/var/lib/mysql \
  -v $(pwd):/local_data \
  -v $(pwd)/config/httpd.conf:/etc/httpd/conf/httpd.conf \
  -v $(pwd)/config/my.cnf:/etc/my.cnf \
  -w /sw/myami/appion \
  -e DISPLAY=host.docker.internal:0 \
  --expose 81 \
  -p $WEBPORT:80 -p $VNCPORT:5901 -p $DBPORT:3306 -p $PTOLEMYPORT:81\
  anchi2c/leginon-py2-centos7

echo Waiting for database...
sleep 10
echo Done.
