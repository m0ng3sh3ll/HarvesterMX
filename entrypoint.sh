#!/bin/bash

# Default user if not provided
MAIL_USER=${MAIL_USER:-inbox}
DOMAIN=${DOMAIN:-localhost}

echo "Initializing Mail Server for domain: $DOMAIN"
echo "Mail User: $MAIL_USER"

# Create the mail user if it doesn't exist
if ! id "$MAIL_USER" &>/dev/null; then
    echo "Creating user $MAIL_USER..."
    useradd -m -s /bin/bash "$MAIL_USER"
fi

# Set password if provided
if [ -n "$MAIL_PASS" ]; then
    echo "$MAIL_USER:$MAIL_PASS" | chpasswd
    echo "Password set for $MAIL_USER"
fi

# Ensure Maildir permissions
mkdir -p /home/$MAIL_USER/Maildir
chown -R $MAIL_USER:$MAIL_USER /home/$MAIL_USER
chmod -R 700 /home/$MAIL_USER/Maildir

# Postfix chroot setup (often needed)
# Copy missing files to chroot if necessary, though basic setups usually work out of box on modern Debian.
# We trust the package installation.

# Fixed permissions
chown root:root /etc/postfix /etc/postfix/main.cf /etc/postfix/master.cf
chmod 644 /etc/postfix/main.cf /etc/postfix/master.cf

# Generate maps
if [ -f /etc/postfix/virtual_catchall ]; then
    postmap /etc/postfix/virtual_catchall
fi
newaliases

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
