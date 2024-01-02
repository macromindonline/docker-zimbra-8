#!/bin/bash

zmprov -l gad | while read DOMAIN;
do
    echo "Starting update on ${DOMAIN}"

    zmprov -l gaa ${DOMAIN} | while read ACCOUNT;
    do
        echo "Updating account ${ACCOUNT} to $(date \"+%Y%m%d%H%M%S\"Z)"
        zmprov ma ${ACCOUNT} zimbraPrefPop3DownloadSince $(date "+%Y%m%d%H%M%S"Z)
        echo "Done."
    done

    echo "Domain ${DOMAIN} updated!"
done