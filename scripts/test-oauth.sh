#!/bin/bash

CLIENT_ID=${1:-"hopsworks-app"}
CLIENT_SECRET=${2:-"da9d22be-dc88-457f-ac03-33789699e140"}

curl -s "http://keycloak.hopsworks.svc.cluster.local:8080/realms/hopsworks9/.well-known/openid-configuration" -o /tmp/openid-configuration.json

AUTH_ENDPOINT=$(jq -r '.authorization_endpoint' /tmp/openid-configuration.json)
TOKEN_ENDPOINT=$(jq -r '.token_endpoint' /tmp/openid-configuration.json)
USERINFO_ENDPOINT=$(jq -r '.userinfo_endpoint' /tmp/openid-configuration.json)

# echo "$AUTH_ENDPOINT?response_type=code&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=openid+profile+email&redirect_uri=https://localhost:8181/callback"

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