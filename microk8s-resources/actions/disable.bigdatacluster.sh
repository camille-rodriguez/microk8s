#!/usr/bin/env bash

set -e

source $SNAP/actions/common/utils.sh

echo "Disabling Big Data Clusters"

KUBECTL="$SNAP/kubectl --kubeconfig=${SNAP_DATA}/credentials/client.config"

$KUBECTL delete namespace mssql-cluster

echo "BDC has been removed."
