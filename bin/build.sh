#!/bin/bash

set -euxo pipefail

script_dir="$(dirname "$0")"

source "$script_dir/../.venv/bin/activate"
ansible-galaxy collection build --force --output-path "$script_dir/../dist" "$script_dir/../"
