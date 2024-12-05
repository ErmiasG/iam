#!/bin/bash

set -e

PASSWORD="${ADMIN_PASSWORD:-adminpw}"
DOMAIN="${LDAP_DOMAIN:-example.com}"
OU="${LDAP_OU:-example}"

/scripts/kill-slapd.sh

debconf-set-selections <<EOF
slapd slapd/internal/adminpw password $PASSWORD
slapd slapd/internal/generated_adminpw password $PASSWORD
slapd slapd/password2 password $PASSWORD
slapd slapd/password1 password $PASSWORD
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string $DOMAIN
slapd shared/organization string $OU
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database string when needed
EOF

dpkg-reconfigure -f noninteractive slapd

/scripts/start-slapd.sh

SSHA_PWD=$(slappasswd -h {SSHA} -s $PASSWORD)
sed -i -e "s/^olcRootPW: XXXXXX/olcRootPW: $SSHA_PWD/" /ldap/config.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /ldap/config.ldif

slapcat -f /ldap/schema_convert.conf -F /tmp/ldif_output -n0 -s "cn={5}dyngroup,cn=schema,cn=config" > /tmp/cn=dyngroup.ldif
sed -i '/structuralObjectClass: olcSchemaConfig/Q' /tmp/cn\=dyngroup.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/cn\=dyngroup.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -v -f /ldap/dbconfig.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /ldap/load_modules.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /ldap/add_modules.ldif

/scripts/kill-slapd.sh
/scripts/start-slapd.sh
