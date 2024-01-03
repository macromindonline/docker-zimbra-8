#!/bin/bash

docker image rm -f zimbra-server
docker build --no-cache -t zimbra-server .
