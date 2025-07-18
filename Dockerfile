FROM ubuntu:18.04

# Update image and install additional packages
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

COPY zimbra.list /etc/apt/sources.list.d/zimbra.list
COPY GPG-KEY-zimbra /tmp/GPG-KEY-zimbra

RUN apt-key add /tmp/GPG-KEY-zimbra && \
  rm /tmp/GPG-KEY-zimbra && \
  apt update && \
  apt install \
    debootstrap \
    dnsmasq \
    iproute2 \
    iptables \
    sed -y && \
  apt autoremove -y && \
  apt clean -y && \
  rm -rf /var/lib/apt/lists/*

# Copy prepared files into the image
# -----------------------------------------------------------------------------
COPY target /

RUN \
  mkdir /data && \
  chmod 750 /docker-entrypoint.sh


# Volumes
# -----------------------------------------------------------------------------
VOLUME [ "/data" ]

# Expose ports
# -----------------------------------------------------------------------------
# 25/tcp   - SMTP (for incoming mail)
# 80/tcp   - HTTP (for web mail clients)
# 110/tcp  - POP3 (for mail clients)
# 143/tcp  - IMAP (for mail clients)
# 443/tcp  - HTTP over TLS (for web mail clients)
# 465/tcp  - SMTP over SSL (for mail clients)
# 587/tcp  - SMTP (submission, for mail clients)
# 993/tcp  - IMAP over TLS (for mail clients)
# 995/tcp  - POP3 over TLS (for mail clients)
# 5222/tcp - XMPP
# 5223/tcp - XMPP (default legacy port)
# 7071/tcp - HTTPS (admin panel, https://<host>/zimbraAdmin)
# -----------------------------------------------------------------------------
EXPOSE 25 80 110 143 443 465 587 993 995 5222 5223 7071

# configure container startup
# -----------------------------------------------------------------------------
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "run" ]
