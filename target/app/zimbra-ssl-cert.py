#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import requests
import smtplib
import socket
import time
from email.mime.text import MIMEText

# Forca o ambiente a usar UTF-8
os.environ['PYTHONIOENCODING'] = 'utf-8'
os.environ['LANG'] = 'C.UTF-8'

# Configuracoes
SMTP_SERVER = '10.100.1.126'
SMTP_FROM = 'noreply@notifications.macromind.net'
SMTP_TO = 'guilherme.filippo@icloud.com'
API_BASE = 'https://dashboard.macromind.com.br/api'

def get_api_data():
    try:
        url = f'{API_BASE}/services/zimbra/get-domains?server={socket.gethostname()}'
        r = requests.get(url, timeout=15)
        if r.ok and r.json()['data']['results']:
            return r.json()['data']['results'][0]
    except Exception as e:
        print(f"Erro API: {e}")
    return []

def send_alert(text):
    msg = MIMEText(text)
    msg['Subject'] = f'Erro SSL Zimbra: {socket.gethostname()}'
    msg['From'] = SMTP_FROM
    msg['To'] = SMTP_TO
    try:
        with smtplib.SMTP(SMTP_SERVER, 25) as s:
            s.sendmail(SMTP_FROM, SMTP_TO, msg.as_string())
    except: pass

def ssl_gen(force=False):
    data = get_api_data()
    if not data or (not data.get('ssl_renew') and not force):
        print('Nada para renovar.')
        return

    hostname = socket.gethostname()
    print(f'--- Iniciando Renovacao Standalone: {hostname} ---')

    # 1. Libera porta 80
    os.system('su - zimbra -c "zmproxyctl stop"')
    time.sleep(3)

    # 2. Certbot
    domains_cmd = f"-d {hostname}"
    for d in data.get('domains', []):
        domains_cmd += f" -d {d}"

    certbot_cmd = (f"certbot certonly --standalone --non-interactive --agree-tos "
                   f"--register-unsafely-without-email --cert-name {hostname} {domains_cmd}")
    
    success = os.system(certbot_cmd)
    os.system('su - zimbra -c "zmproxyctl start"')

    if success == 0:
        print('Certificado obtido! Preparando a Cadeia de Confianca (CA Bundle)...')
        
        le_path = f'/etc/letsencrypt/live/{hostname}'
        zimbra_ssl = '/opt/zimbra/ssl/zimbra/commercial'
        
        # --- PASSO CRUCIAL: Baixar a Raiz ISRG Root X1 ---
        root_ca_url = "https://letsencrypt.org/certs/isrgrootx1.pem"
        try:
            root_content = requests.get(root_ca_url).text
            with open("/tmp/isrgrootx1.pem", "w") as f:
                f.write(root_content)
        except:
            print("Erro ao baixar Root CA. O deploy pode falhar.")

        # 1. Prepara a chave privada
        os.system(f'cp {le_path}/privkey.pem {zimbra_ssl}/commercial.key')
        os.system(f'chown zimbra:zimbra {zimbra_ssl}/commercial.key')

        # 2. Monta o CA Bundle: Intermediaria (chain.pem) + Raiz (isrgrootx1.pem)
        # O Zimbra PRECISA da raiz no arquivo de chain para validar o R12.
        os.system(f'cat {le_path}/chain.pem /tmp/isrgrootx1.pem > /tmp/combined_chain.pem')
        os.system(f'cp {le_path}/cert.pem /tmp/cert.pem')
        os.system('chown zimbra:zimbra /tmp/cert.pem /tmp/combined_chain.pem')

        print('Iniciando Deploy (zmcertmgr)...')
        # 3. Deploy usando o Cert + Bundle (Intermediaria + Raiz)
        deploy_cmd = (f'su - zimbra -c "/opt/zimbra/bin/zmcertmgr deploycrt comm '
                      f'/tmp/cert.pem /tmp/combined_chain.pem"')
        
        if os.system(deploy_cmd) == 0:
            print('Deploy OK! Reiniciando Zimbra...')
            os.system('su - zimbra -c "zmcontrol restart"')
            os.system('rm -f /tmp/cert.pem /tmp/combined_chain.pem /tmp/isrgrootx1.pem')
            requests.put(f"{API_BASE}/instances/{data['uuid']}/ssl-renewed")
            print('Sucesso total!')
        else:
            print('Erro no deploy. Verifique se a Root CA foi baixada corretamente.')
            send_alert("Falha no zmcertmgr deploycrt (Erro de Cadeia)")
    else:
        send_alert("Falha no Certbot Standalone")

if __name__ == '__main__':
    force = len(sys.argv) > 1 and sys.argv[1].lower() == 'force'
    ssl_gen(force)
