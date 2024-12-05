#!/bin/bash

REALM=${REALM:-"hopsworks"}
DESPLAY_NAME=${DESPLAY_NAME:-${REALM^^}}
SERVER=${SERVER:-"http://localhost:8080"}

CLIENT_JSON_PATH=${CLIENT_JSON_PATH:-"resources/example-client.json"}
USERS_JSON_PATH=${USERS_JSON_PATH:-"resources/example-users.json"}

KC_BOOTSTRAP_ADMIN_USERNAME=${KC_BOOTSTRAP_ADMIN_USERNAME:-"admin"}
KC_BOOTSTRAP_ADMIN_PASSWORD=${KC_BOOTSTRAP_ADMIN_PASSWORD:-"admin"}

kcadmin=/opt/keycloak/bin/kcadm.sh

${kcadmin} config credentials --server $SERVER --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD

${kcadmin} create realms -s realm=$REALM -s displayName=$DESPLAY_NAME -s enabled=true

${kcadmin} create groups -r $REALM -b '{ "name": "Admins" }'
${kcadmin} create groups -r $REALM -b '{ "name": "Users" }'

${kcadmin} create roles -r $REALM -b '{"name": "Admins", "description": "Administrator privileges"}'
${kcadmin} create roles -r $REALM -b '{"name": "Users", "description": "User privileges"}'

${kcadmin} create clients -r $REALM -f $CLIENT_JSON_PATH

jq -c '.[]' $USERS_JSON_PATH| while read i; do
  ${kcadmin} create users -r $REALM -b $i
done
