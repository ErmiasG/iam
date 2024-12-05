FROM docker.hops.works/dev/ermias/kerberos/ldap:0.1.0

RUN apt-get update && \   
    apt-get -qqy install krb5-kdc krb5-admin-server krb5-kdc-ldap 

RUN mkdir -p /etc/ldap/schema && \
    cp /usr/share/doc/krb5-kdc-ldap/kerberos.schema.gz /etc/ldap/schema/ && \
    gunzip /etc/ldap/schema/kerberos.schema.gz

COPY resources/krb5principalname.ldif /kerberos/krb5principalname.ldif
COPY resources/schema_convert.conf /kerberos/schema_convert.conf

COPY scripts/krb-reconfigure-slapd.sh /scripts/krb-reconfigure-slapd.sh
RUN chmod a+x /scripts/krb-reconfigure-slapd.sh

COPY scripts/addprinc.sh /scripts/addprinc.sh
RUN chmod a+x /scripts/addprinc.sh

RUN mkdir /tmp/krb_ldif_output  

RUN mkdir -p /var/log/kerberos 

COPY scripts/init_db.sh /init_db.sh
RUN chmod a+x /init_db.sh
