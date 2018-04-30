#!/bin/bash

set -ex
DOMAIN="my.local.stuff.co.nz"
TOMCAT_KEY_PASS="changeit"
CERTBBOT_BIN="/usr/local/bin/certbot"
EMAIL_NOTIFICATION="chao.yang@stuff.co.nz"

# Install certbot

install_certbot () {
    if [[ ! -f /usr/local/bin/certbot ]]; then
        brew install certbot
        chmod a+x $CERTBOT_BIN
    fi
}

# Attempt cert renewal:
renew_ssl () {
    ${CERTBOT_BIN} renew  > /tmp/crt.txt
    cat /tmp/crt.txt | grep "No renewals were attempted"
    if [[ $? -eq "0" ]]; then
        echo "Cert not yet due for renewal"
        exit 0
    else

        # Create Letsencypt ssl dir if doesn't exist
        echo "Renewing ssl certificate..."

        # create a PKCS12 that contains both your full chain and the private key
        rm -f /tmp/${DOMAIN}_fullchain_and_key.p12 2>/dev/null
        openssl pkcs12 -export -out /tmp/${DOMAIN}_fullchain_and_key.p12 \
            -passin pass:$TOMCAT_KEY_PASS \
            -passout pass:$TOMCAT_KEY_PASS \
            -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
            -inkey /etc/letsencrypt/live/$DOMAIN/privkey.pem \
            -name tomcat
    fi
}

# Convert that PKCS12 to a JKS
pkcs2jks () {
    rm -f /etc/ssl/${DOMAIN}.jks 2>/dev/null
    keytool -importkeystore -deststorepass $TOMCAT_KEY_PASS -destkeypass $TOMCAT_KEY_PASS \
      -destkeystore /etc/ssl/${DOMAIN}.jks -srckeystore /tmp/${DOMAIN}_fullchain_and_key.p12  \
      -srcstoretype PKCS12 -srcstorepass $TOMCAT_KEY_PASS \
      -alias tomcat
}      


# Main

install_certbot
renew_ssl
pkcs2jks
