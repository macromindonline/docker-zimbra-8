#!/bin/bash

set -e

ZIMBRA_DOWNLOAD_URL="https://files.zimbra.com/downloads/8.8.15_GA/zcs-8.8.15_GA_3869.UBUNTU18_64.20190918004220.tgz"
ZIMBRA_DOWNLOAD_HASH="88100cc5f8ffc8a806a7644ea15a4d38afaffeb7ea85ec452cad3a0680c5d46d"
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# abort, if the shell is not attached to a terminal
# (the menu-driven installation script requires user interaction)
if [ ! -t 0 ]; then
    echo "The executing shell is not attached to a terminal."
    echo "Aborting installation of Zimbra as the menu-driven setup script requires user interaction."
    echo "Please open a shell in the container and run /app/install-zimbra.sh manually..."
    exit 0
fi

# download zimbra
echo
echo "Downloading Zimbra..."
mkdir -p /install
cd /install
wget -O zcs.tgz $ZIMBRA_DOWNLOAD_URL
CALC_HASH=`sha256sum zcs.tgz | cut -d ' ' -f1`
if [ "$CALC_HASH" != "$ZIMBRA_DOWNLOAD_HASH" ]; then
    echo "Downloaded file is corrupt!"
    exit 1
fi

echo
echo "Extracting Zimbra..."
mkdir zcs
tar -C zcs -xvzf zcs.tgz --strip-components=1
apt-key add /app/zimbra.pub
sed -i 's/grep[[:space:]]-w[[:space:]]9BE6ED79/grep -w 9BE6/g' zcs/util/utilfunc.sh

echo
echo "Installing Zimbra..."
cd zcs
./install.sh

echo
echo "Retrieving some information needed for further steps..."
#ADMIN_EMAIL=`sudo -u zimbra /opt/zimbra/bin/zmlocalconfig smtp_destination | cut -d ' ' -f3`
ADMIN_EMAIL="sysadmin@macromind.net"
echo "- Admin e-mail address: $ADMIN_EMAIL"

# --- auditswatch: oficial -> mirror GitHub -> aviso (à prova de set -e) ---
mkdir -p /install/auditswatch && cd /install/auditswatch
OFICIAL="https://bugzilla-attach.zimbra.com/attachment.cgi?id=66723"
MIRROR="https://raw.githubusercontent.com/macromindonline/docker-zimbra-8/refs/heads/main/target/app/auditswatch"
_aud_ok() { [ -s auditswatch ] && head -1 auditswatch | grep -q '^#!.*perl'; }

echo "Baixando auditswatch (fonte oficial)..."
wget -q -O auditswatch "$OFICIAL" || true          # <-- || true impede o set -e de matar
_aud_ok || { echo "Oficial falhou; tentando mirror GitHub..."; wget -q -O auditswatch "$MIRROR" || true; }

if _aud_ok; then
    mv auditswatch /opt/zimbra/libexec/auditswatch
    chown root:root /opt/zimbra/libexec/auditswatch
    chmod 0755 /opt/zimbra/libexec/auditswatch
    sudo -u zimbra -- /opt/zimbra/bin/zmlocalconfig -e zimbra_swatch_notice_user=sysadmin@macromind.net
    sudo -u zimbra -- /opt/zimbra/bin/zmlocalconfig -e zimbra_swatch_threshold_seconds=3600
    sudo -u zimbra -- /opt/zimbra/bin/zmlocalconfig -e zimbra_swatch_ipacct_threshold=10
    sudo -u zimbra -- /opt/zimbra/bin/zmlocalconfig -e zimbra_swatch_acct_threshold=15
    sudo -u zimbra -- /opt/zimbra/bin/zmlocalconfig -e zimbra_swatch_ip_threshold=20
    sudo -u zimbra -- /opt/zimbra/bin/zmlocalconfig -e zimbra_swatch_total_threshold=100
    sudo -u zimbra -- /opt/zimbra/bin/zmauditswatchctl start
    echo "auditswatch OK"
else
    echo "AVISO: auditswatch indisponivel; seguindo sem ele."
fi

echo
echo "Removing Zimbra installation files..."
cd /
rm -Rv /install

echo
echo "Adding Zimbra's Perl include path to search path..."
echo 'PERL5LIB="/opt/zimbra/common/lib/perl5"' >> /etc/environment

echo
echo "Generating stronger DH parameters (4096 bit)..."
sudo -u zimbra /opt/zimbra/bin/zmdhparam set -new 4096

echo
echo "Configuring cipher suites (as strong as possible without breaking compatibility and sacrificing speed)..."
sudo -u zimbra /opt/zimbra/bin/zmprov mcf zimbraReverseProxySSLCiphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA'
sudo -u zimbra /opt/zimbra/bin/zmprov mcf zimbraMtaSmtpdTlsCiphers high
sudo -u zimbra /opt/zimbra/bin/zmprov mcf zimbraMtaSmtpdTlsProtocols '!SSLv2,!SSLv3'
sudo -u zimbra /opt/zimbra/bin/zmprov mcf zimbraMtaSmtpdTlsMandatoryCiphers high
sudo -u zimbra /opt/zimbra/bin/zmprov mcf zimbraMtaSmtpdTlsExcludeCiphers 'aNULL,MD5,DES'

echo
echo "Configuring default COS to use selected persona in the Return-Path of the mail envelope (important for privacy)."
sudo -u zimbra /opt/zimbra/bin/zmprov mc default zimbraSmtpRestrictEnvelopeFrom FALSE

echo
echo "Installing mail utilities to enable unattended-upgrades to send notifications."
echo "(Can be done after installing Zimbra only as bsd-mailx pulls in postfix that conflicts with the postfix package deployed by Zimbra.)"
apt install bsd-mailx -y

# let the container start Zimbra services next time
rm -f /.dont_start_zimbra

echo
echo "Disabling Antivirus and Antispam - Using MACROMIND Antispam cluster solution"
sudo -u zimbra /opt/zimbra/bin/zmprov -l ms `hostname -f` -zimbraServiceEnabled antispam 
sudo -u zimbra /opt/zimbra/bin/zmprov -l ms `hostname -f` -zimbraServiceEnabled antivirus 
sudo -u zimbra /opt/zimbra/bin/zmprov -l ms `hostname -f` -zimbraServiceEnabled amavis

echo
echo "Disabling CBPolicyd - MACROMIND Firewall"
sudo -u zimbra /opt/zimbra/bin/zmprov ms `hostname -f` -zimbraServiceEnabled cbpolicyd

echo
echo "Configuring to resolve hostname internally"
sudo -u zimbra /opt/zimbra/bin/zmprov ms `hostname -f` zimbraMtaLmtpHostLookup native
sudo -u zimbra /opt/zimbra/bin/zmprov mcf zimbraMtaLmtpHostLookup native

# restart services
echo
echo "Restarting services..."
sudo -u zimbra /opt/zimbra/bin/zmcontrol stop
/app/control-zimbra.sh start

exit 0
