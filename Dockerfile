FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && apt-get install -y \
    postfix \
    dovecot-core \
    dovecot-imapd \
    supervisor \
    rsyslog \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
# 25: SMTP, 587: Submission, 143: IMAP, 993: IMAPS
EXPOSE 25 587 143 993

# Volume for data
VOLUME ["/home", "/etc/postfix", "/etc/dovecot", "/etc/letsencrypt"]

ENTRYPOINT ["/entrypoint.sh"]
