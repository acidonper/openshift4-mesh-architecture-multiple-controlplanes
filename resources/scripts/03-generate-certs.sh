#!/bin/bash
##
# Script to generate trusted certificates for mTLS connections between control planes
##

CONTROL_PLANES="ingress
egress
workload"

CERTS_PATH="resources/certs"

## Generate mtls certificates

for i in $CONTROL_PLANES
do

cat <<EOF > ${CERTS_PATH}/${i}-openssl.conf
[req]
default_bits = 2048
encrypt_key  = no # Change to encrypt the private key using des3 or similar
default_md   = sha256
prompt       = no
utf8         = yes
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints     = CA:FALSE
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth, serverAuth
subjectAltName       = @alt_names
[alt_names]
DNS.1=*.mesh-$i.svc.cluster.local
DNS.2=*.apps.test.sandbox1196.opentlc.com
EOF

  ## Generate certificates 
  openssl req -out ${CERTS_PATH}/${i}.csr -newkey rsa:2048 -nodes -keyout ${CERTS_PATH}/${i}.key -subj "/"
  openssl x509 -req -days 365 -CA ${CERTS_PATH}/ca-cert.pem -CAkey ${CERTS_PATH}/ca-key.pem -CAcreateserial -in ${CERTS_PATH}/${i}.csr -out  ${CERTS_PATH}/${i}.crt -extensions v3_req -extfile ${CERTS_PATH}/${i}-openssl.conf
  
  ## Create secrets
  oc delete secret istio-mtls-cp-secret -n mesh-${i}
  oc create secret generic istio-mtls-cp-secret -n mesh-${i} --from-file=${CERTS_PATH}/${i}.key --from-file=${CERTS_PATH}/${i}.crt --from-file=${CERTS_PATH}/ca-cert.pem

  ## Patch Control Planes
  oc patch smcp -n mesh-${i} mesh-${i} --patch-file resources/control_planes/${i}/${i}-smcp-patch.yaml --type=merge

done

## Generate routed traffic certificate
cat <<EOF > ${CERTS_PATH}/routed-openssl.conf
[req]
default_bits = 2048
encrypt_key  = no # Change to encrypt the private key using des3 or similar
default_md   = sha256
prompt       = no
utf8         = yes
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints     = CA:FALSE
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth, serverAuth
subjectAltName       = @alt_names
[alt_names]
DNS.1=*.apps.test.sandbox1196.opentlc.com
EOF

openssl req -out ${CERTS_PATH}/routed.csr -newkey rsa:2048 -nodes -keyout ${CERTS_PATH}/routed.key -subj "/"
openssl x509 -req -days 365 -CA ${CERTS_PATH}/ca-cert.pem -CAkey ${CERTS_PATH}/ca-key.pem -CAcreateserial -in ${CERTS_PATH}/routed.csr -out  ${CERTS_PATH}/routed.crt -extensions v3_req -extfile ${CERTS_PATH}/routed-openssl.conf
oc delete secret istio-ssl-cp-secret -n mesh-ingress
oc create secret tls istio-ssl-cp-secret -n mesh-ingress --key=${CERTS_PATH}/routed.key --cert=${CERTS_PATH}/routed.crt
