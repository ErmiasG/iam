#!/bin/bash

set -e

PASSWORD="${ADMIN_PASSWORD:-adminpw}"
BASE_DN=$(slapcat | grep "dn: dc=" | awk -F ' ' '{print $2}')

ldapsearch -x -b $BASE_DN -D "cn=admin,$BASE_DN" -w $PASSWORD "$@"
