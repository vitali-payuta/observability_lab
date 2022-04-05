#!/bin/bash

sudo yum install -y http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm

sudo yum install -y zabbix-agent

sudo systemctl start zabbix-agent

sudo sed -i 's;Server=127.0.0.1;Server=192.168.85.11;' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's;# ListenPort=10050;ListenPort=10050;' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's;# ServerActive=;ServerActive=192.168.85.11;' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's;# HostMetadata=;HostMetadata=system.uname;' /etc/zabbix/zabbix_agentd.conf
sudo sed -i 's;# HostMetadataItem=;HostMetadataItem=system.uname;' /etc/zabbix/zabbix_agentd.conf

sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

############HW2#########################
sudo yum install -y epel-release
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx