#!/bin/bash

# Миграция пользователей между хостами

initialize() {
    echo "Привет - этот скрипт поможет тебе перенести пользователей на новый хост, пользуйся на здоровье(by ShinigamiKiko)"
    sleep  2
    echo "Создание папки для миграции..."
    mkdir -p /root/migrate
    export UGIDLIMIT=1000
}

backup_users_and_groups() {
    echo "Бэкап пользователей и групп..."
    awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/passwd > /root/migrate/passwd.mig
    awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534)' /etc/group > /root/migrate/group.mig
    awk -v LIMIT=$UGIDLIMIT -F: '($3>=LIMIT) && ($3!=65534) {print $1}' /etc/passwd | tee - | grep -F - /etc/shadow > /root/migrate/shadow.mig
    cp /etc/gshadow /root/migrate/gshadow.mig
}

backup_data() {
    echo "Создание бэкапов файлов..."
    tar -zcvpf /root/migrate/home.tar.gz /home
    tar -zcvpf /root/migrate/mail.tar.gz /var/spool/mail
}

backup_current_users() {
    echo "Создание бэкапа текущих пользователей..."
    mkdir -p /root/currentuserssave
    cp /etc/passwd /etc/shadow /etc/group /etc/gshadow /root/currentuserssave
}

transfer_to_new_server() {
    echo "Введите хост для переноса:"
    read TARGET_HOST
    echo "Введите порт (по умолчанию 22):"
    read SCP_PORT
    SCP_PORT=${SCP_PORT:-22}
    scp -R -P $SCP_PORT /root/migrate root@$TARGET_HOST:/root
}

restore_on_new_server() {
    echo "Действия на новом сервере..."
    
    backup_current_users

    cat /root/migrate/passwd.mig >> /etc/passwd
    cat /root/migrate/group.mig >> /etc/group
    cat /root/migrate/shadow.mig >> /etc/shadow
    cp /root/migrate/gshadow.mig /etc/gshadow

    tar -zxvf /root/migrate/home.tar.gz -C /
    tar -zxvf /root/migrate/mail.tar.gz -C /
}

# Вызываем функции по порядку
initialize
backup_users_and_groups
backup_data
backup_current_users  # Этот шаг может быть вызван и на новом сервере, перед восстановлением пользователей
transfer_to_new_server
# restore_on_new_server - на новом сервере мы раскоментируем эту строку - и закоментируем строки выше - кроме бэкапа

echo "Миграция завершена :3! Не забудьте запустить restore_on_new_server на новом машине и выполнить перезагрузку."
