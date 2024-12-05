#!/bin/bash

CLIENT_ID=${1:-"hopsworks-app"}
CLIENT_SECRET=${2:-"da9d22be-dc88-457f-ac03-33789699e140"}

curl -s "http://localhost:8080/realms/hopsworks/.well-known/openid-configuration" -o /tmp/openid-configuration.json

AUTH_ENDPOINT=$(jq -r '.authorization_endpoint' /tmp/openid-configuration.json)
TOKEN_ENDPOINT=$(jq -r '.token_endpoint' /tmp/openid-configuration.json)
USERINFO_ENDPOINT=$(jq -r '.userinfo_endpoint' /tmp/openid-configuration.json)

# echo "$AUTH_ENDPOINT?response_type=code&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=openid+profile+email&redirect_uri=https://localhost:8181/callback"

curl \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "username=admin@hopsworks.ai" \
  -d "password=admin" \
  -d "grant_type=password" \
  "$TOKEN_ENDPOINT"