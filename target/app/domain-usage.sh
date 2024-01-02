#!/bin/bash

output="/tmp/account_usage"
domain="$1"
#send_to="idc@macromind.online"

rm -f $output
touch $output

server=`zmhostname`
/opt/zimbra/bin/zmprov gqu $server|grep $domain|awk {'print $1" "$3" "$2'}|sort|while read line
do
    usage=`echo $line|cut -f2 -d " "`
    quota=`echo $line|cut -f3 -d " "`
    user=`echo $line|cut -f1 -d " "`
    status=`/opt/zimbra/bin/zmprov ga $user | grep  ^zimbraAccountStatus | cut -f2 -d " "`
    echo "$user `expr $usage / 1024 / 1024`Mb `expr $quota / 1024 / 1024`Mb ($status account)" >> $output
done

#cat $output | mail @send_to -s"Mailbox Usages for $domain"