#!/bin/bash

set -e

PASSWORD="${ADMIN_PASSWORD:-adminpw}"
BASE_DN=$(slapcat | grep "dn: dc=" | awk -F ' ' '{print $2}')

if [ ! -f "$1" ]; then
    echo "File not found! $1"
fi
echo "ldapadd -x -D cn=admin,$BASE_DN -w XXXXXX -f $1"
ldapadd -x -D "cn=admin,$BASE_DN" -w $PASSWORD -f "$1"

/scripts/ldapsearch.sh