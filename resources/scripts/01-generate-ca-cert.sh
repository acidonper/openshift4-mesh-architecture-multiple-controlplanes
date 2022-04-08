#!/bin/bash
##
# Generate CA Certificates
##

mkdir resources/certs/
openssl genrsa -out resources/certs/ca-key.pem 2048
openssl req -x509 -sha256 -new -nodes -key resources/certs/ca-key.pem -days 3650 -out resources/certs/ca-cert.pem
