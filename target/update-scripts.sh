#!/bin/bash

ZIMBRA_ENVIRONMENT_PATH="../data"

echo "Copying customized scripts"
mkdir -p $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts

cp app/certbot-zimbra.sh $ZIMBRA_ENVIRONMENT_PATH/root/
cp app/queue-delete.pl $ZIMBRA_ENVIRONMENT_PATH/root/

cp app/zcs-export.sh $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/
cp app/zcs-import.sh $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/
cp app/enable-antispam.sh $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/
cp app/change-date-pop.sh $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/

echo "Setting customized permissions"
chmod 750 $ZIMBRA_ENVIRONMENT_PATH/root/certbot-zimbra.sh
chmod 750 $ZIMBRA_ENVIRONMENT_PATH/root/queue-delete.pl

chmod 750 $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/zcs-export.sh
chmod 750 $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/zcs-import.sh
chmod 750 $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/enable-antispam.sh
chmod 750 $ZIMBRA_ENVIRONMENT_PATH/opt/zimbra/scripts/change-date-pop.sh

echo
echo "Done!"
