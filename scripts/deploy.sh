#!/bin/bash

export KUBECONFIG=/home/ermias/Projects/Kube/dev2/kubeconfig.yaml
NAMESPACE=hopsworks
CHARTS=/home/ermias/Projects/ErmiasG/iam/helm

kubectl create namespace $NAMESPACE

helm install kerberos-release $CHARTS/charts/kerberos --namespace $NAMESPACE --values $CHARTS/values.yaml
helm install oauth-release $CHARTS/charts/oauth --namespace $NAMESPACE --values $CHARTS/values.yaml

#helm uninstall kerberos-release --namespace $NAMESPACE
#helm uninstall oauth-release --namespace $NAMESPACE
