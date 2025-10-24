#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VAGRANT_DIR=$SCRIPT_DIR

export VAGRANT_DEFAULT_PROVIDER=${VAGRANT_DEFAULT_PROVIDER:-docker}
export VAGRANT_CWD=$VAGRANT_DIR

pushd "$VAGRANT_DIR" >/dev/null
rm -rf qemu.log

vagrant up --provider="$VAGRANT_DEFAULT_PROVIDER"
vagrant destroy -f

popd >/dev/null
