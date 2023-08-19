#!/bin/bash

# Параметры: путь к сайту и путь к конфигурации nginx
site_path="$1"
config_path="$2"

if [[ -z $site_path || -z $config_path ]]; then
  echo "Вы должны ввести путь к сайту и путь к конфигурации nginx"
  exit 1
fi

# Проверка наличия директории сайта
if [[ ! -d $site_path ]]; then
  echo "Директория сайта не найдена!"
  exit 1
fi

# Проверка наличия файла конфигурации nginx
if [[ ! -f $config_path ]]; then
  echo "Файл конфигурации не найден!"
  exit 1
fi

# Создаем директорию для сертификата, если ее еще нет
sudo mkdir -p /etc/nginx/ssl

# Генерируем ключ и самоподписанный сертификат
ssl_path="$site_path/ssl"
sudo mkdir -p $ssl_path
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$ssl_path/myserver.key" -out "$ssl_path/myserver.crt"
echo "ключ сгенерирован, иду дальше"

# Добавление блока конфигурации в файл
echo "server {" | sudo tee -a $config_path
echo "    listen 443 ssl;" | sudo tee -a $config_path
echo "    server_name sitetestforanton.com;" | sudo tee -a $config_path
echo "    ssl_certificate $ssl_path/myserver.crt;" | sudo tee -a $config_path
echo "    ssl_certificate_key $ssl_path/myserver.key;" | sudo tee -a $config_path
echo "    root $site_path;" | sudo tee -a $config_path
echo "}" | sudo tee -a $config_path

# Перезапускаем Nginx для применения изменений
sudo nginx -s reload