#!/bin/bash

if [[ "`whoami`" != "zimbra" ]]
then
    echo "Not running as zimbra user..."
    exit
else
    echo "Ok, running as zimbra..."
    DOMAIN="$1"

    if [[ -z "${DOMAIN}" ]]
    then
        echo "You need to set the domain to export."
        exit
    else

        NFS="/mg/mx"

        echo
        echo "Creating directory to domain ${DOMAIN} in ${NFS}/${DOMAIN}"
        mkdir ${NFS}/${DOMAIN}

        echo
        echo "Exporting data of ${DOMAIN}"
        
        for ACCOUNT in `zmprov -l gaa ${DOMAIN} | egrep -v 'galsync|spam|ham|virus|stimpson'`
        do
            TGZ="${NFS}/${DOMAIN}/${ACCOUNT}.tgz"
            echo "Creating data file ${TGZ} of account ${ACCOUNT} "
            zmmailbox -z -m ${ACCOUNT} getRestURL "//?fmt=tgz" > ${TGZ}
            echo "Done..."
        done
    fi
fi