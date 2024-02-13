import os
import sys
import requests
import smtplib
import socket
from email.mime.text import MIMEText


def get_api_data():
    remote_data = requests.get('https://dashboard.macromind.com.br/api/services/zimbra/get-domains?server=' + socket.gethostname())
    if remote_data.ok is True and len(remote_data.json()['data']['results']) > 0:
        return remote_data.json()['data']['results'][0]
    return []


def renew_confirmation(instance_uuid):
    val = requests.put('https://dashboard.macromind.com.br/api/instances/' + instance_uuid + '/ssl-renewed')
    return val.ok


def clear():
    print('Cleaning old attempts...')
    os.system('rm -rf /etc/letsencrypt/live/*')
    os.system('rm -rf /etc/letsencrypt/archive/*')
    os.system('rm -rf /etc/letsencrypt/renewal/*')
    os.system('rm -rf /tmp/*.pem')
    os.system('rm -rf /tmp/*.txt')
    print('OK, old files removed.')


def update_authority_x3():
    x3_file = '/root/letsencryptauthorityx3.pem'
    x3_local = os.path.exists(x3_file)
    if x3_local is False:
        print('Updating Letsencrypt certificate authority - X3')
        x3_response = requests.get('https://letsencrypt.org/certs/letsencryptauthorityx3.pem')
        with open(x3_file, 'wb') as local_file:
            print('Writing authority file')
            for chunk in x3_response.iter_content(chunk_size=128):
                local_file.write(chunk)
        print('Authority file saved!')
    return x3_file


def update_authority_r1():
    r1_file = '/root/isrgrootx1.pem'
    r1_local = os.path.exists(r1_file)
    if r1_local is False:
        print('Updating Letsencrypt certificate authority - R1')
        r1_response = requests.get('https://letsencrypt.org/certs/isrgrootx1.pem')
        with open(r1_file, 'wb') as local_file:
            print('Writing authority file')
            for chunk in r1_response.iter_content(chunk_size=128):
                local_file.write(chunk)
        print('Authority file saved!')
    return r1_file

def update_authority_r3():
    r3_file = '/root/lets-encrypt-r3.pem'
    r3_local = os.path.exists(r3_file)
    if r3_local is False:
        print('Updating Letsencrypt certificate authority - R3')
        r3_response = requests.get('https://letsencrypt.org/certs/lets-encrypt-r3.pem')
        with open(r3_file, 'wb') as local_file:
            print('Writing authority file')
            for chunk in r3_response.iter_content(chunk_size=128):
                local_file.write(chunk)
        print('Authority file saved!')
    return r3_file


def ssl_gen(local_renew: False):
    clear()
    remote_data = get_api_data()
    if remote_data is not None and (remote_data['ssl_renew'] is True or local_renew is True):
        print('Starting SSL renew for ' + remote_data['host'])
        ssl_command = 'cd;/usr/bin/certbot certonly --non-interactive --no-eff-email --expand --webroot -w /opt/zimbra/data/nginx/html --cert-name ' + remote_data['host'] + ' -d ' + remote_data['host']
        for domain in remote_data['domains']:
            ssl_command += ' -d ' + domain
        print('Trying to generate a SSL')
        ssl_attempt = os.system(ssl_command)
        if ssl_attempt == 0:
            print('Creating a PEM file based on requests to Letsencrypt...')
            os.system('cat /etc/letsencrypt/archive/' + remote_data['host'] + '/priv*.pem > /opt/zimbra/ssl/zimbra/commercial/commercial.key')
            os.system('chown zimbra:zimbra /opt/zimbra/ssl/zimbra/commercial/commercial.key')
            r3_file = update_authority_r3()
            os.system('cat ' + r3_file + '  > /etc/letsencrypt/live/' + remote_data['host'] + '/chain.pem')
            x3_file = update_authority_x3()
            os.system('cat ' + x3_file + ' >> /etc/letsencrypt/live/' + remote_data['host'] + '/chain.pem')
            r1_file = update_authority_r1()
            os.system('cat ' + r1_file + ' >> /etc/letsencrypt/live/' + remote_data['host'] + '/chain.pem')
            os.system('chmod o+rx /etc/letsencrypt/archive')
            os.system('chmod o+rx /etc/letsencrypt/live')
            print('Activating the new ssl certificate')
            os.system('cd /tmp && su - zimbra -c "/opt/zimbra/bin/zmcertmgr verifycrt comm /opt/zimbra/ssl/zimbra/commercial/commercial.key /etc/letsencrypt/live/' + remote_data['host'] + '/cert.pem /etc/letsencrypt/live/' + remote_data['host'] + '/chain.pem"')
            os.system('cd /tmp && su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm /etc/letsencrypt/live/' + remote_data['host'] + '/cert.pem /etc/letsencrypt/live/' + remote_data['host'] + '/chain.pem"')
            os.system('chmod o-rx /etc/letsencrypt/archive')
            os.system('chmod o-rx /etc/letsencrypt/live')
            os.system('cd /tmp && su - zimbra -c "zmlocalconfig -e ssl_allow_untrusted_certs=true"')
            os.system('cd /tmp && su - zimbra -c "zmlocalconfig -e ldap_starttls_supported=0"')
            os.system('cd /tmp && su - zimbra -c "zmlocalconfig -e ldap_starttls_required=false"')
            os.system('cd /tmp && su - zimbra -c "zmlocalconfig -e ldap_common_require_tls=0"')
            os.system('cd /tmp && su - zimbra -c "zmcontrol restart"')
            renew_confirmation(remote_data['uuid'])
        else:
            print('Error on certificate. Sending alerts...')
            smtp_hostname = '10.100.1.126'
            smtp_username = 'noreply@notifications.macromind.net'
            smtp_destination = 'guilherme.filippo@icloud.com'
            msg = MIMEText('Alerta: Houve um ERRO ao tentar gerar o certificado SSL do Farm ' + remote_data['host'])
            msg['Subject'] = 'Alerta: Erro SSL'
            msg['From'] = smtp_username
            msg['To'] = smtp_destination
            smtp_server=smtplib.SMTP(smtp_hostname, 25)
            smtp_server.ehlo()
            smtp_server.sendmail(smtp_username, smtp_destination, msg.as_string())
            smtp_server.quit()
    else:
        print('No domains to renew...')
    clear()


if __name__ == '__main__':
    force = False
    if len(sys.argv) > 1 and sys.argv[1].lower() == 'force':
        force = True
        print('Forcing SSL Renew')
    ssl_gen(local_renew=force)
