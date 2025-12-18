#!/bin/sh
# Wrapper script to start PQDAG cluster
# This script should be executed on the host where SSH keys are available

cd "$(dirname "$0")"
python3 ./start-all /home/ubuntu/pqdag
