#!/bin/bash

set -euo pipefail

REALM=${REALM:-"hopsworks"}
DISPLAY_NAME=${DISPLAY_NAME:-${DESPLAY_NAME:-${REALM^^}}}
SERVER=${SERVER:-"http://localhost:8080"}
CLIENT_ID=${CLIENT_ID:-"hopsworks-app"}

CLIENTS_JSON_PATH=${CLIENTS_JSON_PATH:-"resources/example-clients.json"}
USERS_JSON_PATH=${USERS_JSON_PATH:-"resources/example-users.json"}
ROLES_JSON_PATH=${ROLES_JSON_PATH:-"resources/example-roles.json"}
GROUPS_JSON_PATH=${GROUPS_JSON_PATH:-"resources/example-groups.json"}
SCOPES_JSON_PATH=${SCOPES_JSON_PATH:-"resources/example-scopes.json"}

KC_BOOTSTRAP_ADMIN_USERNAME=${KC_BOOTSTRAP_ADMIN_USERNAME:-"admin"}
KC_BOOTSTRAP_ADMIN_PASSWORD=${KC_BOOTSTRAP_ADMIN_PASSWORD:-"adminpw"}

kcadmin=/opt/keycloak/bin/kcadm.sh

_create_in_realm() {
  local json_path=$1
  shift
  if [ -s "$json_path" ]; then
    jq -c '.[]' "$json_path" | while IFS= read -r entry; do
      "${kcadmin}" create "$@" -r "$REALM" -b "$entry"
    done
  fi
}

${kcadmin} config credentials --server "$SERVER" --realm master --user "$KC_BOOTSTRAP_ADMIN_USERNAME" --password "$KC_BOOTSTRAP_ADMIN_PASSWORD"

${kcadmin} create realms -s "realm=$REALM" -s "displayName=$DISPLAY_NAME" -s enabled=true

SCOPE_ID=$(${kcadmin} get client-scopes -r $REALM --fields id,name | jq -c -r '.[] | select(.name == "roles") | .id')
${kcadmin} delete client-scopes/$SCOPE_ID -r $REALM 

_create_in_realm "$SCOPES_JSON_PATH" -x client-scopes
_create_in_realm "$CLIENTS_JSON_PATH" clients

ID=$(${kcadmin} get clients -r $REALM -q clientId=$CLIENT_ID --fields id | jq -c -r '.[].id')
_create_in_realm "$ROLES_JSON_PATH" "clients/$ID/roles"

_create_in_realm "$GROUPS_JSON_PATH" groups

if [ -s "$USERS_JSON_PATH" ]; then
  jq -c '.[]' "$USERS_JSON_PATH" | while IFS= read -r entry; do
    ${kcadmin} create users -r "$REALM" -b "$entry"
    USERNAME=$(jq -r '.username' <<< "$entry")
    jq -c '(.clientRoles // {}) | to_entries[]' <<< "$entry" | while IFS= read -r mapping; do
      C_ID=$(jq -r '.key' <<< "$mapping")
      jq -r '.value[]' <<< "$mapping" | while IFS= read -r role; do
        ${kcadmin} add-roles -r "$REALM" --uusername "$USERNAME" --cclientid "$C_ID" --rolename "$role"
      done
    done
  done
fi
