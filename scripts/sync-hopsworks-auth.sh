#!/bin/bash
set -euo pipefail
umask 077

IAM_NAMESPACE=${IAM_NAMESPACE:-iam}
HOPSWORKS_NAMESPACE=${HOPSWORKS_NAMESPACE:-hopsworks}
KEYTAB_SECRET=${KEYTAB_SECRET:-keytab-secret}
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

for resource in "secret/$KEYTAB_SECRET" secret/ldap-credentials-secret secret/hopsworks-app-client-secret configmap/server-krb5-config; do
  kubectl --namespace "$IAM_NAMESPACE" get "$resource" -o json |
    jq --arg namespace "$HOPSWORKS_NAMESPACE" --arg keytab "$KEYTAB_SECRET" \
      'if .kind == "Secret" and .metadata.name == $keytab then .data = {"service.keytab": .data["service.keytab"]} else . end |
       {apiVersion, kind, metadata: {name: .metadata.name, namespace: $namespace}, type, data} | with_entries(select(.value != null))' \
      > "$WORK_DIR/resource.json"
  kubectl --namespace "$HOPSWORKS_NAMESPACE" apply -f "$WORK_DIR/resource.json"
done
