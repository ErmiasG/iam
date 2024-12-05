FROM keycloak/keycloak

USER root
RUN mkdir resources
RUN mkdir scripts

RUN chown keycloak:keycloak resources
RUN chown keycloak:keycloak scripts

USER keycloak
COPY resources/example-client.json resources/example-client.json
COPY resources/example-users.json resources/example-users.json
COPY scripts/configure-keycloak.sh scripts/configure-keycloak.sh