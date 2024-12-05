#!/bin/bash

# Docker container 이름
CONTAINER_NAME=influxdb
# 로컬 백업 디렉토리
BACKUP_DIR=/data/mariadb_db-mariadb/_data/influxdb_backup/
# InfluxDB 데이터 디렉토리 경로
DATA_DIR=/data/mariadb_db-mariadb/_data/influxdb/

# 타 VM 정보
TARGET_HOST="121.189.56.244"
TARGET_PORT=3022
TARGET_USER="root"
TARGET_PASSWORD="bigdatalab!234"
REMOTE_BACKUP_DIR="~/projects/influxdb_backup"

# 타 VM에서 최신 백업 파일 찾기
echo "Fetching latest backup file from remote server..."
LATEST_BACKUP=$(sshpass -p "$TARGET_PASSWORD" ssh -p $TARGET_PORT $TARGET_USER@$TARGET_HOST \
    "ls -t $REMOTE_BACKUP_DIR/influxdb_backup_*.tar.gz | head -n 1")

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backup file found on remote server."
    exit 1
fi

# 최신 백업 파일 이름 가져오기
LATEST_BACKUP_NAME=$(basename $LATEST_BACKUP)

# 타 VM에서 최신 백업 파일 다운로드
echo "Downloading latest backup file: $LATEST_BACKUP_NAME"
sshpass -p "$TARGET_PASSWORD" scp -P $TARGET_PORT $TARGET_USER@$TARGET_HOST:$LATEST_BACKUP $BACKUP_DIR

if [ $? -ne 0 ]; then
    echo "Failed to download backup file from remote server."
    exit 1
fi

# 로컬 백업 파일 경로
BACKUP_FILE="$BACKUP_DIR/$LATEST_BACKUP_NAME"

# 복원 프로세스 시작
echo "Using backup file: $BACKUP_FILE"

# InfluxDB 컨테이너 중지
echo "Stopping InfluxDB container..."
docker stop $CONTAINER_NAME

# 기존 데이터 삭제 (필요 시 백업 후 삭제)
echo "Removing old data..."
rm -rf $DATA_DIR/*

# 백업 파일 복원 (불필요한 경로 제거)
echo "Restoring backup..."
tar --strip-components=4 -xzvf $BACKUP_FILE -C $DATA_DIR

if [ $? -ne 0 ]; then
    echo "Failed to restore backup from file: $BACKUP_FILE"
    exit 1
fi

# InfluxDB 컨테이너 재시작
echo "Starting InfluxDB container..."
docker start $CONTAINER_NAME

# 다운로드한 백업 파일 삭제
echo "Deleting downloaded backup file: $BACKUP_FILE"
rm -f $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "Downloaded backup file deleted successfully."
else
    echo "Failed to delete downloaded backup file."
fi

# 완료 메시지
echo "Restore completed from backup: $BACKUP_FILE"
