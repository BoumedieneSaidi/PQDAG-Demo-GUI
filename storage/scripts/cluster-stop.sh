#!/bin/sh
# Wrapper script to stop PQDAG cluster
# This script should be executed on the host where SSH keys are available

cd "$(dirname "$0")"
python3 ./stop-all /home/ubuntu/pqdag
