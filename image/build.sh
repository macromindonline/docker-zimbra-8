#!/bin/bash

docker image rm -f zimbra-server
docker build -t zimbra-server .
