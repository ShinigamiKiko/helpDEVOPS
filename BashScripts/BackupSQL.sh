#!/bin/bash

export PGPASSWORD="Пароль от ДБ" 
DB_NAME="Имя ДБ"
DB_USER="Юзер ДБ"
DB_HOST="твой хост"
BACKUP_DIR="/path/to/your/backup/directory"
DATE=$(date +"%Y%m%d%H%M")

# Создание резервной копии
pg_dump -h $DB_HOST -U $DB_USER $DB_NAME > $BACKUP_DIR/db_backup_$DATE.sql

# убери для бэкапа
# tar -czvf $BACKUP_DIR/db_backup_$DATE.tar.gz $BACKUP_DIR/db_backup_$DATE.sql

# Удаление несжатого файла убери решутку 
# rm $BACKUP_DIR/db_backup_$DATE.sql

echo "Бэкап успешен!"
