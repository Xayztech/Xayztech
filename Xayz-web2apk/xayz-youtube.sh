#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}   ULTIMATE TELEGRAM VIDEO BOT INSTALLER (INTERACTIVE) ${NC}"
echo -e "${CYAN}======================================================${NC}"

# --- 1. INPUT DATA (Supaya tidak perlu edit file manual) ---
echo ""
echo -e "${GREEN}[INPUT DATA] Silakan masukkan data bot kamu sekarang:${NC}"
echo ""

read -p "1. Masukkan API_ID (Angka dari my.telegram.org): " IN_API_ID
read -p "2. Masukkan API_HASH (String dari my.telegram.org): " IN_API_HASH
read -p "3. Masukkan BOT_TOKEN (Dari BotFather): " IN_BOT_TOKEN

echo ""
echo -e "${GREEN}Data diterima! Memulai instalasi otomatis...${NC}"
sleep 2

# --- 2. INSTALL PAKET SISTEM ---
echo -e "${CYAN}[1/4] Menginstall paket sistem (FFmpeg, Python, Screen)...${NC}"
if [ -f /etc/debian_version ]; then
    sudo apt update -y
    sudo apt install -y python3 python3-pip ffmpeg screen git
elif [ -n "$TERMUX_VERSION" ]; then
    pkg update -y
    pkg install -y python ffmpeg screen git
else
    echo -e "${RED}[!] OS tidak didukung otomatis.${NC}"
    exit 1
fi

# Buat Folder
FOLDER="bot_ultimate_fix"
rm -rf $FOLDER # Hapus folder lama jika ada biar bersih
mkdir -p $FOLDER
cd $FOLDER

# --- 3. INSTALL LIBRARY PYTHON ---
echo -e "${CYAN}[2/4] Menginstall Library Python...${NC}"
pip3 install --upgrade pip
pip3 install pyrogram tgcrypto pytgcalls yt-dlp

# --- 4. MEMBUAT BOT.PY (Dengan Data Kamu) ---
echo -e "${CYAN}[3/4] Menulis kode bot (Menu Lengkap)...${NC}"

# Kita pakai cat EOF tapi hati-hati dengan variabel bash ($)
# Kita inject variabel IN_API_ID ke dalam file python

cat << EOF > bot.py
import os
import asyncio
from pyrogram import Client, filters
from pyrogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from pytgcalls import PyTgCalls
from pytgcalls.types import MediaStream, AudioQuality, VideoQuality
from yt_dlp import YoutubeDL

# === CONFIG OTOMATIS DARI INSTALLER ===
API_ID = $IN_API_ID
API_HASH = "$IN_API_HASH"
BOT_TOKEN = "$IN_BOT_TOKEN"
# ======================================

app = Client("ultimate_session", api_id=API_ID, api_hash=API_HASH, bot_token=BOT_TOKEN)
call_py = PyTgCalls(app)

# Helper Download
def download_media(url, is_video=True):
    opts = {
        'quiet': True, 
        'noplaylist': True,
        'outtmpl': 'downloads/%(id)s.%(ext)s'
    }
    if is_video:
        opts['format'] = 'best[ext=mp4]'
    else:
        opts['format'] = 'bestaudio'

    with YoutubeDL(opts) as ydl:
        info = ydl.extract_info(url, download=False)
        filename = ydl.prepare_filename(info)
        if not os.path.exists(filename):
            ydl.download([url])
        return filename, info['title'], info['thumbnail'], info.get('duration_string', '??:??')

# --- MENU START (SESUAI REQUEST) ---
@app.on_message(filters.command("start"))
async def start(client, message):
    uname = message.from_user.first_name
    # HTML Caption sesuai request
    caption = f"""
<b><blockquote>==================================</blockquote></b>

<b><blockquote>Olla👋, {uname} このボットは、YouTube Music と YouTube Video Stream のボットです。|| 作成および開発者: @XYCoolcraft</blockquote></b>

<b><blockquote>==⟩ MENU ⟨==</blockquote></b>

/ytvid [judul] - Video Call (Nonton Bareng)
/ytmusic [judul] - Voice Call (Dengar Musik)
/stop - Mematikan Player

<b><blockquote>==================================</blockquote></b>
"""
    # Mengirim Gambar Thumbnail
    await message.reply_photo(
        photo="https://cdn-icons-png.flaticon.com/512/1384/1384060.png",
        caption=caption
    )

# --- FUNGSI UTAMA (VIDEO & MUSIC) ---
@app.on_message(filters.command(["ytvid", "ytmusic", "play"]) & filters.group)
async def stream_handler(client, message):
    cmd = message.command[0]
    query = " ".join(message.command[1:])
    
    if not query:
        return await message.reply("❌ <b>Harap masukkan judul!</b>\nContoh: <code>/ytvid Tulus Monokrom</code>")

    # Tentukan Mode (Video atau Musik)
    is_video = True if cmd in ["ytvid", "play"] else False
    mode_text = "Video" if is_video else "Musik"
    
    status = await message.reply(f"🔍 <b>Mencari {mode_text}...</b>")

    try:
        # 1. Cari URL
        proc = await asyncio.create_subprocess_shell(
            f"yt-dlp --print '%(id)s' 'ytsearch1:{query}'",
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
        )
        stdout, _ = await proc.communicate()
        res = stdout.decode().strip()

        if not res:
            return await status.edit("❌ Tidak ditemukan.")

        url = f"https://www.youtube.com/watch?v={res}"
        
        # 2. Download
        await status.edit(f"📥 <b>Downloading {mode_text}...</b>")
        path, title, thumb, durasi = download_media(url, is_video=is_video)

        # 3. Play Stream
        await status.edit(f"▶️ <b>Memutar {mode_text} di Call...</b>")
        
        if is_video:
            stream = MediaStream(path, audio_parameters=AudioQuality.HIGH, video_parameters=VideoQuality.SD_480p)
        else:
            stream = MediaStream(path, audio_parameters=AudioQuality.HIGH, video_flags=MediaStream.Flags.IGNORE)

        await call_py.play(message.chat.id, stream)

        # 4. Kirim Player Interface (Tombol Lengkap)
        # Tombol Pause/Resume/Stop
        buttons = InlineKeyboardMarkup([
            [
                InlineKeyboardButton("⏮", callback_data="rewind"),
                InlineKeyboardButton("⏸ Pause", callback_data="pause"),
                InlineKeyboardButton("▶️ Play", callback_data="resume"),
                InlineKeyboardButton("⏭", callback_data="fast_forward")
            ],
            [
                InlineKeyboardButton("⏹ STOP", callback_data="stop")
            ]
        ])

        caption_play = f"""
<b>{title}</b>
👤 <b>Request:</b> {message.from_user.mention}
⏱ <b>Durasi:</b> {durasi}
"""
        await message.reply_photo(photo=thumb, caption=caption_play, reply_markup=buttons)
        await status.delete()

    except Exception as e:
        await status.edit(f"❌ Error: {e}")

# --- TOMBOL INTERAKTIF ---
@app.on_callback_query()
async def cb_handler(client, cb):
    chat_id = cb.message.chat.id
    data = cb.data

    if data == "stop":
        await call_py.leave_call(chat_id)
        await cb.message.delete()
    elif data == "pause":
        await call_py.pause_stream(chat_id)
        await cb.answer("Paused")
    elif data == "resume":
        await call_py.resume_stream(chat_id)
        await cb.answer("Resumed")
    elif data in ["rewind", "fast_forward"]:
        await cb.answer("Fitur Seek hanya visual (Stream Realtime)", show_alert=True)

# --- START SYSTEM ---
async def main():
    print("Bot Berjalan...")
    await call_py.start()
    await asyncio.Event().wait()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
EOF

# --- 5. MEMBUAT FILE RUN.SH ---
echo -e "${CYAN}[4/4] Membuat script kontrol 'run.sh'...${NC}"

cat << 'EOF' > run.sh
#!/bin/bash
SESSION="bot_ultimate"
case $1 in
    start)
        echo "Menyalakan Bot..."
        screen -S $SESSION python3 bot.py
        echo "✅ Bot berjalan di background!"
        ;;
    stop)
        screen -X -S $SESSION quit
        echo "⛔ Bot dimatikan."
        ;;
    cek)
        screen -r $SESSION
        ;;
    *)
        echo "Gunakan: ./run.sh start | stop | cek"
        ;;
esac
EOF
chmod +x run.sh

echo ""
echo -e "${GREEN}✅ SUKSES! Bot sudah siap.${NC}"
echo -e "${CYAN}======================================================${NC}"
echo "Sekarang jalankan bot dengan perintah:"
echo "👉 ./run.sh start"
echo -e "${CYAN}======================================================${NC}"
