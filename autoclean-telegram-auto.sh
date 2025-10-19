#!/bin/bash
# =====================================================
# Digilunar AutoClean Utility (Non-Interactive)
# Versi 3.0 - by GPT-5 & Paduka
# =====================================================

# === 🔧 KONFIGURASI TELEGRAM ===
BOT_TOKEN="ISI_TOKEN_BOT_KAMU"
CHAT_ID="1122334455"
# get chat_id at @lunarid_bot

# === 🔧 INFORMASI UMUM ===
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
TMP_LOG="/tmp/autoclean_report.txt"

{
echo "🛰️ *[Lunar Clean Report]*"
echo "📅 $DATE"
echo "🖥️ Host: *$HOSTNAME*"
echo ""
echo "🧹 *Pembersihan Otomatis Dimulai...*"
echo "--------------------------------------"
} > "$TMP_LOG"

# ===== PM2 =====
if command -v pm2 >/dev/null 2>&1; then
  pm2 flush >/dev/null 2>&1
  rm -f /root/.pm2/logs/*.log 2>/dev/null
  echo "✅ PM2 logs dibersihkan." >> "$TMP_LOG"
else
  echo "⚠️ PM2 tidak ditemukan." >> "$TMP_LOG"
fi

# ===== Laravel & Web Logs =====
find /www/wwwroot -type f -name "*.log" -delete 2>/dev/null
find /www/wwwlogs -type f -name "*.log" -delete 2>/dev/null
echo "✅ Log aplikasi & webserver dibersihkan." >> "$TMP_LOG"

# ===== Recycle Bin =====
rm -rf /.Recycle_bin/* 2>/dev/null
echo "✅ Recycle Bin dikosongkan." >> "$TMP_LOG"

# ===== MySQL & aaPanel Log =====
find /www/server/data -type f -name "*.err" -size +500M -delete 2>/dev/null
echo "✅ Log MySQL besar dihapus." >> "$TMP_LOG"

# ===== Cache & Log Sistem =====
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
find /www/backup -type f -mtime +14 -delete 2>/dev/null
echo "✅ Backup lama (>14 hari) dihapus." >> "$TMP_LOG"

# ===== Ringkasan Disk =====
USED_BEFORE=$(df -h / | awk 'NR==2{print $3}')
FREE_BEFORE=$(df -h / | awk 'NR==2{print $4}')
PERCENT_BEFORE=$(df -h / | awk 'NR==2{print $5}')
sleep 1
USED_AFTER=$(df -h / | awk 'NR==2{print $3}')
FREE_AFTER=$(df -h / | awk 'NR==2{print $4}')
PERCENT_AFTER=$(df -h / | awk 'NR==2{print $5}')

echo "--------------------------------------" >> "$TMP_LOG"
echo "💾 *Disk Usage:*" >> "$TMP_LOG"
echo "Sebelum: $USED_BEFORE / Bebas: $FREE_BEFORE ($PERCENT_BEFORE)" >> "$TMP_LOG"
echo "Sesudah: $USED_AFTER / Bebas: $FREE_AFTER ($PERCENT_AFTER)" >> "$TMP_LOG"
echo "" >> "$TMP_LOG"
echo "🚀 *Status:* SUCCESS" >> "$TMP_LOG"

# ===== Kirim ke Telegram =====
MESSAGE=$(cat "$TMP_LOG" | sed 's/"/\\"/g')
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
     -d "chat_id=${CHAT_ID}" \
     -d "parse_mode=Markdown" \
     -d "text=${MESSAGE}" >/dev/null 2>&1
