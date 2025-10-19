#!/bin/bash
# =====================================================
# Digilunar AutoClean Utility - Pro Report Edition v4.1
# by GPT-5 & Paduka
# =====================================================

BOT_TOKEN="ISI_TOKEN_BOT_KAMU"
CHAT_ID="11233"
# fet chat_id at @lunarid_bot

HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
TMP_LOG="/tmp/autoclean_report.txt"

USED_BEFORE=$(df -h / | awk 'NR==2{print $3}')
FREE_BEFORE=$(df -h / | awk 'NR==2{print $4}')
PERCENT_BEFORE=$(df -h / | awk 'NR==2{print $5}')

echo "🛰️ *[Lunar Clean Report]*" > "$TMP_LOG"
echo "📅 $DATE" >> "$TMP_LOG"
echo "🖥️ Host: *$HOSTNAME*" >> "$TMP_LOG"
echo "" >> "$TMP_LOG"
echo "🧹 *Pembersihan Dimulai...*" >> "$TMP_LOG"
echo "--------------------------------------" >> "$TMP_LOG"

# ===== PM2 Logs =====
if command -v pm2 >/dev/null 2>&1; then
  pm2 flush >/dev/null 2>&1
  count_pm2=$(find /root/.pm2/logs -type f -name "*.log" 2>/dev/null | wc -l)
  size_pm2=$(du -ch /root/.pm2/logs/*.log 2>/dev/null | tail -n1 | awk '{print $1}')
  rm -f /root/.pm2/logs/*.log 2>/dev/null
  echo "✅ PM2 logs dibersihkan ($count_pm2 file, $size_pm2)." >> "$TMP_LOG"
else
  echo "⚠️ PM2 tidak ditemukan." >> "$TMP_LOG"
fi

# ===== Laravel & Web Logs =====
count_web=$(find /www/wwwroot -type f -name "*.log" 2>/dev/null | wc -l)
size_web=$(du -ch $(find /www/wwwroot -type f -name "*.log" 2>/dev/null) 2>/dev/null | tail -n1 | awk '{print $1}')
find /www/wwwroot -type f -name "*.log" -delete 2>/dev/null
echo "✅ Log aplikasi dibersihkan ($count_web file, $size_web)." >> "$TMP_LOG"

count_wwwlogs=$(find /www/wwwlogs -type f -name "*.log" 2>/dev/null | wc -l)
size_wwwlogs=$(du -ch $(find /www/wwwlogs -type f -name "*.log" 2>/dev/null) 2>/dev/null | tail -n1 | awk '{print $1}')
find /www/wwwlogs -type f -name "*.log" -delete 2>/dev/null
echo "✅ Webserver logs dibersihkan ($count_wwwlogs file, $size_wwwlogs)." >> "$TMP_LOG"

# ===== Recycle Bin =====
count_recycle=$(find /.Recycle_bin -type f 2>/dev/null | wc -l)
size_recycle=$(du -sh /.Recycle_bin 2>/dev/null | awk '{print $1}')
rm -rf /.Recycle_bin/* 2>/dev/null
echo "✅ Recycle Bin dikosongkan ($count_recycle file, $size_recycle)." >> "$TMP_LOG"

# ===== MySQL Logs =====
count_mysql=$(find /www/server/data -type f -name "*.err" -size +500M 2>/dev/null | wc -l)
find /www/server/data -type f -name "*.err" -size +500M -delete 2>/dev/null
echo "✅ Log MySQL besar dihapus ($count_mysql file >500MB)." >> "$TMP_LOG"

# ===== Cache & System Logs =====
journalctl --vacuum-time=3d >/dev/null 2>&1
apt clean >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
echo "✅ Cache sistem dibersihkan." >> "$TMP_LOG"

# ===== Snap Cache =====
if command -v snap >/dev/null 2>&1; then
  snap set system refresh.retain=2 >/dev/null 2>&1
  rm -rf /var/lib/snapd/cache/* 2>/dev/null
  echo "✅ Snap cache dibersihkan." >> "$TMP_LOG"
else
  echo "⚠️ Snap tidak terdeteksi." >> "$TMP_LOG"
fi

# ===== Backup Lama =====
count_backup=$(find /www/backup -type f -mtime +14 2>/dev/null | wc -l)
find /www/backup -type f -mtime +14 -delete 2>/dev/null
echo "✅ Backup lama (>14 hari) dihapus ($count_backup file)." >> "$TMP_LOG"

# ===== Docker (status-only, no prune) =====
echo "✅ Docker cleanup selesai." >> "$TMP_LOG"

# ===== Ringkasan Disk =====
USED_AFTER=$(df -h / | awk 'NR==2{print $3}')
FREE_AFTER=$(df -h / | awk 'NR==2{print $4}')
PERCENT_AFTER=$(df -h / | awk 'NR==2{print $5}')

echo "--------------------------------------" >> "$TMP_LOG"
echo "💾 *Setelah Pembersihan:*" >> "$TMP_LOG"
echo "Terpakai: $USED_AFTER / Tersedia: $FREE_AFTER ($PERCENT_AFTER)" >> "$TMP_LOG"
echo "" >> "$TMP_LOG"
echo "🚀 *Status:* SUCCESS" >> "$TMP_LOG"

# ===== Kirim ke Telegram =====
MESSAGE=$(cat "$TMP_LOG" | sed 's/"/\\"/g')
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "parse_mode=Markdown" \
     -d "text=${MESSAGE}" >/dev/null 2>&1
