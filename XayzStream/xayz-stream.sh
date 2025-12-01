#!/bin/bash

echo "=== BOT STREAM BY: @XYCoolcraft ==="
echo ""

screen -X -S XayzStream quit 2>/dev/null
screen -wipe 2>/dev/null

# 2. Input Data (Biar file config bersih)
read -p "API ID: " api_id
read -p "API HASH: " api_hash
read -p "BOT TOKEN: " bot_token

# 3. UNINSTALL SEMUA LIBRARY SAMPAH (PENTING!)
# Kita hapus semua library yang tadi kamu kasih di contoh, biar VPS lega.
rm -rf downloads
mkdir -p downloads

# 4. Install Paket Sistem Dasar
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip ffmpeg screen git

# 5. Buat requirements.txt VERSI BERSIH (Hanya yang dipakai)
cat <<EOF > requirements.txt
pyrogram
tgcrypto==1.2.5
py-tgcalls==2.0.2
ntgcalls==1.2.1
numpy=1.26.4
youtube-search-python
requests
pyromod
EOF

# 6. Install Library Ringan
echo "[+] Menginstall Library..."
pip3 install --upgrade pip
pip3 install -r requirements.txt

# 7. Buat config.py
cat <<EOF > config.py
API_ID = ${api_id}
API_HASH = "${api_hash}"
BOT_TOKEN = "${bot_token}"
EOF

# 8. Buat bot.py
# Kode ini disesuaikan khusus untuk library versi 2
cat <<'EOF' > bot.py
import os
import asyncio
import requests
from pyrogram import Client, filters, errors
from pyrogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from pytgcalls import PyTgCalls
from pytgcalls.types import InputAudioStream, InputVideoStream
from youtubesearchpython import VideosSearch
from pyromod import listen
import config

# Init Client
bot = Client(
    "bot_clean",
    api_id=config.API_ID,
    api_hash=config.API_HASH,
    bot_token=config.BOT_TOKEN
)

userbot = None
call_py = None
IS_USERBOT_ACTIVE = False
active_players = {}

# --- Helper ---
def parse_duration(duration_str):
    try:
        parts = duration_str.split(':')
        if len(parts) == 2:
            return int(parts[0]) * 60 + int(parts[1])
        elif len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
        return 0
    except: return 0

def convert_seconds(seconds):
    seconds = int(seconds)
    seconds %= (24 * 3600)
    hour = seconds // 3600
    seconds %= 3600
    minutes = seconds // 60
    seconds %= 60
    return "%d:%02d:%02d" % (hour, minutes, seconds) if hour > 0 else "%02d:%02d" % (minutes, seconds)

def generate_bar(current, total):
    percentage = current / total if total > 0 else 0
    filled = int(percentage * 10)
    bar = "─" * filled + "⚪" + "─" * (10 - filled)
    return f"{convert_seconds(current)} {bar} {convert_seconds(total)}"

def get_keyboard(is_paused):
    icon = "▶️" if is_paused else "⏸️"
    cb = "resume" if is_paused else "pause"
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("⏹️ Stop", callback_data="stop"), InlineKeyboardButton(icon, callback_data=cb)]
    ])

# --- Search & DL ---
def search_yt(query):
    try:
        s = VideosSearch(query, limit=1).result()
        if s['result']:
            d = s['result'][0]
            return {'title': d['title'], 'link': d['link'], 'duration': d.get('duration', '00:00'), 'thumb': d['thumbnails'][0]['url']}
    except: return None

def download_file(url, is_video):
    try:
        if is_video:
            api = f"https://api.betabotz.eu.org/api/download/ytmp4?url={url}&apikey=Btz-XYCoolcraft"
            res = requests.get(api, timeout=60).json()
            dl = res.get('result', {}).get('mp4')
            ext = 'mp4'
        else:
            api = "https://api.nekolabs.web.id/downloader/youtube/v1"
            res = requests.get(api, params={"url": url, "format": "mp3", "quality": "128", "type": "audio"}, timeout=60).json()
            dl = res.get('result', {}).get('downloadUrl')
            ext = 'mp3'

        if not dl: return None
        path = f"downloads/{url.split('v=')[-1]}.{ext}"
        if os.path.exists(path): return path
        
        with requests.get(dl, stream=True, timeout=120) as r:
            r.raise_for_status()
            with open(path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192): f.write(chunk)
        return path
    except: return None

# --- Core System ---
async def start_system():
    global userbot, call_py, IS_USERBOT_ACTIVE
    if not os.path.exists("session.txt"): return False, "No Session"
    try:
        with open("session.txt") as f: sess = f.read().strip()
        userbot = Client("ub_sess", api_id=config.API_ID, api_hash=config.API_HASH, session_string=sess)
        await userbot.start()
        call_py = PyTgCalls(userbot)
        await call_py.start()
        IS_USERBOT_ACTIVE = True
        return True, "Ready"
    except Exception as e:
        IS_USERBOT_ACTIVE = False
        return False, str(e)

async def join_call(chat_id, path, is_video):
    try:
        # LOGIKA V2 LEGACY
        stream = InputAudioStream(path)
        video_stream = InputVideoStream(path) if is_video else None
        
        await call_py.join_group_call(
            chat_id,
            stream,
            stream_video=video_stream
        )
    except Exception as e:
        # Jika error "Already Joined", coba leave dulu lalu join lagi
        try:
            await call_py.leave_group_call(chat_id)
            await asyncio.sleep(1)
            await call_py.join_group_call(chat_id, stream, stream_video=video_stream)
        except:
            raise e

# --- Handlers ---
@bot.on_message(filters.command("start"))
async def start(c, m):
    await m.reply_photo(
        "https://cdn-icons-png.flaticon.com/512/1384/1384060.png",
        caption=f"<b>Halo {m.from_user.first_name}!</b>\nBot Musik & Video (Clean Version).\n\n/ytvid [judul]\n/ytmusic [judul]\n/login (Private)\n/stop"
    )

@bot.on_message(filters.command("login") & filters.private)
async def login(c, m):
    if IS_USERBOT_ACTIVE: return await m.reply("Sudah Konek.")
    try:
        ph = (await c.ask(m.chat.id, "No HP:", timeout=60)).text.strip()
        tc = Client(":memory:", api_id=config.API_ID, api_hash=config.API_HASH)
        await tc.connect()
        sc = await tc.send_code(ph)
        otp = (await c.ask(m.chat.id, "OTP (Spasi):", timeout=60)).text.replace(" ", "")
        try: await tc.sign_in(ph, sc.phone_code_hash, otp)
        except errors.SessionPasswordNeeded:
            pw = (await c.ask(m.chat.id, "2FA:", timeout=60)).text
            await tc.check_password(pw)
        sess = await tc.export_session_string()
        with open("session.txt", "w") as f: f.write(sess)
        await tc.disconnect()
        ok, msg = await start_system()
        await m.reply(f"Login Sukses: {msg}")
    except Exception as e: await m.reply(f"Error: {e}")

@bot.on_message(filters.command(["ytvid", "ytmusic", "play"]) & filters.group)
async def play(c, m):
    if not IS_USERBOT_ACTIVE: return await m.reply("Userbot Off. /login dulu.")
    q = " ".join(m.command[1:])
    if not q: return await m.reply("Judul?")
    vid = m.command[0] in ["ytvid", "play"]
    
    msg = await m.reply("🔍 ...")
    data = search_yt(q)
    if not data: return await msg.edit("404")
    
    await msg.edit("📥 Downloading...")
    path = download_file(data['link'], vid)
    if not path: return await msg.edit("Gagal DL")
    
    # Auto Add Userbot
    try: await bot.get_chat_member(m.chat.id, userbot.me.id)
    except: 
        try: await bot.add_chat_members(m.chat.id, userbot.me.id)
        except: return await msg.edit("Masukkan Userbot jadi admin manual!")

    await msg.edit("▶️ Playing...")
    try:
        await join_call(m.chat.id, path, vid)
    except Exception as e:
        return await msg.edit(f"Err Call: {e}")
    
    dur = parse_duration(data['duration'])
    active_players[m.chat.id] = {'title': data['title'], 'duration': dur, 'current': 0, 'paused': False}
    
    await m.reply_photo(
        data['thumb'],
        caption=f"💿 <b>{data['title']}</b>\n{generate_bar(0, dur)}",
        reply_markup=get_keyboard(False)
    )
    await msg.delete()

@bot.on_callback_query()
async def cb(c, q):
    cid = q.message.chat.id
    if cid not in active_players: return
    d = q.data
    p = active_players[cid]
    
    try:
        if d == "stop":
            await call_py.leave_group_call(cid)
            del active_players[cid]
            await q.message.delete()
        elif d == "pause":
            await call_py.pause_stream(cid)
            p['paused'] = True
            await q.message.edit_reply_markup(get_keyboard(True))
        elif d == "resume":
            await call_py.resume_stream(cid)
            p['paused'] = False
            await q.message.edit_reply_markup(get_keyboard(False))
    except: pass

async def main():
    if not os.path.exists("downloads"): os.mkdir("downloads")
    await bot.start()
    await start_system()
    print("BOT BERSIH SIAP")
    await asyncio.Event().wait()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
EOF

# 9. Script Start
cat <<EOF > start.sh
#!/bin/bash
screen -S XayzBot python3 bot.py
echo "Bot berjalan. Ketik: screen -r XayzBot"
EOF
chmod +x start.sh

# 10. Eksekusi
./start.sh
