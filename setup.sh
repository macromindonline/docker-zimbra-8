#!/bin/bash

apt update &>/dev/null && apt dist-upgrade -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update &>/dev/null && apt install docker-ce nfs-common -y
mkdir -p /mg/mx && mount 10.100.1.34:/mg/mx /mg/mx
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod 700 /usr/local/bin/docker-compose
systemctl disable systemd-resolved
systemctl stop systemd-resolved
unlink /etc/resolv.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf