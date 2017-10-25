#!/bin/bash

set -e
set -x

rm -rf playbooks

kubespray aws -y --config kubespray.yml --nodes 2

pushd playbooks
# git reset --hard cfea99c4ee56f8d7afe176fdc4a172f610bdc333
popd

rm -rf playbooks/inventory/group_vars
cp -a group_vars playbooks/inventory/

IPS=$(cat playbooks/nodes_instances.json | jq -r .[].public_ip)
for IP in $IPS; do
	ssh-keygen -R $IP
	ssh-keyscan -H $IP >> ~/.ssh/known_hosts
	ssh ubuntu@$IP -- "sudo DEBIAN_FRONTEND=noninteractive apt-get -y update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade && sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python"
done

# Use -r on Linux.
sed -E -i'' -e 's/(ansible_ssh_host[^\s]*)/\1   ansible_ssh_user=ubuntu/g' playbooks/inventory/inventory.cfg

kubespray deploy -y --aws --ubuntu --config kubespray.yml