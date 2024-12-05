#!/bin/bash

export KUBECONFIG=/home/ermias/Projects/Kube/dev1/kubeconfig.yaml
NAMESPACE=hopsworks
CHARTS=/home/ermias/Projects/ErmiasG/iam/helm

helm install oauth-release $CHARTS/charts/oauth --namespace $NAMESPACE --values $CHARTS/values.yaml

helm uninstall oauth-release --namespace $NAMESPACE
