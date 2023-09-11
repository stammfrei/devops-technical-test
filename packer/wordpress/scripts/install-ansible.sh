#! /usr/bin/env bash
# Install ansible on a python:3.x.x-bookworm image
# shellcheck disable=1091

# Creating a venv in /opt/ansible
mkdir -p /opt
cd /opt || (echo 2>&1 "failed to cd to /opt" && exit 1)

python3 -m venv ansible
source ansible/bin/activate

# Install ansible in the venv
pip install ansible-core

# install an ansible wrapper script that will uses the virtualenv
cat <<'EOF' >/opt/ansible.sh
#! /bin/bash

source /opt/ansible/bin/activate

ansible-playbook "$@"
EOF

chmod +x /opt/ansible.sh
