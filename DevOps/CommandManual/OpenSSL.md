---
description: Openssl
---

# Openssl

## Introduction

...

## How to Use

### 1. Third-Party CA Signed Certificate

```bash
# generate private key, encryption parameter: -des3
openssl genrsa -out a.com.key 2048

# generate CSR file
openssl genrsa -out a.com.key 2048 openssl req -new -sha256 -key a.com.key -out a.com.csr
# view CSR information
openssl req -noout -text -in a.com.csr

# submit CSR file to CA or third-party certificate authority to obtain a digitally signed public key CRT file
# deploy CRT and key files to the web server
```

### 2. Self-Signed / Private CA Certificate

- Self-signed method

```bash
# self-sign using existing private key and CSR
openssl x509 -req -days 3650 -in a.com.csr -extensions v3_ca -signkey a.com.key -out a.com.crt
# or directly generate private key + public certificate
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout a.com.key -out a.com.crt


# directly generate self-signed certificate
openssl req -x509 -new -newkey rsa:2048 -days 3650 -nodes -keyout server.key -out server.crt -subj "/C=HK/ST=HK/L=HK/O=Example Inc/OU=IT/CN=*.example.com"
# verify private key and public certificate
openssl rsa -check -in server.key
openssl x509 -text -noout -in server.crt
```

- CA signed method

```bash
# generate CA public and private keys
openssl genrsa -out ca.key 2048
openssl req -x509 -sha256 -new -nodes -key ca.key -out ca.crt -days 36500 -subj "/C=CN/ST=HK/L=HK/O=HK/OU=HK LTD/CN=a.com"
# view CA certificate details
openssl x509 -in ca.crt -text


# sign certificate using CA
openssl x509 -req -days 365 -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial -in a.com.csr -out a.com.crt
# append CA cert for better browser compatibility
cat ca.crt >> a.com.crt


# view issuer information
openssl x509 -noout -issuer -issuer_hash -in a.com.crt
```

### 3. Encrypt and Decrypt Files with OpenSSL

```bash
# generate and verify private key
openssl genrsa -out logic.key 2048
openssl rsa -in logic.key -text -noout

# export and verify public key
openssl rsa -in logic.key -pubout -out logic.pub
openssl rsa -in logic.pub -pubin -text -noout

# encrypt/decrypt small files
# 1024-bit key can encrypt files smaller than 86 bytes, 2048-bit key can encrypt files smaller than 214 bytes
# encrypt with public key
openssl rsautl -encrypt -inkey logic.pub -pubin -in file.txt -out file.bin
# decrypt with private key
openssl rsautl -decrypt -inkey logic.key -in file.bin

# encrypt/decrypt large files
# encrypt with public key
openssl smime -encrypt -aes256 -in Large.zip -binary -outform DEM -out Encrypted.zip logic.pub
# decrypt with private key
openssl smime -decrypt -in Encrypted.zip -binary -inform DEM -inkey logic.key -out Large.zip
```

### 4. Certificate Format Conversion

> Common certificate formats:
>
> - .DER .CER: Binary format, contains certificate only, no private key.
> - .PEM: Text format, can contain both certificate and private key. Files with .key suffix are typically PEM format.
> - .CRT: Can be binary or text format, contains certificate only, no private key.
> - .PFX .P12: PKCS12 binary format, contains both certificate and private key, usually password-protected.
> - .JKS: Java-specific binary format, contains both certificate and private key, usually password-protected.

```bash
# DER/CER/CRT to PEM
# view certificate info first, then convert format
openssl x509 -in cert.der -inform der -text -noout openssl x509 -in cert.der -inform der -outform pem -out cert.pem

# PEM to DER/CER/CRT
openssl x509 -in cert.pem -text -noout openssl x509 -in cert.pem -outform der -out cert.der

# PFX to PEM
openssl pkcs12 -info -nodes -in site.pfx openssl pkcs12 -in site.pfx -out site.pem -nodes

# JKS to PEM
# requires keytool from JDK, first convert to PKCS12 format:
keytool -importkeystore -srckeystore cert.jks -destkeystore cert.pkcs -srcstoretype JKS -deststoretype PKCS12
# then convert to PEM format with openssl
openssl pkcs12 -in cert.pkcs -out cert.pem
```

### 5. Other Tips

```bash
# random 32 characters secret key
openssl rand -hex 32

# email test
openssl s_client -connect mail.example.com:25
openssl s_client -starttls smtp -connect mail.example.com:25

# remove password from certificate
openssl rsa -in cert.key -out nopass.key

# view public key hash
openssl x509 -noout -hash -in cert.pem

# view local certificate
openssl x509 -dates -noout -in example.com.crt
openssl x509 -dates -text -noout -in example.com.crt
# view certificate start and end dates
openssl x509 -startdate -noout -in example.com.crt
openssl x509 -enddate -noout -in example.com.crt
openssl x509 -checkend 86400 -noout -in example.com.crt

# view online certificate
openssl s_client -connect www.baidu.com:443 -showcerts
openssl s_client -connect www.baidu.com:443 -servername www.baidu.com 2> /dev/null | openssl x509 -noout -dates

# extract expiration date
openssl s_client -connect www.baidu.com:443 -servername www.baidu.com 2>/dev/null |openssl x509 -enddate -noout |cut -d "=" -f 2
# convert date format
date --date="$(openssl s_client -connect www.baidu.com:443 -servername www.baidu.com 2>/dev/null |openssl x509 -enddate -noout |cut -d "=" -f 2)" --iso-8601

# check if website accepts specific SSL protocol version
# protocols: TLS 1.0 (tls1), TLS 1.1 (tls1_1), TLS 1.2 (tls1_2). SSL V2 (ssl2) and SSL V3 (ssl3) are disabled by default in newer openssl versions
openssl s_client -connect www.baidu.com:443 -tls1

# check if website supports specific cipher suite
openssl s_client -connect www.baidu.com:443 -tls1_2 -cipher 'ECDHE-RSA-AES128-GCM-SHA256'
```

> Reference:
>
> 1. [Official Website](https://www.openssl.org/)
> 2. [Repository](https://github.com/openssl/openssl)
