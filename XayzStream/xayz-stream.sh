#!/bin/bash

echo "=== AUTO INSTALLER STREAM BOT (LATEST V3 + VENV + UI MENU FIX) ==="
echo "Author: @XYCoolcraft"
echo ""


# 2. Input Data
read -p "API ID: " api_id
read -p "API HASH: " api_hash
read -p "BOT TOKEN: " bot_token

# 3. Bersihkan Folder Lama
rm -rf downloads
rm -rf media_storage 
rm -rf session.txt

# 4. Install Paket Sistem
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv ffmpeg screen git

# 5. Buat Virtual Environment (Folder 'downloads')
echo "[+] Membuat Virtual Environment..."
python3 -m venv downloads

# 6. Aktifkan Venv
source downloads/bin/activate

# 7. Install Library (Di dalam Venv)
echo "[+] Menginstall Library Terbaru..."
pip install --upgrade pip
pip install pyrogram tgcrypto pytgcalls youtube-search-python requests pyromod

# 8. Buat config.py
cat <<EOF > config.py
API_ID = ${api_id}
API_HASH = "${api_hash}"
BOT_TOKEN = "${bot_token}"
EOF

# 9. Buat bot.py (MENU SUDAH DIPERBAIKI)
cat <<'EOF' > bot.py
import os
import asyncio
import requests
from pyrogram import Client, filters, errors
from pyrogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from pytgcalls import PyTgCalls
from pytgcalls.types import MediaStream, AudioQuality, VideoQuality
from youtubesearchpython import VideosSearch
from pyromod import listen
import config

STORAGE_DIR = "media_storage"

bot = Client(
    "bot_manager",
    api_id=config.API_ID,
    api_hash=config.API_HASH,
    bot_token=config.BOT_TOKEN
)

userbot = None
call_py = None
IS_USERBOT_ACTIVE = False
active_players = {}

def parse_duration(duration_str):
    try:
        parts = duration_str.split(':')
        if len(parts) == 2: return int(parts[0]) * 60 + int(parts[1])
        elif len(parts) == 3: return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
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
        [InlineKeyboardButton("⟨|| 5s", callback_data="rewind"), InlineKeyboardButton(icon, callback_data=cb), InlineKeyboardButton("5s ||⟩", callback_data="forward")],
        [InlineKeyboardButton("⏹️ Stop", callback_data="stop")]
    ])

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
            res = requests.get(api, timeout=120).json()
            dl = res.get('result', {}).get('mp4')
            ext = 'mp4'
        else:
            api = "https://api.nekolabs.web.id/downloader/youtube/v1"
            res = requests.get(api, params={"url": url, "format": "mp3", "quality": "128", "type": "audio"}, timeout=120).json()
            dl = res.get('result', {}).get('downloadUrl')
            ext = 'mp3'

        if not dl: return None
        
        vid_id = url.split('v=')[-1]
        path = f"{STORAGE_DIR}/{vid_id}.{ext}"
        
        if not os.path.exists(STORAGE_DIR): os.makedirs(STORAGE_DIR)
        if os.path.exists(path): return path
        
        with requests.get(dl, stream=True, timeout=300) as r:
            r.raise_for_status()
            with open(path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192): f.write(chunk)
        return path
    except Exception as e:
        print(f"DL Error: {e}")
        return None

async def start_system():
    global userbot, call_py, IS_USERBOT_ACTIVE
    if not os.path.exists("session.txt"): return False, "Session not found"
    try:
        with open("session.txt") as f: sess = f.read().strip()
        userbot = Client("ub_sess", api_id=config.API_ID, api_hash=config.API_HASH, session_string=sess)
        await userbot.start()
        call_py = PyTgCalls(userbot)
        await call_py.start()
        IS_USERBOT_ACTIVE = True
        return True, "System Ready (V3 Latest)"
    except Exception as e:
        IS_USERBOT_ACTIVE = False
        return False, str(e)

async def ensure_ub(chat_id):
    try:
        m = await bot.get_chat_member(chat_id, userbot.me.id)
        if m.status in ['left', 'kicked']: raise Exception
        return True
    except:
        try:
            await bot.add_chat_members(chat_id, userbot.me.id)
            await asyncio.sleep(1)
            return True
        except: return False

@bot.on_message(filters.command("start"))
async def start(c, m):
    user = m.from_user.first_name
    caption_text = f"""
<b><blockquote>==================================</blockquote></b>

<b><blockquote>Olla👋, {user} このボットは、YouTube Music と YouTube Video Stream のボットです。|| 作成および開発者: @XYCoolcraft</blockquote></b>

<b><blockquote>==⟩ MENU ⟨==</blockquote></b>

/ytvid [judul] - Video Call Sharing
/ytmusic [judul] - Voice Call Music
/login - Hubungkan Userbot (Private)
/stop - Matikan Player

<b><blockquote>==================================</blockquote></b>
"""
    await m.reply_photo(
        photo="https://cdn-icons-png.flaticon.com/512/1384/1384060.png",
        caption=caption_text,
        quote=True
    )

@bot.on_message(filters.command("login") & filters.private)
async def login(c, m):
    if IS_USERBOT_ACTIVE: return await m.reply("Connected.")
    try:
        ph = (await c.ask(m.chat.id, "📱 No HP (+62..):", timeout=60)).text.strip()
        tc = Client(":memory:", api_id=config.API_ID, api_hash=config.API_HASH)
        await tc.connect()
        sc = await tc.send_code(ph)
        otp = (await c.ask(m.chat.id, "📩 OTP (SPASI):", timeout=60)).text.replace(" ", "")
        try: await tc.sign_in(ph, sc.phone_code_hash, otp)
        except errors.SessionPasswordNeeded:
            pw = (await c.ask(m.chat.id, "🔐 Password 2FA:", timeout=60)).text
            await tc.check_password(pw)
        sess = await tc.export_session_string()
        with open("session.txt", "w") as f: f.write(sess)
        await tc.disconnect()
        ok, msg = await start_system()
        await m.reply(f"✅ Login Sukses: {msg}")
    except Exception as e: await m.reply(f"❌ Error: {e}")

@bot.on_message(filters.command(["ytvid", "ytmusic", "play"]) & filters.group)
async def play(c, m):
    if not IS_USERBOT_ACTIVE: return await m.reply("❌ /login di Private dulu")
    q = " ".join(m.command[1:])
    if not q: return await m.reply("❌ Judul?")
    vid = m.command[0] in ["ytvid", "play"]
    
    msg = await m.reply("🔍 Mencari...")
    data = search_yt(q)
    if not data: return await msg.edit("❌ 404 Not Found")
    
    await msg.edit("📥 Downloading to Server...")
    path = download_file(data['link'], vid)
    if not path: return await msg.edit("❌ Gagal Download / Timeout")
    
    if not await ensure_ub(m.chat.id): return await msg.edit("❌ Gagal Add Userbot")
    
    await msg.edit("▶️ Playing...")
    try:
        stream = MediaStream(
            path,
            audio_parameters=AudioQuality.HIGH,
            video_parameters=VideoQuality.SD_480p if vid else None,
            video_flags=MediaStream.Flags.IGNORE if not vid else None
        )
        await call_py.play(m.chat.id, stream)
    except Exception as e:
        return await msg.edit(f"❌ Err V3: {e}")
    
    dur = parse_duration(data['duration'])
    active_players[m.chat.id] = {'title': data['title'], 'duration': dur, 'current': 0, 'paused': False, 'thumb': data['thumb']}
    
    await m.reply_photo(
        data['thumb'],
        caption=f"💿 <b>{data['title']}</b>\n\n{generate_bar(0, dur)}\n\n👤 {m.from_user.mention}",
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
            await call_py.leave_call(cid)
            del active_players[cid]
            await q.message.delete()
        elif d == "pause":
            await call_py.pause_stream(cid)
            p['paused'] = True
        elif d == "resume":
            await call_py.resume_stream(cid)
            p['paused'] = False
        
        if d in ["pause", "resume"]:
             bar = generate_bar(p['current'], p['duration'])
             icon = "⏸️" if p['paused'] else "▶️"
             await q.message.edit_caption(
                 f"💿 <b>{p['title']}</b>\n\n{bar}\n\n👤 {icon}",
                 reply_markup=get_keyboard(p['paused'])
             )
    except: pass

async def main():
    if not os.path.exists(STORAGE_DIR): os.mkdir(STORAGE_DIR)
    await bot.start()
    await start_system()
    print("BOT V3 LATEST + UI MENU READY")
    await asyncio.Event().wait()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
EOF

# 10. Buat Script Start
cat <<EOF > start.sh
#!/bin/bash
source downloads/bin/activate
screen -S BotScreen python3 bot.py
echo "Bot berjalan di VENV 'downloads'. Ketik: screen -r BotScreen"
EOF
chmod +x start.sh

# 11. Jalankan
./start.sh
