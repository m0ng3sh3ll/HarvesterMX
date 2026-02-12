#!/bin/bash

echo "====================================================================="
echo "       MAIL SERVER DOCKER SETUP (Postfix + Dovecot)"
echo "====================================================================="

# Setup Directories
cd "$(dirname "$0")" || exit
BASE_DIR="$(pwd)"

# 1. Gather Information
echo ""
echo "--- DNS Check ---"
echo "Before proceeding, please ensure you have configured the following DNS records:"
echo "  - A Record:     mail.$DOMAIN -> IP_ADDRESS"
echo "  - MX Record:    $DOMAIN      -> mail.$DOMAIN (Priority 10)"
echo "  - TXT Record:   v=spf1 mx -all"
echo "  - PTR Record:   Reverse DNS for your IP (Recommended)"
echo ""
read -p "Have you configured these records? (y/n): " DNS_CONFIRM
if [[ "$DNS_CONFIRM" != "y" ]]; then
    echo "Please configure your DNS records and try again."
    exit 1
fi

echo ""
echo "--- Configuration ---"
read -p "Enter your Domain Name (e.g., example.com): " DOMAIN
read -p "Enter your Hostname (e.g., mail.example.com): " HOSTNAME
read -p "Enter the System User to receive emails (e.g., inbox): " MAIL_USER
read -s -p "Enter the Password for $MAIL_USER: " MAIL_PASS
echo ""

# Validate Certs (Local or Generate)
LE_DIR="$BASE_DIR/letsencrypt"
CERT_PATH="$LE_DIR/live/$DOMAIN"

if [ ! -d "$CERT_PATH" ]; then
    echo "Certificates not found in $LE_DIR."
    read -p "Do you want to generate them now using Certbot (Docker)? (y/n): " GEN_CERT
    if [[ "$GEN_CERT" == "y" ]]; then
        echo "Starting Certbot..."
        echo "Please ensure Port 80 is free."
        mkdir -p "$LE_DIR"
        docker run -it --rm --name certbot \
            --dns 8.8.8.8 \
            -v "$LE_DIR:/etc/letsencrypt" \
            -v "$LE_DIR/../letsencrypt-lib:/var/lib/letsencrypt" \
            -p 80:80 \
            certbot/certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"
        
        if [ ! -d "$CERT_PATH" ]; then
            echo "Certificate generation failed or was cancelled."
            exit 1
        fi
        
        echo "----------------------------------------------------------------"
        echo "Certificates generated successfully!"
        echo "NOTE: They are saved LOCALLY in: $LE_DIR"
        echo "      (NOT in the global /etc/letsencrypt)"
        echo "----------------------------------------------------------------"
        
        # Fix permissions so current user can read them
        echo "Fixing permissions..."
        chmod -R 755 "$LE_DIR"
        
        echo "Files found:"
        ls -l "$CERT_PATH"
    else
        echo "Please ensure certificates are placed in $LE_DIR/live/$DOMAIN/ before starting."
        # We allow continuing if they plan to put them there manually
    fi
else
    echo "Certificates found at $CERT_PATH"
fi

# 2. Prepare Directories (Moved to top)
CONFIG_DIR="$BASE_DIR/config"
DATA_DIR="$BASE_DIR/mail_data"

echo ""
echo "Creating directories..."
mkdir -p "$CONFIG_DIR/postfix"
mkdir -p "$CONFIG_DIR/dovecot"
mkdir -p "$DATA_DIR"

# 3. Generate Configurations

# --- Postfix virtual_catchall ---
echo "/@${DOMAIN//./\\.}/    $MAIL_USER" > "$CONFIG_DIR/postfix/virtual_catchall"
echo "Generated virtual_catchall"

# --- Postfix main.cf ---
cat <<EOF > "$CONFIG_DIR/postfix/main.cf"
# Postfix main.cf - Dockerized

compatibility_level = 3.9
biff = no

# Host and Domain
myhostname = $HOSTNAME
mydomain = $DOMAIN
myorigin = \$mydomain
mydestination = \$myhostname, localhost.\$mydomain, localhost, $DOMAIN

# Network
inet_interfaces = all
inet_protocols = all
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 172.16.0.0/12 192.168.0.0/16 10.0.0.0/8

# Aliases and Mailbox
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
home_mailbox = Maildir/
mailbox_command =
luser_relay = $MAIL_USER@localhost
local_recipient_maps =

# TLS Parameters (SMTPD)
# Note: Paths are inside the container
smtpd_tls_cert_file = /etc/letsencrypt/live/$DOMAIN/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/$DOMAIN/privkey.pem
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache

# TLS Parameters (SMTP Client)
smtp_tls_security_level = may
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache

# SASL Auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
broken_sasl_auth_clients = yes

# Restrictions
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination
smtpd_banner = \$myhostname ESMTP \$mail_name

# Virtual Maps
virtual_alias_maps = regexp:/etc/postfix/virtual_catchall
virtual_transport = local
EOF
echo "Generated config/postfix/main.cf"

# --- Postfix master.cf ---
cat <<EOF > "$CONFIG_DIR/postfix/master.cf"
# Postfix master.cf - Dockerized

smtp      inet  n       -       y       -       -       smtpd
pickup    unix  n       -       y       60      1       pickup
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd

# Submission (587)
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=may
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
EOF
echo "Generated config/postfix/master.cf"

# --- Dovecot dovecot.conf ---
cat <<EOF > "$CONFIG_DIR/dovecot/dovecot.conf"
# Dovecot config - Dockerized

## Core
protocols = imap
listen = *

## Authentication
auth_mechanisms = plain login
auth_username_format = %Ln
passdb {
  driver = pam
}
userdb {
  driver = passwd
}

## SSL
ssl = required
ssl_cert = </etc/letsencrypt/live/$DOMAIN/fullchain.pem
ssl_key = </etc/letsencrypt/live/$DOMAIN/privkey.pem

## Mail Location
mail_location = maildir:~/Maildir
namespace inbox {
  inbox = yes
}

## Services
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
  }
}

service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}
EOF
echo "Generated config/dovecot/dovecot.conf"


# 4. Generate Docker Compose
echo ""
echo "Generating docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  mailserver:
    build: .
    container_name: mailserver
    restart: always
    environment:
      - DOMAIN=$DOMAIN
      - MAIL_USER=$MAIL_USER
      - MAIL_PASS=$MAIL_PASS
    # network_mode: host (Bridge is preferred on Windows/Docker Desktop)
    dns:
      - 8.8.8.8
      - 8.8.4.4
    ports:
      - "25:25"
      - "587:587"
      - "143:143"
      - "993:993"
    volumes:
      - ./config/postfix:/etc/postfix
      - ./config/dovecot:/etc/dovecot
      - ./mail_data:/home
      - ./letsencrypt:/etc/letsencrypt:ro
EOF
echo "Generated docker-compose.yml"

# 5. Build and Run
echo ""
echo "--- Starting Docker Container ---"
echo "Building image..."
docker compose build

echo "Starting container..."
docker compose up -d

echo ""
echo "Checking status..."
docker compose ps

echo ""
echo "Done! Configuration is in ./config if you need to manually edit it."
echo "Mail data will be stored in ./mail_data"
