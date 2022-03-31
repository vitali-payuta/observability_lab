# LDAP
## Home task

#### Hometask requirements:

##### TASK 1

1. Spin-up VM-1-server in GCP. It must match next conditions:

  a. OS Centos 7 should be installed

  b. LDAP server should be installed and configured

  c. UI (phpldapadmin) should be installed

  d. Provision via terraform

##### TASK 2

1. Spin-up second VM-2-client GCP. It must match next conditions:

a. OS Centos 7 should be installed

b. LDAP client installed and configured

c. Provision via terraform

##### TASK 3

1. SSH to VM-2-client using ldap username / password

***

#### Hometask report

I will try to show my results bellow:

To confidure Server and Client I used Vagrant. 

<details>
<summary>Vagrantfile</summary>

```ruby

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "ldap-server" do |nodebalance|
    nodebalance.vm.box = "centos/7"
    nodebalance.vm.network "private_network", ip: "192.168.85.11"
    nodebalance.vm.synced_folder "D:/vagrant/ldap", "/vagrant"

    nodebalance.vm.provider "virtualbox" do |vc|
      vc.name = "ldap-server"
      vc.memory = "2048"
      vc.cpus = 2
    end

    nodebalance.vm.provision "shell", inline: <<-SHELL
    /vagrant/server.sh
    SHELL
  end


  config.vm.define "ldap-client" do |node1|
    node1.vm.box = "centos/7"
    node1.vm.network "private_network", ip: "192.168.85.10"
    node1.vm.synced_folder "D:/vagrant/ldap", "/vagrant"

    node1.vm.provider "virtualbox" do |va|
        va.name = "ldap-client"
        va.memory = "2048"
    end

    node1.vm.provision "shell", inline: <<-SHELL
    /vagrant/client.sh
    SHELL
  end  
end


```

</details>

To confidure LDAP server I used script. 

<details>
<summary>My bash script to configure LDAP-server&PHP-Ldap Admin</summary>

```sh

#!/bin/bash

#sudo yum update -y
sudo yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel
sudo systemctl start slapd
sudo systemctl enable slapd

slappasswd -s admin_ldap > temp



cat > ldaprootpasswd.ldif <<EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $(cat temp)
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ldaprootpasswd.ldif

sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat > ldapdomain.ldif <<EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=devopsldab,dc=com" read by * none

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=devopsldab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=devopsldab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $(cat temp)

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=devopsldab,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=devopsldab,dc=com" write by * read
EOF

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ldapdomain.ldif

cat > baseldapdomain.ldif <<EOF
dn: dc=devopsldab,dc=com
objectClass: top
objectClass: dcObject
objectclass: organization
o: devopsldab com
dc: devopsldab

dn: cn=Manager,dc=devopsldab,dc=com
objectClass: organizationalRole
cn: Manager
description: Directory Manager

dn: ou=People,dc=devopsldab,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=devopsldab,dc=com
objectClass: organizationalUnit
ou: Group
EOF

sudo ldapadd -x -w admin_ldap -D "cn=Manager,dc=devopsldab,dc=com" -f baseldapdomain.ldif


cat > group.ldif <<EOF
dn: cn=Manager,ou=Group,dc=devopsldab,dc=com
objectClass: top
objectClass: posixGroup
gidNumber: 1005
EOF

sudo ldapadd -x -w admin_ldap -D "cn=Manager,dc=devopsldab,dc=com" -f group.ldif

slappasswd -s lab_user > temp2

sudo cat > ldapuser.ldif <<EOF 
dn: uid=vpayuta,ou=People,dc=devopsldab,dc=com
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: vpayuta
uid: vpayuta
uidNumber: 1005
gidNumber: 1005
homeDirectory: /home/vpayuta
userPassword: $(cat temp2)
loginShell: /bin/bash
gecos: vpayuta
shadowLastChange: 0
shadowMax: -1
shadowWarning: 0
EOF

ldapadd -x -D "cn=Manager,dc=devopsldab,dc=com" -w admin_ldap -f ldapuser.ldif

sudo yum install -y php-ldap php-mbstring php-pear php-xml
sudo yum install -y epel-release
sudo yum install -y phpldapadmin

sudo sed -i '397 s;// $servers;$servers;' /etc/phpldapadmin/config.php
sudo sed -i '398 s;$servers->setValue;// $servers->setValue;' /etc/phpldapadmin/config.php
sudo sed -i ' s;Require local;Require all granted;' /etc/httpd/conf.d/phpldapadmin.conf 
sudo sed -i ' s;Allow from 127.0.0.1;Allow from 0.0.0.0;' /etc/httpd/conf.d/phpldapadmin.conf 

sudo systemctl restart httpd



```

</details>

To configure client on the second VM, I also used bash script
Also I configure ssh to make possible to enter ssh session using user login and password

<details>
<summary>My bash script to configure LDAP-client & ssh </summary>

```shell

#!/bin/bash
sudo yum install -y openldap-clients nss-pam-ldapd

sudo authconfig --enableldap --enableldapauth --ldapserver=192.168.85.11 --ldapbasedn="dc=devopsldab,dc=com" --enablemkhomedir --update

sudo sed -i ' s;PasswordAuthentication no;PasswordAuthentication yes;' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo systemctl restart nslcd


```

</details>

And there are few screenshots to prove my result:

SSH:
![Image alt](https://github.com/vitali-payuta/observability_lab/blob/task1/hometask1/getent_passwd.PNG)

PHPADMIN:
![Image alt](https://github.com/vitali-payuta/observability_lab/blob/task1/hometask1/phpldapadmin.PNG)

VM:
![Image alt](https://github.com/vitali-payuta/observability_lab/blob/task1/hometask1/vm.PNG)



