#!/bin/bash

if [[ "`whoami`" != "zimbra" ]]
then
    echo "Not running as zimbra user..."
    exit
else

    DOMAIN="$1"

    if [[ -z "${DOMAIN}" ]]
    then
        echo "You need to set the domain to export."
        exit
    else

        NFS="/mg/mx"

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating directory to domain ${DOMAIN} in ${NFS}/${DOMAIN}"
        SCRIPTS_DIR="${NFS}/${DOMAIN}/scripts"
        mkdir -p ${SCRIPTS_DIR}

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Writing a script to easily creation for domain and users in destination server"
        echo "#!/bin/bash" > ${SCRIPTS_DIR}/prepare_environment.sh
        echo "zmprov cd ${DOMAIN} zimbraPrefTimeZoneId America/Sao_Paulo zimbraPublicServiceProtocol https zimbraVirtualHostname webmail.${DOMAIN}" >> ${SCRIPTS_DIR}/prepare_environment.sh

        for ACCOUNT in `zmprov -l gaa ${DOMAIN} | egrep -v 'galsync|spam|ham|virus|stimpson'`
        do
            echo "zmprov ca ${ACCOUNT} \"Macromind@123\"" >> ${SCRIPTS_DIR}/prepare_environment.sh
            echo "zmprov ma ${ACCOUNT} zimbraPrefPop3DownloadSince \"$(date '+%Y%m%d%H%M%S'Z)\"" >> ${SCRIPTS_DIR}/prepare_environment.sh
            echo "zmmailbox -z -m ${ACCOUNT} addFilterRule \"DisableWarnings\" active any address \"from\" all contains \"MAILER-DAEMON\" discard" >> ${SCRIPTS_DIR}/prepare_environment.sh
            echo "zmmailbox -z -m ${ACCOUNT} addFilterRule \"AntispamTitle\" active any header \"subject\" contains \"SPAM\" fileinto \"Junk\"" >> ${SCRIPTS_DIR}/prepare_environment.sh
            echo "zmmailbox -z -m ${ACCOUNT} addFilterRule \"AntispamUnsubscribe\" active any header \"List-Unsubscribe\" exists fileinto \"Junk\"" >> ${SCRIPTS_DIR}/prepare_environment.sh
        done

        chmod 700 ${SCRIPTS_DIR}/prepare_environment.sh

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Exporting data of ${DOMAIN}"

        FILES_DIR="${NFS}/${DOMAIN}/files"
        mkdir -p ${FILES_DIR}

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Some adjustments to default settings..."
        zmprov mcf zimbraPublicServiceHostname $(hostname)
        zmprov mcf zimbraPublicServiceProtocol https
        zmprov mcf zimbraPublicServicePort 443

        zmprov md ${DOMAIN} zimbraPublicServiceHostname $(hostname)
        zmprov md ${DOMAIN} zimbraPublicServiceProtocol https
        zmprov md ${DOMAIN} zimbraPublicServicePort 443

        echo
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Settings OK..."

        for ACCOUNT in `zmprov -l gaa ${DOMAIN} | egrep -v 'galsync|spam|ham|virus|stimpson'`
        do
            TGZ="${FILES_DIR}/${ACCOUNT}.tgz"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating data file ${TGZ} of account ${ACCOUNT} "
            zmmailbox -z -m ${ACCOUNT} getRestURL "//?fmt=tgz" > ${TGZ}
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done..."
        done
    fi
fi
