#!/bin/bash
service webmin start
service squid start
service nginx start

exec e2guardian -N
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
