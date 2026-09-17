---
description: OpenSSL CLI references for keys, certificates, encryption, and TLS probing
tags:
  - devops/command
  - security
---

# OpenSSL

## Private Keys

```bash
# generate RSA private key (add -des3 to password-protect)
openssl genrsa -out a.com.key 2048

# inspect a private key
openssl rsa -in logic.key -text -noout
openssl rsa -check -in server.key

# export matching public key
openssl rsa -in logic.key -pubout -out logic.pub
openssl rsa -in logic.pub -pubin -text -noout

# remove passphrase from a key
openssl rsa -in cert.key -out nopass.key
```

## Certificate Signing Request (CSR)

```bash
# generate CSR from an existing key (interactive subject prompts)
openssl req -new -sha256 -key a.com.key -out a.com.csr

# inspect a CSR
openssl req -noout -text -in a.com.csr

# typical next step: submit the CSR to a CA, receive a signed CRT, deploy CRT + key
```

## Self-Signed Certificate

```bash
# sign an existing CSR with its own key (X.509 self-sign)
openssl x509 -req -days 3650 -in a.com.csr -extensions v3_ca -signkey a.com.key -out a.com.crt

# one-shot: new key + self-signed cert (interactive)
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout a.com.key -out a.com.crt

# one-shot with non-interactive subject
openssl req -x509 -new -newkey rsa:2048 -days 3650 -nodes \
  -keyout server.key -out server.crt \
  -subj "/C=HK/ST=HK/L=HK/O=Example Inc/OU=IT/CN=*.example.com"

# verify what was issued
openssl x509 -text -noout -in server.crt
```

## Private CA (Sign Your Own)

```bash
# create a long-lived CA key + self-signed CA cert
openssl genrsa -out ca.key 2048
openssl req -x509 -sha256 -new -nodes -key ca.key -out ca.crt -days 36500 \
  -subj "/C=CN/ST=HK/L=HK/O=HK/OU=HK LTD/CN=a.com"
openssl x509 -in ca.crt -text

# sign a CSR with the CA
openssl x509 -req -days 365 -sha256 \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -in a.com.csr -out a.com.crt

# append the CA cert so browsers see the full chain
cat ca.crt >> a.com.crt
```

## Certificate Inspection

```bash
# view full cert
openssl x509 -in cert.pem -text -noout

# issuer
openssl x509 -noout -issuer -issuer_hash -in a.com.crt

# public key hash
openssl x509 -noout -hash -in cert.pem

# validity dates
openssl x509 -dates -noout -in example.com.crt
openssl x509 -startdate -noout -in example.com.crt
openssl x509 -enddate -noout -in example.com.crt

# expires within N seconds? (exit 0 = no, exit 1 = yes)
openssl x509 -checkend 86400 -noout -in example.com.crt
```

## Format Conversion

Common certificate formats:

- **DER / CER**: binary, certificate only, no private key.
- **PEM**: text (base64), can contain both certificate and private key. `.key` files are typically PEM.
- **CRT**: either binary or text, certificate only, no private key.
- **PFX / P12**: PKCS#12 binary, both certificate and private key, usually password-protected.
- **JKS**: Java-specific binary, both certificate and private key, usually password-protected.

```bash
# DER → PEM
openssl x509 -in cert.der -inform der -text -noout
openssl x509 -in cert.der -inform der -outform pem -out cert.pem

# PEM → DER
openssl x509 -in cert.pem -text -noout
openssl x509 -in cert.pem -outform der -out cert.der

# PFX/P12 → PEM
openssl pkcs12 -info -nodes -in site.pfx
openssl pkcs12 -in site.pfx -out site.pem -nodes

# JKS → PEM (via PKCS#12, requires keytool from JDK)
keytool -importkeystore -srckeystore cert.jks -destkeystore cert.pkcs \
  -srcstoretype JKS -deststoretype PKCS12
openssl pkcs12 -in cert.pkcs -out cert.pem
```

## File Encryption

```bash
# small files only — direct RSA encryption
# 1024-bit key can encrypt files < 86 bytes; 2048-bit < 214 bytes
openssl rsautl -encrypt -inkey logic.pub -pubin -in file.txt -out file.bin
openssl rsautl -decrypt -inkey logic.key -in file.bin

# large files — S/MIME with AES-256 hybrid encryption
openssl smime -encrypt -aes256 -in Large.zip -binary -outform DEM -out Encrypted.zip logic.pub
openssl smime -decrypt -in Encrypted.zip -binary -inform DEM -inkey logic.key -out Large.zip
```

## TLS Probing (s_client)

### View Remote Certificate

```bash
# show the full chain offered by the server
openssl s_client -connect www.baidu.com:443 -showcerts

# pipe into x509 to extract just the dates
openssl s_client -connect www.baidu.com:443 -servername www.baidu.com 2>/dev/null \
  | openssl x509 -noout -dates

# extract expiration as ISO date
date --date="$(openssl s_client -connect www.baidu.com:443 -servername www.baidu.com 2>/dev/null \
  | openssl x509 -enddate -noout | cut -d= -f2)" --iso-8601
```

### Protocol & Cipher Suite

```bash
# does the server accept this TLS version?
# (older protocols ssl2/ssl3 are disabled in modern openssl builds)
openssl s_client -connect www.baidu.com:443 -tls1
openssl s_client -connect www.baidu.com:443 -tls1_2

# does the server support this cipher suite?
openssl s_client -connect www.baidu.com:443 -tls1_2 -cipher 'ECDHE-RSA-AES128-GCM-SHA256'
```

### STARTTLS

```bash
# upgrade plaintext SMTP/IMAP/POP3 to TLS
openssl s_client -connect mail.example.com:25
openssl s_client -starttls smtp -connect mail.example.com:25
```

## Utility

```bash
# random 32-byte secret as hex
openssl rand -hex 32

# random base64 secret (good for app secrets)
openssl rand -base64 48
```

> Reference:
>
> 1. [Official Website](https://www.openssl.org/)
> 2. [Repository](https://github.com/openssl/openssl)
