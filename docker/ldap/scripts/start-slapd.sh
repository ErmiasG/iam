#!/bin/bash

if pgrep -x "slapd" > /dev/null
then
    echo "slapd is running"
else
    echo "Starting slapd"
    slapd -h "ldap:/// ldapi:///" -d 0 &
    sleep 3
    echo "slapd started with pid=$!"
fi
