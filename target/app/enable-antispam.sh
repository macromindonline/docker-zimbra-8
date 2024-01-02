#!/bin/bash

if [[ "`whoami`" != "zimbra" ]]
then
    echo "Not running as zimbra user..."
    exit
else

    delFilter() {

        FILTERS=("DisableWarnings" "AntispamTitle" "AntispamUnsubscribe")
        ACCOUNT=${1}

        for TAG in ${FILTERS[@]}
        do
            if /opt/zimbra/bin/zmmailbox -z -m ${ACCOUNT} getFilterRules | grep ${TAG} >/dev/null
            then
                echo "Removing rule ${TAG} of ${ACCOUNT}"
                /opt/zimbra/bin/zmmailbox -z -m ${ACCOUNT} deleteFilterRule ${TAG}
            fi
        done
    }

    addFilter() {

        ACCOUNT=${1}

        echo "${ACCOUNT} => DisableWarnings"
        /opt/zimbra/bin/zmmailbox -z -m ${ACCOUNT} addFilterRule "DisableWarnings" active any address "from" all contains "MAILER-DAEMON" discard

        echo "${ACCOUNT} => AntispamTitle"
        /opt/zimbra/bin/zmmailbox -z -m ${ACCOUNT} addFilterRule "AntispamTitle" active any header "subject" contains "SPAM" fileinto "Junk"

        echo "${ACCOUNT} => AntispamUnsubscribe"
        /opt/zimbra/bin/zmmailbox -z -m ${ACCOUNT} addFilterRule "AntispamUnsubscribe" active any header "List-Unsubscribe" exists fileinto "Junk"
    }

    /opt/zimbra/bin/zmprov -l gaa | while read ACCOUNT;
    do
        echo "Updating rules for ${ACCOUNT}"
        delFilter ${ACCOUNT}
        addFilter ${ACCOUNT}
        echo "Done."
    done
fi
