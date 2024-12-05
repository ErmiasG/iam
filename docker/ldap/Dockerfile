FROM ubuntu:noble

RUN echo "path-include /usr/share/doc/krb5*" >> /etc/dpkg/dpkg.cfg.d/excludes

RUN apt-get update && \
    apt-get -qqy install nano less curl && \
    apt-get -qqy install expect && \
    apt-get -qqy install slapd ldap-utils schema2ldif 

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

RUN mkdir /ldap
COPY resources/config.ldif /ldap/config.ldif
COPY resources/dbconfig.ldif /ldap/dbconfig.ldif
COPY resources/load_modules.ldif /ldap/load_modules.ldif
COPY resources/add_modules.ldif /ldap/add_modules.ldif
COPY resources/schema_convert.conf /ldap/schema_convert.conf

COPY scripts/start-slapd.sh /scripts/start-slapd.sh
RUN chmod a+x /scripts/start-slapd.sh

COPY scripts/kill-slapd.sh /scripts/kill-slapd.sh
RUN chmod a+x /scripts/kill-slapd.sh

COPY scripts/reconfigure-slapd.sh /scripts/reconfigure-slapd.sh
RUN chmod a+x /scripts/reconfigure-slapd.sh

COPY scripts/ldapsearch.sh /scripts/ldapsearch.sh
RUN chmod a+x /scripts/ldapsearch.sh

COPY scripts/add-users.sh /scripts/add-users.sh
RUN chmod a+x /scripts/add-users.sh

RUN mkdir /tmp/ldif_output