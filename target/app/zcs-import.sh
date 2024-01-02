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

        zmprov cd ${DOMAIN} zimbraPrefTimeZoneId America/Sao_Paulo zimbraPublicServiceProtocol https zimbraVirtualHostname webmail.${DOMAIN}

        NFS="/mg/mx"

        echo
        echo "Importing data of ${DOMAIN}"

        for ACCOUNT_FILE in `ls ${NFS}/${DOMAIN}`
        do
            ACCOUNT_NAME=`echo ${ACCOUNT_FILE%.*}`
            echo "Creating account ${ACCOUNT_NAME}"
            zmprov ca ${ACCOUNT_NAME} ChangeMe@123
            echo "Configuring Pop3 download date to ${ACCOUNT_NAME}"
            zmprov ma ${ACCOUNT_NAME} zimbraPrefPop3DownloadSince $(date "+%Y%m%d%H%M%S"Z)
            echo "Force ${ACCOUNT_NAME} to change password at next logon"
            zmprov ma ${ACCOUNT_NAME} zimbraPasswordMustChange TRUE
            echo "${ACCOUNT_NAME} => DisableWarnings"
            zmmailbox -z -m ${ACCOUNT_NAME} addFilterRule "DisableWarnings" active any address "from" all contains "MAILER-DAEMON" discard
            echo "${ACCOUNT_NAME} => AntispamTitle"
            zmmailbox -z -m ${ACCOUNT_NAME} addFilterRule "AntispamTitle" active any header "subject" contains "SPAM" fileinto "Junk"
            echo "${ACCOUNT_NAME} => AntispamUnsubscribe"
            zmmailbox -z -m ${ACCOUNT_NAME} addFilterRule "AntispamUnsubscribe" active any header "List-Unsubscribe" exists fileinto "Junk"
            echo "Opening ${ACCOUNT_FILE} and importing to ${ACCOUNT_NAME}"
            TGZ="${NFS}/${DOMAIN}/${ACCOUNT_FILE}"
            zmmailbox -z -m ${ACCOUNT_NAME} postRestURL "//?fmt=tgz&resolve=skip" ${TGZ}
            echo "Done..."
        done
    fi
fi