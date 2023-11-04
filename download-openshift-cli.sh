#!/bin/bash

mkdir -p ./bin
cd ./bin

wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz

tar zxvf openshift-client-linux.tar.gz
rm -f openshift-client-linux.tar.gz

wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz

tar zxvf openshift-install-linux.tar.gz
rm -f openshift-install-linux.tar.gz

rm README.md

chmod a+x oc
chmod a+x kubectl
chmod a+x openshift-install
