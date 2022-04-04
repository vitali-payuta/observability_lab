#!/bin/bash

sudo yum -y update
sudo yum -y install mariadb mariadb-server


sudo /usr/bin/mysql_install_db --user=mysql --force

sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo yum -y install http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm
sudo yum -y install zabbix-server-mysql zabbix-web-mysql


mysql -uroot <<EOF
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@'localhost' identified by 'zabbix';
FLUSH PRIVILEGES;
EOF

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -pzabbix zabbix


cat >> /etc/zabbix/zabbix_server.conf <<EOF
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
EOF

sed -i 's;# php_value date.timezone Europe/Riga;php_value date.timezone Europe/Minsk;' /etc/httpd/conf.d/zabbix.conf

setsebool -P httpd_can_connect_zabbix on
setsebool -P httpd_can_network_connect_db on

cat >> /etc/zabbix/web/zabbix.conf.php<<EOF
<?php
// Zabbix GUI configuration file.
global \$DB;
\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = 'zabbix';
// Schema 
\$DB['SCHEMA'] = '';
\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '';
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

sudo chmod 777 /etc/zabbix/web/zabbix.conf.php

sudo systemctl start zabbix-server httpd
sudo systemctl enable zabbix-server httpd

sudo yum install -y zabbix-agent

sudo systemctl start zabbix-agent

sudo sed -i 's;# ListenPort=10050;ListenPort=10050;' /etc/zabbix/zabbix_agentd.conf

sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent