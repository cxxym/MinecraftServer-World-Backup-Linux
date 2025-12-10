#!/bin/bash
#
# Minecraft Fabric 自动备份脚本（可本地+远程备份）
#

###========================================
### 配置区域（请按需修改）
###========================================

# 世界存档目录
WORLD_DIR="/path/to/world"

# 临时快照目录（rsync 两遍复制）
SNAPSHOT_DIR="/tmp/mc_world_snapshot"

# 本地备份 ZIP 存放路径
BACKUP_DIR="/path/to/backups"

# 本地保留多少个 ZIP 备份
LOCAL_KEEP=5

# 远程保留多少个 ZIP 备份
REMOTE_KEEP=2

# 远程服务器信息（请自行填写）
REMOTE_USER="your_user"
REMOTE_HOST="your_host"
REMOTE_PORT=22
REMOTE_PASS="your_password"
REMOTE_DIR="/path/to/remote/backup"

# ZIP 压缩级别 0~9
ZIP_LEVEL=7

###========================================
### 安全设置
###========================================
set -e
set -o pipefail

mkdir -p "$SNAPSHOT_DIR" "$BACKUP_DIR"

###========================================
### rsync 双遍复制世界
###========================================
echo "[1/7] rsync 第一次..."
rsync -a --delete "$WORLD_DIR/" "$SNAPSHOT_DIR/"

echo "[2/7] 等待 IO 稳定..."
sleep 2

echo "[3/7] rsync 第二次..."
rsync -a --delete "$WORLD_DIR/" "$SNAPSHOT_DIR/"

###========================================
### ZIP 打包
###========================================
TIME=$(date "+%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="world_$TIME.zip"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

echo "[4/7] ZIP 压缩 (级别: $ZIP_LEVEL)..."
(cd "$SNAPSHOT_DIR" && zip -"$ZIP_LEVEL" -r "$BACKUP_PATH" . >/dev/null)

echo "本地备份完成：$BACKUP_PATH"

###========================================
### 本地清理（LOCAL_KEEP）
###========================================
echo "[5/7] 本地清理，只保留 $LOCAL_KEEP 个 ZIP..."

shopt -s nullglob
LOCAL_FILES=( "$BACKUP_DIR"/*.zip )

if [ ${#LOCAL_FILES[@]} -gt $LOCAL_KEEP ]; then
    for ((i=LOCAL_KEEP; i<${#LOCAL_FILES[@]}; i++)); do
        rm -f "${LOCAL_FILES[$i]}"
    done
fi

###========================================
### 上传远程
###========================================
echo "[6/7] 上传到远程服务器：$REMOTE_HOST"

sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -p $REMOTE_PORT \
"$REMOTE_USER@$REMOTE_HOST" "mkdir -p '$REMOTE_DIR'"

sshpass -p "$REMOTE_PASS" scp -P $REMOTE_PORT "$BACKUP_PATH" \
"$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"

###========================================
### 远程清理（REMOTE_KEEP）
###========================================
echo "[7/7] 远程清理..."

sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -p $REMOTE_PORT \
"$REMOTE_USER@$REMOTE_HOST" '
shopt -s nullglob
FILES=( '"$REMOTE_DIR"'/*.zip )
if [ ${#FILES[@]} -gt '"$REMOTE_KEEP"' ]; then
    for ((i='"$REMOTE_KEEP"'; i<${#FILES[@]}; i++)); do
        rm -f "${FILES[$i]}"
    done
fi
'

echo "全部完成"
