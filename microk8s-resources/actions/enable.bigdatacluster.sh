#!/usr/bin/env bash

set -e

source $SNAP/actions/common/utils.sh

min_mem_gb=64
config_profile_path=${SNAP}/actions/bdc
username="${AZDATA_USERNAME:-admin}"
password="${AZDATA_PASSWORD:-MyC0m9l&xP@ssw0rd}"
KUBECONFIG="${SNAP_DATA}"/credentials/client.config

echo "----------------------------------------"
echo "Installation of Microsoft Big Data Cluster"
echo "Warning: This installation requires the download of additional packages to the host system."
echo "----------------------------------------"

echo "----------------------------------------"
echo "Verifying system requirements..."
echo "----------------------------------------"

total_mem=$(awk '($1=="MemTotal:" && $2~/^[0-9]+$/){print $2}' /proc/meminfo)
if [[ total_mem -lt min_mem_gb*1024*1024 ]]; then
  echo "The recommended minimum RAM to run Microsoft Big Data Clusters is 64GB. Aborting the deployment."
  exit 1
else
  echo "Sufficient memory found."
fi

ubuntu_version=$(lsb_release --short --release)
if [[ ubuntu_version == '16.04' ]] ; then
  package_url='https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2019.list'
  echo "OS version confirmed, proceeding."
elif [[ ubuntu_version == '18.04' ]]; then
  package_url='https://packages.microsoft.com/config/ubuntu/18.04/mssql-server-2019.list)'
  echo "OS version confirmed, proceeding."
else
  echo "The ubuntu version detected ($ubuntu_version) is not compatible with BDC. Please install this addon on either Ubuntu 16.04 or 18.04."
  exit 1
fi

echo "----------------------------------------"
echo "Installing azdata cli"
echo "----------------------------------------"
run_with_sudo apt-get update
run_with_sudo apt-get install gnupg ca-certificates curl wget software-properties-common apt-transport-https lsb-release -y
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
run_with_sudo add-apt-repository "$(wget -qO- ${package_url})"
run_with_sudo apt-get update
run_with_sudo apt-get install -y azdata-cli


echo "----------------------------------------"
echo "Enabling dns and storage addons"
echo "----------------------------------------"
"$SNAP/microk8s-enable.wrapper" dns storage
sleep 5


sudo snap install kubectl --classic
#mkdir ~/.kube
#run_with_sudo microk8s.kubectl config view --raw > .kube/config #or export KUBECONFIG=path/to/.kube/config

#we should deploy from a template already generated here
#microk8s creates a local storage, let's test with that
#vi /var/snap/microk8s/current/args/kube-apiserver -> add a line > --allow-privileged and restart microk8s CAN BE AVOIDED WITH FOLLOWING
# azdata bdc config init --source kubeadm-dev-test --target dev-test --accept-eula='yes'
# azdata bdc config patch --config-file dev-test/control.json --patch-file storageclass-patch.json
# azdata bdc config patch --config-file dev-test/control.json --patch-file elasticsearch-patch.json

echo "----------------------------------------"
echo "Deploying BDC with azdata"
echo "----------------------------------------"
azdata bdc create --config-profile ${config_profile_path} --accept-eula='yes'

