#!/bin/bash
tmux new-session -d -s zimbra 'cd /root/docker-zimbra-8 && ./run.sh'
