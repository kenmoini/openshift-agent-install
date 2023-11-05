#!/bin/bash

# This script will download the target version of the OpenShift RHCOS Live ISO used for installation

# Set the version of OpenShift to install
OPENSHIFT_VERSION=${1}
ARCHITECTURE=${2:-x86_64}

# Check to see if there was an input parameter
if [ -z "${OPENSHIFT_VERSION}" ]; then
  echo "Usage: $0 <OpenShift Version x.y.z>"
  exit 1
fi

# Get the specified version of openshift-install
TMP_DIR=$(mktemp -d -t ocp-bin-XXXXX)
cd ${TMP_DIR}
wget https://mirror.openshift.com/pub/openshift-v4/${ARCHITECTURE}/clients/ocp/${OPENSHIFT_VERSION}/openshift-install-linux.tar.gz
tar zxvf openshift-install-linux.tar.gz
chmod a+x openshift-install

# Get the installer specific RHCOS image
RHCOS_ISO=$(./openshift-install coreos print-stream-json | jq -r '.architectures.'${ARCHITECTURE}'.artifacts.metal.formats.iso.disk.location')

# return to the script directory
cd ${OLDPWD}

# Download the RHCOS ISO
wget ${RHCOS_ISO}

# Clean up
rm -rf ${TMP_DIR}

echo "Move the ISO to the ~/.cache/agent/image_cache/coreos-${ARCHITECTURE}.iso path"