#!/bin/sh

# Desc: Connect to the Kubernetes cluster control node and open a browser
# 
# Args: None
#
# Notes:
#   This assumes that the user's public key is authorized on the kubernetes control node
#
# Authors:
#   David Newman

cleanup() {
    echo cleanup
    kill $SSH_PID
    exit
}

echo connecting to kubernetes control node...

# tunnel local port 6443
ssh -N -L 6443:127.0.0.1:6443 ec2-user@ec2-18-217-177-192.us-east-2.compute.amazonaws.com &
SSH_PID=$!

echo $SSH_PID
trap cleanup INT TERM

sleep 3
echo opening browser...

# open a browser
xdg-open "https://127.0.0.1:6443" > /dev/null 2> /dev/null

while :; do
    sleep 1
done
