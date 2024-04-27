#!/bin/bash

set -e

project_dir=$(dirname $(dirname $(cd $(dirname $0); pwd)))

py3=$(which python3.8 || which python3)

$py3 -m pip install --user -U pip

# ./scripts/install_deps.sh
