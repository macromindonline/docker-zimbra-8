#!/bin/bash
apt update &>/dev/null
apt install nfs-common -y
mkdir -p /mg/mx