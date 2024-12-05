#!/bin/bash

# Docker container 이름
CONTAINER_NAME=influxdb
# 백업 디렉토리
BACKUP_DIR=/data/mariadb_db-mariadb/_data/influxdb_backup
# 타 VM 정보
TARGET_HOST="121.189.56.244"
TARGET_PORT=3022
TARGET_USER="root"
TARGET_PASSWORD="bigdatalab!234"
TARGET_PATH="~/projects/influxdb_backup"
# 보관 기간 (일 단위)
RETENTION_DAYS=7

# 이메일 설정
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
EMAIL_USER="oyh1202@gmail.com"
EMAIL_PASSWORD="ncnpvkuabvzbrnyx"
EMAIL_RECIPIENT="hyunwoo50@cbnu.ac.kr"
EMAIL_SUBJECT="InfluxDB Backup Status"

# 날짜로 백업 파일 이름 설정
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/influxdb_backup_$TIMESTAMP.tar.gz"

# Python 이메일 전송 함수
send_email() {
    local email_body=$1
    python3 - <<EOF
import smtplib
from email.mime.text import MIMEText

smtp_server = "${SMTP_SERVER}"
smtp_port = ${SMTP_PORT}
user = "${EMAIL_USER}"
password = "${EMAIL_PASSWORD}"
recipient = "${EMAIL_RECIPIENT}"
subject = "${EMAIL_SUBJECT}"
body = """${email_body}"""

msg = MIMEText(body)
msg["Subject"] = subject
msg["From"] = user
msg["To"] = recipient

try:
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(user, password)
        server.send_message(msg)
    print("Email sent successfully.")
except Exception as e:
    print(f"Failed to send email: {e}")
EOF
}

# 이메일 본문 초기화
EMAIL_BODY="InfluxDB Backup Report\n\n"

# InfluxDB 컨테이너 중지
echo "Stopping InfluxDB container..."
docker stop $CONTAINER_NAME
EMAIL_BODY+="[INFO] InfluxDB container stopped.\n"

# 백업 실행
echo "Backing up data..."
tar -czvf $BACKUP_FILE /data/mariadb_db-mariadb/_data/influxdb
EMAIL_BODY+="[INFO] Backup created: $BACKUP_FILE\n"

# InfluxDB 컨테이너 재시작
echo "Starting InfluxDB container..."
docker start $CONTAINER_NAME
EMAIL_BODY+="[INFO] InfluxDB container restarted.\n"

# 타 VM으로 백업 파일 전송 (sshpass 사용)
echo "Transferring backup to remote server..."
sshpass -p "$TARGET_PASSWORD" scp -P $TARGET_PORT $BACKUP_FILE $TARGET_USER@$TARGET_HOST:$TARGET_PATH

if [ $? -eq 0 ]; then
    echo "Backup transferred successfully to $TARGET_HOST:$TARGET_PATH"
    EMAIL_BODY+="[SUCCESS] Backup transferred to $TARGET_HOST:$TARGET_PATH\n"
    echo "Deleting local backup file: $BACKUP_FILE"
    rm -f $BACKUP_FILE
    if [ $? -eq 0 ]; then
        EMAIL_BODY+="[INFO] Local backup file deleted successfully.\n"
    else
        EMAIL_BODY+="[WARNING] Failed to delete local backup file.\n"
    fi
else
    echo "Failed to transfer backup to $TARGET_HOST:$TARGET_PATH"
    EMAIL_BODY+="[ERROR] Failed to transfer backup to $TARGET_HOST:$TARGET_PATH\n"
    send_email "$EMAIL_BODY"
    exit 1
fi

# 타 VM에서 7일 이상 된 백업 파일 삭제 (sshpass 사용)
echo "Deleting backups older than $RETENTION_DAYS days on remote server..."
sshpass -p "$TARGET_PASSWORD" ssh -p $TARGET_PORT $TARGET_USER@$TARGET_HOST \
    "find $TARGET_PATH -type f -name 'influxdb_backup_*.tar.gz' -mtime +$RETENTION_DAYS -exec rm -f {} \;"

if [ $? -eq 0 ]; then
    echo "Old backups deleted successfully on remote server."
    EMAIL_BODY+="[INFO] Old backups deleted successfully on remote server.\n"
else
    echo "Failed to delete old backups on remote server."
    EMAIL_BODY+="[WARNING] Failed to delete old backups on remote server.\n"
fi

# 이메일 전송
echo "Sending email report..."
send_email "$EMAIL_BODY"

# 완료 메시지
echo "Backup, transfer, cleanup, and email report completed."
