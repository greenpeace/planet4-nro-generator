#!/bin/sh
set -e

ls -al /tmp/.ssh

cp -R /tmp/.ssh/* /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*

ls -al /root/.ssh

exec "$@"
