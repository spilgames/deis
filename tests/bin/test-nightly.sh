#!/bin/bash
#
# Preps a test environment and runs `make test-integration` with single-node vagrant.

echo Testing ${DEIS_TEST_APP?}...
THIS_DIR=$(cd $(dirname $0); pwd)  # absolute path

cd ${GOPATH?}/src/github.com/deis/deis
echo DEISCTL_TUNNEL=${DEISCTL_TUNNEL?}

# Environment reset and configuration
rm -rf ~/.deis
ssh-add -D || eval $(ssh-agent) && ssh-add -D
ssh-add ~/.vagrant.d/insecure_private_key
ssh-add ~/.ssh/deis
$THIS_DIR/halt-all-vagrants.sh
vagrant destroy --force
rm -rf tests/example-*

set -e

if ! [[ -x deisctl ]]; then
    curl -sSL http://deis.io/deisctl/install.sh | sudo sh
fi

vagrant up --provider virtualbox
deisctl install platform
deisctl start platform
make test-integration
deisctl uninstall platform
vagrant halt
