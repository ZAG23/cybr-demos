#!/bin/bash
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/credential_providers/agent_ubuntu"

cd "$demo_path/setup"
./install.sh
