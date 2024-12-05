#!/bin/bash

# 0. 중복 실행 방지
if [ -f /tmp/setup_done ]; then
    echo "Setup already done, skipping."
    exit 0
fi

# 1. 환경 변수 설정
export TERM=xterm
export DEBIAN_FRONTEND=noninteractive

# 2. 필수 패키지 설치
echo "Installing required packages..."
apt-get update && apt-get install -y cron sshpass || exit 1

# 3. `policy-rc.d` 설정
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d

# 4. 백업 스크립트 설정
echo "Setting up backup script..."
chmod +x /usr/local/bin/influxdb_backup.sh

# 5. 크론탭 작업 설정
CRON_JOB="0 0 * * * /usr/local/bin/influxdb_backup.sh >> /var/log/influxdb_backup.log 2>&1"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (echo "$CRON_JOB" | crontab -)

# 6. cron 서비스 시작
echo "Starting cron service..."
cron -f &

# 5. InfluxDB 시작
echo "Starting InfluxDB..."
influxd

# 7. 완료 마크 파일 생성
touch /tmp/setup_done
