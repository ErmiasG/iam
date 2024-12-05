#!/bin/bash

set -e

/scripts/reconfigure-slapd.sh
sleep 2

slaptest -f /kerberos/schema_convert.conf -F /tmp/krb_ldif_output
mv /tmp/krb_ldif_output/cn\=config/cn\=schema/cn\=\{0\}kerberos.ldif /tmp/krb_ldif_output/kerberos.ldif
sed -i -e 's/^dn: cn={[0-9]*}kerberos/dn: cn=kerberos,cn=schema,cn=config/' /tmp/krb_ldif_output/kerberos.ldif
sed -i -e 's/^cn: {[0-9]*}kerberos/cn: kerberos/' /tmp/krb_ldif_output/kerberos.ldif
sed -i '/structuralObjectClass: olcSchemaConfig/Q' /tmp/krb_ldif_output/kerberos.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/krb_ldif_output/kerberos.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -v -f /kerberos/krb5principalname.ldif 


if [ -f /kerberos/acl.ldif ]; then
  ldapmodify -Q -Y EXTERNAL -H ldapi:/// -v -f /kerberos/acl.ldif
fi

/scripts/kill-slapd.sh
sleep 2
/scripts/start-slapd.sh


