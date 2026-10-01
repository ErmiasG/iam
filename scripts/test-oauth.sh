#!/bin/bash

set -euo pipefail
umask 077

while getopts ":r:i:s:u:p:h" opt; do
  case $opt in
    r) REALM="$OPTARG"
    ;;
    i) CLIENT_ID="$OPTARG"
    ;;
    s) CLIENT_SECRET="$OPTARG"
    ;;
    u) USEREMAIL="$OPTARG"
    ;;
    p) USERPWD="$OPTARG"
    ;;
    h) echo "$0 -r -i -s -u -p -h"
    exit 0
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
    :) echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
  esac

  case ${OPTARG:-} in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

REALM=${REALM:-"hopsworks"}
CLIENT_ID=${CLIENT_ID:-"hopsworks-app0"}
CLIENT_SECRET=${CLIENT_SECRET:-"da9d22be-dc88-457f-ac03-33789699e140"}
USEREMAIL=${USEREMAIL:-"admin@hopsworks.ai"}
USERPWD=${USERPWD:-"adminpw"}

KEYCLOAK_URL=${KEYCLOAK_URL:-http://keycloak.iam.svc.cluster.local:8080}
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

curl --fail-with-body --silent --show-error "${KEYCLOAK_URL%/}/realms/$REALM/.well-known/openid-configuration" -o "$WORK_DIR/openid-configuration.json"

has_error=$(jq 'has("error")' "$WORK_DIR/openid-configuration.json")
if [ "$has_error" == true ]; then 
  jq -r '.error' "$WORK_DIR/openid-configuration.json"
  exit 1
fi

TOKEN_ENDPOINT=$(jq -er '.token_endpoint | select(type == "string" and length > 0)' "$WORK_DIR/openid-configuration.json")
USERINFO_ENDPOINT=$(jq -er '.userinfo_endpoint | select(type == "string" and length > 0)' "$WORK_DIR/openid-configuration.json")

# echo "$AUTH_ENDPOINT?response_type=code&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=openid+profile+email&redirect_uri=https://localhost:8181/callback"

curl --fail-with-body --silent --show-error \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "client_secret=$CLIENT_SECRET" \
  --data-urlencode "scope=openid profile email groups roles" \
  --data-urlencode "username=$USEREMAIL" \
  --data-urlencode "password=$USERPWD" \
  -d "grant_type=password" \
  "$TOKEN_ENDPOINT" -o "$WORK_DIR/oauth-token.json"

has_error=$(jq 'has("error")' "$WORK_DIR/oauth-token.json")
if [ "$has_error" == true ]; then 
  jq -r '.error_description' "$WORK_DIR/oauth-token.json"
  exit 1
fi

ACCESS_TOKEN=$(jq -er '.access_token | select(type == "string" and length > 0)' "$WORK_DIR/oauth-token.json")

curl --fail-with-body --silent --show-error \
  -H "Authorization: bearer $ACCESS_TOKEN" \
  "$USERINFO_ENDPOINT" | jq
