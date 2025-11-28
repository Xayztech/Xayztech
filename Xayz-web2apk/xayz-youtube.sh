#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}   ULTIMATE TELEGRAM VIDEO BOT (FIXED VERSION)         ${NC}"
echo -e "${CYAN}======================================================${NC}"

# --- 1. INPUT DATA ---
echo ""
echo -e "${GREEN}[INPUT DATA] Masukkan data bot kamu lagi:${NC}"
echo ""

read -p "1. Masukkan API_ID (Angka): " IN_API_ID
read -p "2. Masukkan API_HASH (String): " IN_API_HASH
read -p "3. Masukkan BOT_TOKEN: " IN_BOT_TOKEN

echo ""
echo -e "${GREEN}Data diterima. Memulai perbaikan instalasi...${NC}"
sleep 2

# --- 2. INSTALL PAKET SISTEM (DITAMBAH BUILD-ESSENTIAL) ---
echo -e "${CYAN}[1/4] Menginstall 'Alat Tukang' (Compiler & Python Dev)...${NC}"

# Update repo dulu
sudo apt-get update -y

# Install paket wajib untuk compile tgcalls (INI YANG KURANG TADI)
sudo apt-get install -y build-essential python3-dev libffi-dev libssl-dev

# Install paket standar
sudo apt-get install -y python3 python3-pip ffmpeg screen git

# Buat Folder
FOLDER="bot_video_fixed"
rm -rf $FOLDER 
mkdir -p $FOLDER
cd $FOLDER

# --- 3. INSTALL LIBRARY PYTHON (DENGAN CARA AMAN) ---
echo -e "${CYAN}[2/4] Menginstall Library Python (Ini mungkin agak lama)...${NC}"

# Upgrade pip
python3 -m pip install --upgrade pip

# Install satu per satu untuk mencegah konflik
pip3 install yt-dlp
pip3 install tgcrypto
pip3 install pyrogram==2.0.106

echo -e "${CYAN}...Sedang mengcompile PyTgCalls (Mohon tunggu, jangan dicancel)...${NC}"
# Kita install versi spesifik yang stabil
pip3 install pytgcalls==2.1.0

# --- 4. MEMBUAT BOT.PY ---
echo -e "${CYAN}[3/4] Menulis ulang kode bot...${NC}"

cat << EOF > bot.py
import os
import asyncio
from pyrogram import Client, filters
from pyrogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from pytgcalls import PyTgCalls
from pytgcalls.types import MediaStream, AudioQuality, VideoQuality
from yt_dlp import YoutubeDL

# === CONFIG OTOMATIS ===
API_ID = $IN_API_ID
API_HASH = "$IN_API_HASH"
BOT_TOKEN = "$IN_BOT_TOKEN"
# =======================

app = Client("fixed_session", api_id=API_ID, api_hash=API_HASH, bot_token=BOT_TOKEN)
call_py = PyTgCalls(app)

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

@app.on_message(filters.command("start"))
async def start(client, message):
    uname = message.from_user.first_name
    caption = f"""
<b><blockquote>==================================</blockquote></b>
<b><blockquote>Olla👋, {uname} このボットは、YouTube Music と YouTube Video Stream のボットです。|| 作成および開発者: @XYCoolcraft</blockquote></b>
<b><blockquote>==⟩ MENU ⟨==</blockquote></b>

/ytvid [judul] - Video Call
/ytmusic [judul] - Voice Call
/stop - Matikan
<b><blockquote>==================================</blockquote></b>
"""
    await message.reply_photo(photo="https://cdn-icons-png.flaticon.com/512/1384/1384060.png", caption=caption)

@app.on_message(filters.command(["ytvid", "ytmusic", "play"]) & filters.group)
async def stream_handler(client, message):
    cmd = message.command[0]
    query = " ".join(message.command[1:])
    
    if not query:
        return await message.reply("❌ <b>Harap masukkan judul!</b>")

    is_video = True if cmd in ["ytvid", "play"] else False
    mode_text = "Video" if is_video else "Musik"
    
    status = await message.reply(f"🔍 <b>Mencari {mode_text}...</b>")

    try:
        proc = await asyncio.create_subprocess_shell(
            f"yt-dlp --print '%(id)s' 'ytsearch1:{query}'",
            stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
        )
        stdout, _ = await proc.communicate()
        res = stdout.decode().strip()

        if not res:
            return await status.edit("❌ Tidak ditemukan.")

        url = f"https://www.youtube.com/watch?v={res}"
        
        await status.edit(f"📥 <b>Downloading {mode_text}...</b>")
        path, title, thumb, durasi = download_media(url, is_video=is_video)

        await status.edit(f"▶️ <b>Memutar {mode_text}...</b>")
        
        if is_video:
            stream = MediaStream(path, audio_parameters=AudioQuality.HIGH, video_parameters=VideoQuality.SD_480p)
        else:
            stream = MediaStream(path, audio_parameters=AudioQuality.HIGH, video_flags=MediaStream.Flags.IGNORE)

        await call_py.play(message.chat.id, stream)

        buttons = InlineKeyboardMarkup([
            [InlineKeyboardButton("⏹ STOP", callback_data="stop")]
        ])

        caption_play = f"<b>{title}</b>\n👤 <b>Req:</b> {message.from_user.mention}\n⏱ <b>Durasi:</b> {durasi}"
        await message.reply_photo(photo=thumb, caption=caption_play, reply_markup=buttons)
        await status.delete()

    except Exception as e:
        await status.edit(f"❌ Error: {e}")

@app.on_callback_query(filters.regex("stop"))
async def stop_cb(client, cb):
    await call_py.leave_call(cb.message.chat.id)
    await cb.message.delete()

async def main():
    print("Bot Berjalan...")
    await call_py.start()
    await asyncio.Event().wait()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
EOF

# --- 5. RUN SCRIPT ---
echo -e "${CYAN}[4/4] Membuat script kontrol 'run.sh'...${NC}"

cat << 'EOF' > run.sh
#!/bin/bash
SESSION="bot_fixed"
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
echo -e "${GREEN}✅ PERBAIKAN SELESAI!${NC}"
echo "Silakan jalankan:"
echo "cd bot_video_fixed"
echo "./run.sh start"
echo ""
