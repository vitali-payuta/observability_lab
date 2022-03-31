#!/bin/bash
sudo yum install -y openldap-clients nss-pam-ldapd

sudo authconfig --enableldap --enableldapauth --ldapserver=192.168.85.11 --ldapbasedn="dc=devopsldab,dc=com" --enablemkhomedir --update

sudo systemctl restart nslcd
