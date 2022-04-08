#!/bin/bash
##
# Create & Deploy Red Hat Service Mesh Control Planes
##

## Creating Application Namespace
oc new-project jump-app-dev

## Defining control plane namespaces
NS_PREFIX="ingress
egress
workload"

## Creating namespaces and installing the different controlplanes
for i in $NS_PREFIX
do
  oc new-project mesh-${i}
  oc create secret generic istio-ca-secret -n mesh-${i} --from-file=resources/certs/ca-cert.pem --from-file=resources/certs/ca-key.pem --type=istio.io/ca-root
  oc apply -f resources/control_planes/${i}/${i}-smcp.yaml -n mesh-${i}
  oc apply -f resources/control_planes/${i}/${i}-smmr.yaml -n mesh-${i}
  oc wait --for condition=Ready -n mesh-${i} smmr/default --timeout 300s -n mesh-${i}
done

