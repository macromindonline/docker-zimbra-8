#!/bin/bash

if [ ! -f "env.prod" ]; then
    echo "Please, create a env.prod file based on env.example to set HOSTNAME variable."
    exit
fi

IPV4=`ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1`
grep -v '^#' env.prod
export $(grep -v '^#' env.prod | xargs)

docker run -it \
    --rm \
    --hostname $HOSTNAME \
    --name $HOSTNAME \
    -p $IPV4:25:25 \
    -p $IPV4:80:80 \
    -p $IPV4:110:110 \
    -p $IPV4:143:143 \
    -p $IPV4:443:443 \
    -p $IPV4:465:465 \
    -p $IPV4:587:587 \
    -p $IPV4:993:993  \
    -p $IPV4:995:995 \
    -p $IPV4:5222:5222 \
    -p $IPV4:5223:5223 \
    -p $IPV4:7071:7071 \
    -p $IPV4:7780:7780 \
    --volume $PWD/data:/data \
    --volume /mg/mx:/data/mg/mx \
    --cap-add NET_ADMIN \
    --cap-add SYS_ADMIN \
    --cap-add SYS_PTRACE \
    --security-opt apparmor=unconfined \
    zimbra-server \
    run-and-enter

# docker run -it --rm --hostname $HOSTNAME -p $IPV4:25:25 -p $IPV4:80:80 -p $IPV4:110:110 -p $IPV4:143:143 -p $IPV4:443:443 -p $IPV4:465:465 -p $IPV4:587:587 -p $IPV4:993:993 -p $IPV4:995:995 -p $IPV4:5222:5222 -p $IPV4:5223:5223 -p $IPV4:7071:7071 --volume $PWD/data:/data --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add SYS_PTRACE --security-opt apparmor=unconfined zimbra-server run-and-enter
