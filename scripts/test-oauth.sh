#!/bin/bash

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
  esac

  case $OPTARG in
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

echo "REALM=$REALM, CLIENT_ID=$CLIENT_ID, CLIENT_SECRET=$CLIENT_SECRET, USEREMAIL=$USEREMAIL, USERPWD=$USERPWD"

curl -s "http://keycloak.hopsworks.svc.cluster.local:8080/realms/$REALM/.well-known/openid-configuration" -o /tmp/openid-configuration.json

has_error=$(jq 'has("error")' /tmp/openid-configuration.json)
if [ "$has_error" == true ]; then 
  jq -r '.error' /tmp/openid-configuration.json
  rm /tmp/openid-configuration.json
  exit 1
fi

AUTH_ENDPOINT=$(jq -r '.authorization_endpoint' /tmp/openid-configuration.json)
TOKEN_ENDPOINT=$(jq -r '.token_endpoint' /tmp/openid-configuration.json)
USERINFO_ENDPOINT=$(jq -r '.userinfo_endpoint' /tmp/openid-configuration.json)

# echo "$AUTH_ENDPOINT?response_type=code&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=openid+profile+email&redirect_uri=https://localhost:8181/callback"
touch /tmp/oauth-token.json

curl -s \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "scope=openid+profile+email+groups+roles" \
  -d "username=admin@hopsworks.ai" \
  -d "password=adminpw" \
  -d "grant_type=password" \
  "$TOKEN_ENDPOINT" -o /tmp/oauth-token.json

has_error=$(jq 'has("error")' /tmp/oauth-token.json)
if [ "$has_error" == true ]; then 
  jq -r '.error_description' /tmp/oauth-token.json
  rm /tmp/oauth-token.json
  exit 1
fi

ACCESS_TOKEN=$(jq -r '.access_token' /tmp/oauth-token.json)

curl -s \
  -H "Authorization: bearer $ACCESS_TOKEN" \
  "$USERINFO_ENDPOINT" | jq