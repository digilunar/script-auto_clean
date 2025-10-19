# script-auto_clean
Petunjuk singkat

Simpan file ini:

nano /root/autoclean-telegram-auto.sh


Lalu isi token bot:

BOT_TOKEN="123456789:AAEXAMPLE_KEY"
CHAT_ID="397533470"


Jadikan executable:

chmod +x /root/autoclean-telegram-auto.sh


Jalankan manual sekali untuk tes:

bash /root/autoclean-telegram-auto.sh


Kamu akan langsung dapat laporan di Telegram dari @lunarid_bot.

Jadwalkan cron tiap minggu:

crontab -e


Tambahkan baris:

0 3 * * 0 /root/autoclean-telegram-auto.sh >> /var/log/autoclean.log 2>&1


Skrip ini tidak akan pernah menghapus data produksi atau database aktif, hanya menghapus:

Log besar (PM2, Laravel, webserver, aaPanel)

Cache sistem & snap

Backup lama (>14 hari)

File di Recycle Bin
