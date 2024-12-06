#!/bin/bash

REALM=${REALM:-"hopsworks05"}
DESPLAY_NAME=${DESPLAY_NAME:-${REALM^^}}
SERVER=${SERVER:-"http://keycloak.hopsworks.svc.cluster.local:8080"}
APP_NAME="hopsworks-app"

CLIENTS_JSON_PATH=${CLIENTS_JSON_PATH:-"resources/example-clients.json"}
USERS_JSON_PATH=${USERS_JSON_PATH:-"resources/example-users.json"}
ROLES_JSON_PATH=${ROLES_JSON_PATH:-"resources/example-roles.json"}
GROUPS_JSON_PATH=${GROUPS_JSON_PATH:-"resources/example-groups.json"}
SCOPES_JSON_PATH=${SCOPES_JSON_PATH:-"resources/example-scopes.json"}

KC_BOOTSTRAP_ADMIN_USERNAME=${KC_BOOTSTRAP_ADMIN_USERNAME:-"admin"}
KC_BOOTSTRAP_ADMIN_PASSWORD=${KC_BOOTSTRAP_ADMIN_PASSWORD:-"adminpw"}

kcadmin=/opt/keycloak/bin/kcadm.sh

_create_in_realm() {
  if [ -s $1 ]; then
    jq -c '.[]' $1 | while read i; do
      ${kcadmin} create $2 -r $REALM -b "$i"
    done
  fi
}

${kcadmin} config credentials --server $SERVER --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD

${kcadmin} create realms -s realm=$REALM -s displayName=$DESPLAY_NAME -s enabled=true

SCOPE_ID=$(${kcadmin} get client-scopes -r $REALM --fields id,name | jq -c -r '.[] | select(.name == "roles") | .id')
${kcadmin} delete client-scopes/$SCOPE_ID -r $REALM 

_create_in_realm $SCOPES_JSON_PATH "-x client-scopes"
_create_in_realm $CLIENTS_JSON_PATH "clients"

CLIENT_ID=$(${kcadmin} get clients -r $REALM -q clientId=$APP_NAME --fields id | jq -c -r '.[].id')
_create_in_realm $ROLES_JSON_PATH "clients/$CLIENT_ID/roles"

_create_in_realm $GROUPS_JSON_PATH "groups"

if [ -s $USERS_JSON_PATH ]; then
  jq -c '.[]' $USERS_JSON_PATH | while read i; do
    ${kcadmin} create users -r $REALM -b "$i"
    USERNAME=$(jq -c -r '.username' <<< "$i")
    CLIENT_ROLES=$(jq -c -r '.clientRoles' <<< "$i")
    jq -c -r ".\"$APP_NAME\"[]" <<< $CLIENT_ROLES | while read j; do
      ${kcadmin} add-roles -r $REALM --uusername $USERNAME --cclientid $APP_NAME --rolename "$j"
    done
  done
fi