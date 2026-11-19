#!/bin/bash

set -euo pipefail
umask 077

PASSWORD="${ADMIN_PASSWORD:-adminpw}"
LDIF_FILE=${1:?Usage: add-users.sh users.ldif}
BASE_DN=$(slapcat | awk '/^dn: dc=/ && !found {print $2; found = 1}')

if [ ! -f "$LDIF_FILE" ]; then
    echo "File not found! $LDIF_FILE" >&2
    exit 1
fi
if [ -z "$BASE_DN" ]; then
    echo "Could not determine the LDAP base DN" >&2
    exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
awk -v directory="$WORK_DIR" '
    BEGIN { RS = ""; ORS = "\n\n" }
    /(^|\n)dn:/ {
        filename = sprintf("%s/%08d.ldif", directory, ++entry_count)
        print > filename
        close(filename)
    }
    END { if (entry_count == 0) exit 1 }
' "$LDIF_FILE"

for entry_file in "$WORK_DIR"/*.ldif; do
    entry_dn=$(awk '/^dn:/ {sub(/^dn:[[:space:]]*/, ""); print; exit}' "$entry_file")
    if ldapadd -x -D "cn=admin,$BASE_DN" -w "$PASSWORD" -f "$entry_file" > "$WORK_DIR/result" 2>&1; then
        echo "Added LDAP entry: $entry_dn"
    else
        status=$?
        if [ "$status" -eq 68 ]; then
            echo "LDAP entry already exists, skipping: $entry_dn"
        else
            cat "$WORK_DIR/result" >&2
            exit "$status"
        fi
    fi
done
