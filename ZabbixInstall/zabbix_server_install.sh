#! /bin/bash

ARGS=$(getopt -o a:b:c:d:e:f:g -l "host_password:,mysql_db_user_name:,mysql_db_password:,mariadb_db_user_name:,maria_db_password:,database_new_root_password:,zabbix_database_new_password:" -- "$@");

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
    -b|--mysql_db_user_name)
      shift;
      if [ -n "$1" ]; then
        mysql_db_user_name=$1;
        shift;
      fi
      ;;
   -c|--mysql_db_password)
      shift;
      if [ -n "$1" ]; then
        mysql_db_password=$1;
        shift;
      fi
      ;;
   -d|--mariadb_db_user_name)
      shift;
      if [ -n "$1" ]; then
        mariadb_db_user_name=$1;
        shift;
      fi
      ;;
   -e|--maria_db_password)
      shift;
      if [ -n "$1" ]; then
        maria_db_password=$1;
        shift;
      fi
      ;;
   -f|--database_new_root_password)
      shift;
      if [ -n "$1" ]; then
        database_new_root_password=$1;
        shift;
      fi
      ;;
   -g|--zabbix_database_new_password)
      shift;
      if [ -n "$1" ]; then
        zabbix_database_new_password=$1;
        shift;
      fi
      ;;
    --)
      shift;
      break;
      ;;
  esac
done



echo "$host_password" | sudo -S sudo apt -y update

# установка php  модулей
echo "$host_password" | sudo -S apt -y install php7.0-xml php7.0-bcmath php7.0-mbstring

#Проверяет версию Ubuntu и устанавливает репозиторий zabbix
if [ $(cat /etc/os-release  | awk 'NR==2 {print $3}'| grep -i -o xenial) ==  "Xenial" ]; then
  echo "$host_password" | sudo -S wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+xenial_all.deb
  echo "$host_password" | sudo -S dpkg -i zabbix-release_4.2-1+xenial_all.deb
elif [ $(cat /etc/os-release  | awk 'NR==2 {print $3}'| grep -i -o bionic) ==  "Bionic" ]; then
  echo "$host_password" | sudo -S wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
  echo "$host_password" | sudo -S dpkg -i zabbix-release_4.2-1+bionic_all.deb
fi

echo "$host_password" | sudo -S sudo apt -y update

# Проверка установлен ли mysql сервер
mysql=$(dpkg -l | grep "mysql-server")

if [ "$?" ==  0 ]; then
#Установка сервера
echo "$host_password" | sudo -S apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent
echo "create database zabbix character set utf8 collate utf8_bin;" | mysql -h localhost -u $mysql_db_user_name -p$mysql_db_password

echo  "grant all privileges on zabbix.* to zabbix@'%' identified by '$zabbix_database_new_password';"  | mysql -h localhost -u $mysql_db_user_name -p$mysql_db_password
echo "flush privileges;" | mysql -h localhost -u $mysql_db_user_name -p$mysql_db_password

echo "$host_password" | sudo -S sed -i  "s/^\(bind-address\s*=\).*/\1 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
echo "$host_password" | sudo -S service mysql restart

echo "$host_password" | sudo -S zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix -p$zabbix_database_new_password
echo "$host_password" | sudo -S sed -i  "s/^\(\s*#\s*DBPassword=\).*/\DBPassword=/"  /etc/zabbix/zabbix_server.conf
echo "$host_password" | sudo -S sed -i  "s/^\(DBPassword\s*=\).*/\1 ${zabbix_database_new_password}/" /etc/zabbix/zabbix_server.conf

#Таймзона
echo "$host_password" | sudo -S  sed -i  "s/^\(\s*#\s*php_value date.timezone Europe\/Riga\).*/\\tphp_value date.timezone Asia\/Kolkata/" /etc/zabbix/apache.conf
fi

# Установлена ли MariaDB?
mariadb=$(dpkg -l | grep mariadb-server)
if [ "$?" ==  0 ]; then
#Установка сервера 
echo "$host_password" | sudo -S apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent
echo "create database zabbix character set utf8 collate utf8_bin;" | mysql -h localhost -u $mariadb_db_user_name -p$maria_db_password

echo  "grant all privileges on zabbix.* to zabbix@'%' identified by '$zabbix_database_new_password';"  | mysql -h localhost -u $mariadb_db_user_name -p$maria_db_password
echo "flush privileges;" | mysql -h localhost -u $mariadb_db_user_name -p$maria_db_password

echo "$host_password" | sudo -S sed -i  "s/^\(bind-address\s*=\).*/\1 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
echo "$host_password" | sudo -S service mysql restart

#Импорт в БД а также установка
echo "$host_password" | sudo -S zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix -p$zabbix_database_new_password
echo "$host_password" | sudo -S sed -i  "s/^\(\s*#\s*DBPassword=\).*/\DBPassword=/"  /etc/zabbix/zabbix_server.conf
echo "$host_password" | sudo -S sed -i  "s/^\(DBPassword\s*=\).*/\1 ${zabbix_database_new_password}/" /etc/zabbix/zabbix_server.conf

#Установка таймзоны
echo "$host_password" | sudo -S  sed -i  "s/^\(\s*#\s*php_value date.timezone Europe\/Riga\).*/\\tphp_value date.timezone Asia\/Kolkata/" /etc/zabbix/apache.conf
fi

#Установка бд MariaDB
db_install_check=$(dpkg -l | grep mariadb-server || dpkg -l | grep mysql-server)

if [ "$?" !=  0 ]; then
#Install Zabbix server, frontend agent
echo "$host_password" | sudo -S debconf-set-selections <<< 'mysql-server mysql-server/root_password password $database_new_root_password'
echo "$host_password" | sudo -S debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password  $database_new_root_password'
echo "$host_password" | sudo -S apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-agent
echo "create database zabbix character set utf8 collate utf8_bin;" | mysql -h localhost -u root -p$database_new_root_password

#По умолчанию все хосты имеют доступ , создайте свой белый список для привелегий!!
echo  "grant all privileges on zabbix.* to zabbix@'%' identified by '$zabbix_database_new_password';"  | mysql -h localhost -u root -p$database_new_root_password
echo "flush privileges;" | mysql -h localhost -u root -p$database_new_root_password

#Добавьте свой белый список Ip тк тут НЕБЕЗОПАСНО 0.0.0.0 - все удаленные хосты имеют доступ
echo "$host_password" | sudo -S sed -i  "s/^\(bind-address\s*=\).*/\1 0.0.0.0/"  /etc/mysql/mariadb.conf.d/50-server.cnf
echo "$host_password" | sudo -S service mysql restart

#импорт в базу данных забикса
echo "$host_password" | sudo -S zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix -p$zabbix_database_new_password
echo "$host_password" | sudo -S sed -i  "s/^\(\s*#\s*DBPassword=\).*/\DBPassword=/"  /etc/zabbix/zabbix_server.conf
echo "$host_password" | sudo -S sed -i  "s/^\(DBPassword\s*=\).*/\1 ${zabbix_database_new_password}/" /etc/zabbix/zabbix_server.conf

#Добавьте свой часовой пояс!!!
echo "$host_password" | sudo -S echo "$host_password" | sudo -S  sed -i  "s/^\(\s*#\s*php_value date.timezone Europe\/Riga\).*/\\tphp_value date.timezone Asia\/Kolkata/" /etc/zabbix/apache.conf
fi

echo "$host_password" | sudo -S systemctl restart zabbix-server zabbix-agent apache2
echo "$host_password" | sudo -S systemctl enable zabbix-server zabbix-agent apache2

#Проверка статуса
zabbix_status=$(echo "$host_password" | sudo -S systemctl status zabbix-server |  awk 'NR==3')
echo "$zabbix_status"
