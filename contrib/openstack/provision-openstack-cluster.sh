#!/usr/bin/env bash
#
# Usage: ./provision-openstack-cluster.sh <key pair name> [flavor]
#
# Supported environment variables:
#    DEIS_DNS: Comma separated list of names servers for use in the deis private network (default: none)
#    DEIS_NUM_INSTANCES: Number of instances to create (default: 3)

set -e

THIS_DIR=$(cd $(dirname $0); pwd) # absolute path
CONTRIB_DIR=$(dirname $THIS_DIR)

source $CONTRIB_DIR/utils.sh

if [ -z "$2" ]; then
  echo_red 'Usage: provision-openstack-cluster.sh <coreos image name/id> <key pair name> [flavor]'
  exit 1
fi
COREOS_IMAGE=$1
KEYPAIR=$2

if ! which nova > /dev/null; then
  echo_red 'Please install nova and ensure it is in your $PATH.'
  exit 1
fi

if ! which neutron > /dev/null; then
  echo_red 'Please install neutron and ensure it is in your $PATH.'
  exit 1
fi

if [ -z "$3" ]; then
  FLAVOR="DEIS"
else
  FLAVOR=$3
fi

if [ -z "$OS_AUTH_URL" ]; then
  echo_red "nova credentials are not set. Please source openrc.sh"
  exit 1
fi

#if ! nova network-list|grep -q net_deis &>/dev/null; then
#  echo_yellow "Creating deis private network..."
#  CIDR=${DEIS_CIDR:-10.21.12.0/24}
#  SUBNET_OPTIONS=""
#  [ ! -z "$DEIS_DNS" ] && SUBNET_OPTIONS=$(echo $DEIS_DNS|awk -F "," '{for (i=1; i<=NF; i++) printf "--dns-nameserver %s ", $i}')
#  NETWORK_ID=$(neutron net-create net_deis | awk '{ printf "%s", ($2 == "id" ? $4 : "")}')
#  echo "DBG: SUBNET_OPTIONS=$SUBNET_OPTIONS"
#  SUBNET_ID=$(neutron subnet-create --name deis_subnet $SUBNET_OPTIONS deis $CIDR| awk '{ printf "%s", ($2 == "id" ? $4 : "")}')
#else
  NETWORK_ID=$(neutron net-list | awk '{printf "%s", ($4 == "net_deis" ? $2 : "")}')
#fi


if [ -z "$DEIS_NUM_INSTANCES" ]; then
    DEIS_NUM_INSTANCES=5
fi

# check that the CoreOS user-data file is valid
$CONTRIB_DIR/util/check-user-data.sh

i=1 ; while [[ $i -le $DEIS_NUM_INSTANCES ]] ; do \
    echo_yellow "Provisioning deis-$i..."
    nova boot --image $COREOS_IMAGE --flavor $FLAVOR --key-name $KEYPAIR --user-data ../coreos/user-data --nic net-id=$NETWORK_ID deis-$i ; \
    ((i = i + 1)) ; \
done

echo_green "Your Deis cluster has successfully deployed to OpenStack."
echo_green "Please continue to follow the instructions in the README."
