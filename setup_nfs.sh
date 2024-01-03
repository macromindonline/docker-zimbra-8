#!/bin/bash
apt update &>/dev/null
apt install nfs-common -y
mkdir -p /mg/mx
mount 10.100.1.34:/mg/mx /mg/mx