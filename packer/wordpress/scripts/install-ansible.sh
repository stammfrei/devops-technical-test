#! /usr/bin/env bash
# Install ansible on a python:3.x.x-bookworm image
# shellcheck disable=1091

# Creating a venv in /opt/ansible
mkdir -p /opt
cd /opt || (echo 2>&1 "failed to cd to /opt" && exit 1)

python -m venv ansible
source ansible/bin/activate

# Install ansible in the venv
pip install ansible-core
