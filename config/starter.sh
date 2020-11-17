#!/bin/bash
service webmin start
service squid start
service nginx start
service e2guardian start
# service cron start

while true
do
if [[ $(service webmin status) = *stopped* ]]
then
break
else
sleep 5m
fi
done
