#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
NAMESPACE=${NAMESPACE:-iam}
RELEASE=${RELEASE:-iam}
CHARTS=${CHARTS:-"$SCRIPT_DIR/../helm"}

helm upgrade --install "$RELEASE" "$CHARTS" \
  --namespace "$NAMESPACE" --create-namespace --wait --timeout 10m "$@"
