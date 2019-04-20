#! /bin/bash

if [ -z "$1" ]
then
  echo "Please supply a subdomain to create a certificate for";
  echo "e.g. mysite.localhost"
  exit;
fi

DOMAIN=$1
COMMON_NAME=${2:-$1}

CERT_ROOT=certs

# генерируем CA
if [ ! -f $CERT_ROOT/rootCA.key ]; then
  openssl genrsa -out $CERT_ROOT/rootCA.key 2048
  openssl req -x509 -new -nodes -key $CERT_ROOT/rootCA.key -sha256 -days 1024 -out $CERT_ROOT/rootCA.crt -subj "/C=RU/ST=None/L=None/O=Local/CN=CA"
fi

# генерируем ключ для локальных сертификатов
if [ ! -f $CERT_ROOT/self.key ]; then
  openssl genrsa -out $CERT_ROOT/self.key 2048
fi

NUM_OF_DAYS=10000

echo "keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $COMMON_NAME
DNS.2 = *.$COMMON_NAME
" > /tmp/__v3.ext

openssl req -new -key $CERT_ROOT/self.key -out /tmp/self.csr -subj "/C=RU/ST=None/L=None/O=Local/CN=$COMMON_NAME"
openssl x509 -req -in /tmp/self.csr -CA $CERT_ROOT/rootCA.crt -CAkey $CERT_ROOT/rootCA.key -CAcreateserial -out $CERT_ROOT/self.crt -days $NUM_OF_DAYS -sha256 -extfile /tmp/__v3.ext

rm /tmp/self.csr
rm /tmp/__v3.ext