#!/bin/sh
# Copy SSH keys to writable location with correct permissions
mkdir -p /tmp/.ssh
cp -r /root/.ssh/* /tmp/.ssh/ 2>/dev/null || true
chmod 700 /tmp/.ssh
chmod 600 /tmp/.ssh/id_rsa 2>/dev/null || true
chmod 600 /tmp/.ssh/pqdag 2>/dev/null || true

# Export SSH directory
export HOME_SSH=/tmp/.ssh

# Run the application with SSH configured
exec java -jar -Duser.home.ssh=/tmp/.ssh app.jar
