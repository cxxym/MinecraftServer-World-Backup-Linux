#!/bin/bash

###========================================
### 配置区域
###========================================

WORLD_DIR="/home/ook/Fabric/world"
SNAPSHOT_DIR="/home/ook/TempWorld"
BACKUP_DIR="/home/ook/Fabric/backups"

LOCAL_KEEP=5
REMOTE_KEEP=2

REMOTE_USER="root"
REMOTE_HOST="REMOTE_SERVER_IP"
REMOTE_PORT=22
REMOTE_PASS="REMOTE_PASSWORD"
REMOTE_DIR="/root/mc_remote_backups"

ZIP_LEVEL=1

###========================================
### 安全设置
###========================================
set -e
set -o pipefail

mkdir -p "$SNAPSHOT_DIR" "$BACKUP_DIR"

clear
echo "== Minecraft 世界备份 =="
sleep 0.5

###========================================
### 1/7 rsync 第一次
###========================================
echo "[1/7] 同步世界（第一次）"
rsync -a --delete "$WORLD_DIR/" "$SNAPSHOT_DIR/" >/dev/null 2>&1

###========================================
### 2/7 等待 IO
###========================================
echo "[2/7] 等待 IO 稳定"
sleep 3

###========================================
### 3/7 rsync 第二次
###========================================
echo "[3/7] 同步世界（第二次）"
rsync -a --delete "$WORLD_DIR/" "$SNAPSHOT_DIR/" >/dev/null 2>&1

###========================================
### 4/7 ZIP 压缩
###========================================
echo "[4/7] 压缩备份（ZIP）"

TIME=$(date "+%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="$BACKUP_DIR/world_$TIME.zip"

cd "$SNAPSHOT_DIR"
zip -r -"$ZIP_LEVEL" -q "$BACKUP_PATH" .
cd - >/dev/null

###========================================
### 5/7 本地清理（彻底隔离 set -e）
###========================================
echo "[5/7] 本地清理"

set +e

shopt -s nullglob
LOCAL_FILES=( "$BACKUP_DIR"/*.zip )
shopt -u nullglob

if [ "${#LOCAL_FILES[@]}" -gt "$LOCAL_KEEP" ]; then
    IFS=$'\n' LOCAL_FILES=($(ls -1t "${LOCAL_FILES[@]}"))
    unset IFS
    for ((i=LOCAL_KEEP; i<${#LOCAL_FILES[@]}; i++)); do
        rm -f "${LOCAL_FILES[$i]}"
    done
fi

set -e

###========================================
### 6/7 上传远程（一定会执行）
###========================================
echo "[6/7] 上传远程"

sshpass -p "$REMOTE_PASS" ssh -q -o StrictHostKeyChecking=no -p $REMOTE_PORT \
"$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$REMOTE_DIR'"

sshpass -p "$REMOTE_PASS" scp -P $REMOTE_PORT \
"$BACKUP_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"

###========================================
### 7/7 远程清理（修复版，强制 bash）
###========================================
echo "[7/7] 远程清理"

sshpass -p "$REMOTE_PASS" ssh -q -o StrictHostKeyChecking=no -p $REMOTE_PORT \
"$REMOTE_USER@$REMOTE_HOST" "bash -s" <<EOF
set +e

shopt -s nullglob
FILES=( "$REMOTE_DIR"/*.zip )
shopt -u nullglob

if [ \${#FILES[@]} -gt $REMOTE_KEEP ]; then
    IFS=\$'\n' FILES=(\$(ls -1t "\${FILES[@]}"))
    unset IFS
    for ((i=$REMOTE_KEEP; i<\${#FILES[@]}; i++)); do
        rm -f "\${FILES[\$i]}"
    done
fi

set -e
EOF

echo
echo "== 备份完成 =="
