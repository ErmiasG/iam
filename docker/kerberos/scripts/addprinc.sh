#!/bin/bash

set -e

PASSWORD="${ADMIN_PASSWORD:-adminpw}"
# File to process
LDIF_FILE=${1:-"users.ldif"}

# Check if the file exists
if [[ ! -f "$LDIF_FILE" ]]; then
    echo "Error: File '$LDIF_FILE' not found!"
    exit 1
fi

USERS=$(awk '
  BEGIN { in_entry = 0; dn = ""; }
  
  # Start of an entry, look for DN
  /^dn:/ {
    if (in_entry && dn != "") {
      dn = ""
    }
    in_entry = 1
    split($0, array, ":")
    dn = array[2]
  }

  /^uid:/ {
    if (in_entry && uid != "") {
      uid = ""
    }
    split($0, array, ":")
    uid = array[2]
  }

  /^userPassword:/ {
    if (in_entry && userPassword != "") {
      userPassword = ""
    }
    split($0, array, ":")
    userPassword = array[2]
  }

  # Check for user-related objectClasses
  /^objectClass:/ {
    if ($2 ~ /(person|inetOrgPerson)/) {
      user_found = 1
    }
  }

  # End of entry: blank line
  /^[[:space:]]*$/ {
    if (in_entry && user_found) {
      print dn, uid, userPassword
      user_found = 0
    }
    in_entry = 0
  }

  END {
    # Print the last entry if valid
    if (in_entry && user_found) {
      print dn, uid, userPassword
    }
  }
' "$LDIF_FILE")

while IFS= read -r line; do
IFS=' ' read -r -a array <<< "$line"
DN=${array[0]}
ID=${array[1]}
PWD=${array[2]}

kadmin.local -q "addprinc -x dn="$DN" $ID" <<EOF 
$PWD
$PWD
EOF
done <<< "$USERS"


