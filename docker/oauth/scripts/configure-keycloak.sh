#!/bin/bash

REALM=${REALM:-"hopsworks"}
DESPLAY_NAME=${DESPLAY_NAME:-${REALM^^}}
SERVER=${SERVER:-"http://localhost:8080"}

CLIENTS_JSON_PATH=${CLIENTS_JSON_PATH:-"resources/example-clients.json"}
USERS_JSON_PATH=${USERS_JSON_PATH:-"resources/example-users.json"}
GROUPS_JSON_PATH=${GROUPS_JSON_PATH:-"resources/example-groups.json"}
SCOPES_JSON_PATH=${SCOPES_JSON_PATH:-"resources/example-scopes.json"}

KC_BOOTSTRAP_ADMIN_USERNAME=${KC_BOOTSTRAP_ADMIN_USERNAME:-"admin"}
KC_BOOTSTRAP_ADMIN_PASSWORD=${KC_BOOTSTRAP_ADMIN_PASSWORD:-"adminpw"}

kcadmin=/opt/keycloak/bin/kcadm.sh

_add_to_realm() {
  if [ -s $1 ]; then
    jq -c '.[]' $1 | while read i; do
      ${kcadmin} create $2 -r $REALM -b "$i"
    done
  fi
}

${kcadmin} config credentials --server $SERVER --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD

${kcadmin} create realms -s realm=$REALM -s displayName=$DESPLAY_NAME -s enabled=true

_add_to_realm $SCOPES_JSON_PATH "-x client-scopes"
_add_to_realm $CLIENTS_JSON_PATH "clients"

_add_to_realm $GROUPS_JSON_PATH "groups"
_add_to_realm $USERS_JSON_PATH "users"
