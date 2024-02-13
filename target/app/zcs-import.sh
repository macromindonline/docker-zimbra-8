#!/bin/bash

if [[ "`whoami`" != "zimbra" ]]; then
    echo "Not running as zimbra user..."
    exit
else

    DOMAIN="$1"

    if [[ -z "${DOMAIN}" ]]; then
        echo "You need to set the domain to export."
        exit
    else

        SOURCE="/mg/mx/${DOMAIN}/files"
        IMPORTED="${SOURCE}/imported"

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Importing data of ${DOMAIN}"

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Some adjustments to default settings..."
        zmprov mcf zimbraPublicServiceHostname $(hostname)
        zmprov mcf zimbraPublicServiceProtocol https
        zmprov mcf zimbraPublicServicePort 443
        
        zmprov md ${DOMAIN} zimbraPublicServiceHostname $(hostname)
        zmprov md ${DOMAIN} zimbraPublicServiceProtocol https
        zmprov md ${DOMAIN} zimbraPublicServicePort 443

        zmlocalconfig -e mailboxd_java_heap_memory_percent=40
        zmlocalconfig -e mysql_memory_percent=30
        zmlocalconfig -e socket_so_timeout=3000000       
        
        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Settings OK..."

        for ACCOUNT_FILE in `ls ${SOURCE}`
        do
            ACCOUNT_NAME=`echo ${ACCOUNT_FILE%.*}`
            ERROR_COUNT=0
            
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Opening ${ACCOUNT_FILE} and importing into ${ACCOUNT_NAME}"
            TGZ="${SOURCE}/${ACCOUNT_FILE}"

            while true; do

                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing zmmailbox to post file..."
                OUTPUT=$(zmmailbox -z -m ${ACCOUNT_NAME} -t 0 postRestURL "//?fmt=tgz&resolve=skip" ${TGZ} 2>&1)
                STATUS=$?

                if [[ $STATUS -eq 0 && ! $OUTPUT =~ "Read timed out" ]]; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Imported sucessfully, moving to another folder..."
                    mv ${TGZ} ${IMPORTED}
                    break
                else
                    ((ERROR_COUNT++))
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Read timed out, trying again - ${ERROR_COUNT}"
                    sleep 5
                fi
            done

            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done..."
        done

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Data successfuly imported of ${DOMAIN}"
        zmlocalconfig -u socket_so_timeout
    fi
fi
