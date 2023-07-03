#! /bin/bash

ARGS=$(getopt -o a:b -l "host_password:,zabbix_server_ip:" -- "$@");

eval set -- "$ARGS";

while true; do
  case "$1" in
    -a|--host_password)
      shift;
      if [ -n "$1" ]; then
        host_password=$1;
        shift;
      fi
      ;;
    -b|--zabbix_server_ip)
      shift;
      if [ -n "$1" ]; then
        zabbix_server_ip=$1;
        shift;
      fi
      ;;
    --)
      shift;
      break;
      ;;
  esac
done



if [ $(cat /etc/os-release  | awk 'NR==2 {print $3}'| grep -i -o xenial) ==  "Xenial" ]; then
  echo "$host_password" | sudo -S wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+xenial_all.deb
  echo "$host_password" | sudo -S dpkg -i zabbix-release_4.2-1+xenial_all.deb
elif [ $(cat /etc/os-release  | awk 'NR==2 {print $3}'| grep -i -o bionic) ==  "Bionic" ]; then
  echo "$host_password" | sudo -S wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
  echo "$host_password" | sudo -S dpkg -i zabbix-release_4.2-1+bionic_all.deb
fi


echo "$host_password" | sudo -S sudo apt -y update

#установка заббикса
echo "$host_password" | sudo -S apt-get -y install zabbix-agent

#добавляем ip in zabbiхх:
echo "$host_password" | sudo -S sed -i  "s/^\(Server\s*=\).*/\1 ${zabbix_server_ip}/" /etc/zabbix/zabbix_agentd.conf


#запуск агента
echo "$host_password" | sudo -S systemctl start zabbix-agent
echo "$host_password" | sudo -S systemctl enable zabbix-agent

#проверка статуса агента
zabbix_agent_status=$(echo "$host_password" | sudo -S systemctl status zabbix-agent |  awk 'NR==3')
echo "$zabbix_agent_status"
