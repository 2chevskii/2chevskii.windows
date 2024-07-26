#!/bin/bash

set -euxo pipefail

script_dir="$(dirname "$0")"

if [[ ! -d "$script_dir/../.venv" ]]; then
  python3 -m venv "$script_dir/../.venv"
fi

source "$script_dir/../.venv/bin/activate"
pip install -r "$script_dir/../requirements.txt"
