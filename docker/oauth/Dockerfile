FROM ubuntu:noble

ARG KC_VERSION=26.0.7

USER root
RUN useradd -ms /bin/bash keycloak
RUN apt update && apt install -y jq curl wget && apt install -y openjdk-21-jdk

RUN wget -q -O /tmp/keycloak-${KC_VERSION}.tar.gz https://github.com/keycloak/keycloak/releases/download/${KC_VERSION}/keycloak-${KC_VERSION}.tar.gz && \
    mkdir /opt/keycloak && \
    tar -xvzf /tmp/keycloak-${KC_VERSION}.tar.gz -C /opt/keycloak --strip-components=1

RUN chown keycloak:keycloak -R /opt/keycloak

RUN mkdir resources
RUN mkdir scripts

RUN chown keycloak:keycloak resources
RUN chown keycloak:keycloak scripts

USER keycloak
COPY resources/example-client.json resources/example-client.json
COPY resources/example-users.json resources/example-users.json
COPY scripts/configure-keycloak.sh scripts/configure-keycloak.sh

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]