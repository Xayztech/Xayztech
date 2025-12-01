#!/bin/bash

clear
echo "=== AUTO INSTALLER BOT STREAM VIA VPS || CREATED AND DEVELOPER BY: @XYCoolcraft ==="
echo ""

read -p "API ID: " api_id
read -p "API HASH: " api_hash
read -p "BOT TOKEN: " bot_token

echo ""
echo "[+] Menginstall Paket Sistem..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip ffmpeg screen

echo "[+] Membuat Folder..."
mkdir -p Xayz-stream
cd Xayz-stream

echo "[+] Membuat requirements.txt..."
cat <<EOF > requirements.txt
pyrogram
tgcrypto
pytgcalls==3.0.0.dev24
youtube-search-python
requests
pyromod
nest_asyncio
EOF

echo "[+] Membuat config.py..."
cat <<EOF > config.py
API_ID = ${api_id}
API_HASH = "${api_hash}"
BOT_TOKEN = "${bot_token}"
EOF

echo "[+] Membuat bot.py..."
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
        if len(parts) == 2:
            return int(parts[0]) * 60 + int(parts[1])
        elif len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
        return 0
    except:
        return 0

def search_yt(query):
    try:
        search = VideosSearch(query, limit=1)
        result = search.result()
        if result['result']:
            data = result['result'][0]
            return {
                'title': data['title'],
                'link': data['link'],
                'id': data['id'],
                'duration': data.get('duration', '00:00'),
                'thumb': data['thumbnails'][0]['url']
            }
    except:
        return None
    return None

def download_and_save(url, is_video=True):
    try:
        if is_video:
            api_url = f"https://api.betabotz.eu.org/api/download/ytmp4?url={url}&apikey=Btz-XYCoolcraft"
            req = requests.get(api_url, timeout=120).json()
            if not req.get('status') or not req.get('result'): return None
            dl_url = req['result'].get('mp4')
            ext = 'mp4'
        else:
            api_url = "https://api.nekolabs.web.id/downloader/youtube/v1"
            params = {"url": url, "format": "mp3", "quality": "128", "type": "audio"}
            req = requests.get(api_url, params=params, timeout=120).json()
            if not req.get('success') or not req.get('result'): return None
            dl_url = req['result'].get('downloadUrl')
            ext = 'mp3'

        if not dl_url: return None

        vid_id = url.split('v=')[-1]
        file_path = f"downloads/{vid_id}.{ext}"
        
        if not os.path.exists("downloads"):
            os.makedirs("downloads")

        if os.path.exists(file_path):
            return file_path

        with requests.get(dl_url, stream=True, timeout=120) as r:
            r.raise_for_status()
            with open(file_path, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
        
        return file_path
    except Exception as e:
        print(f"Download Error: {e}")
        return None

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

def get_player_keyboard(is_paused):
    play_pause_btn = InlineKeyboardButton("▶️", callback_data="resume") if is_paused else InlineKeyboardButton("⏸️", callback_data="pause")
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton("⟨|| 5s", callback_data="rewind"),
            play_pause_btn,
            InlineKeyboardButton("5s ||⟩", callback_data="forward")
        ],
        [
            InlineKeyboardButton("⏹️ Stop", callback_data="stop")
        ]
    ])

async def start_userbot_system():
    global userbot, call_py, IS_USERBOT_ACTIVE
    if not os.path.exists("session.txt"):
        return False, "Session file not found."
    try:
        with open("session.txt", "r") as f:
            session_str = f.read().strip()
        if not session_str:
            return False, "Session file empty."
        
        userbot = Client(
            "userbot_session",
            api_id=config.API_ID,
            api_hash=config.API_HASH,
            session_string=session_str
        )
        await userbot.start()
        call_py = PyTgCalls(userbot)
        await call_py.start()
        IS_USERBOT_ACTIVE = True
        return True, "System Started."
    except Exception as e:
        IS_USERBOT_ACTIVE = False
        return False, str(e)

async def ensure_userbot_in_group(chat_id):
    try:
        member = await bot.get_chat_member(chat_id, userbot.me.id)
        if member.status in ['kicked', 'left']:
            raise Exception
        return True
    except:
        try:
            await bot.add_chat_members(chat_id, userbot.me.id)
            await asyncio.sleep(1)
            return True
        except:
            return False

@bot.on_message(filters.command("start"))
async def start_handler(client, message):
    user = message.from_user.first_name
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
    await message.reply_photo(
        photo="https://cdn-icons-png.flaticon.com/512/1384/1384060.png",
        caption=caption_text,
        quote=True
    )

@bot.on_message(filters.command("login") & filters.private)
async def login_handler(client, message):
    global IS_USERBOT_ACTIVE
    if IS_USERBOT_ACTIVE:
        return await message.reply("Userbot is already connected.")
    
    user_id = message.chat.id
    try:
        nomor = await client.ask(user_id, "📱 Phone Number (e.g., +628123456789):", timeout=300)
    except: return
    
    phone = nomor.text.strip()
    temp_client = Client("temp_login", api_id=config.API_ID, api_hash=config.API_HASH, in_memory=True)
    await temp_client.connect()
    
    try:
        sent_code = await temp_client.send_code(phone)
    except Exception as e:
        await temp_client.disconnect()
        return await message.reply(f"Failed to send code: {e}")
    
    try:
        otp = await client.ask(user_id, "📩 OTP Code (Use SPACE, e.g., 1 2 3 4 5):", timeout=300)
    except: return
    
    phone_code = otp.text.replace(" ", "")
    
    try:
        await temp_client.sign_in(phone, sent_code.phone_code_hash, phone_code)
    except errors.SessionPasswordNeeded:
        try:
            pw = await client.ask(user_id, "🔐 2FA Password:", timeout=300)
            await temp_client.check_password(pw.text)
        except Exception as e:
            await temp_client.disconnect()
            return await message.reply("Invalid Password.")
    except Exception as e:
        await temp_client.disconnect()
        return await message.reply(f"Login Error: {e}")
    
    session_string = await temp_client.export_session_string()
    await temp_client.disconnect()
    
    with open("session.txt", "w") as f:
        f.write(session_string)
    
    success, msg = await start_userbot_system()
    if success:
        await message.reply("✅ Login Successful. System Started.")
    else:
        await message.reply(f"⚠️ Login saved but failed to start: {msg}")

@bot.on_message(filters.command(["ytvid", "ytmusic", "play"]) & filters.group)
async def stream_handler(client, message):
    if not IS_USERBOT_ACTIVE:
        return await message.reply("❌ Userbot not connected. Please /login in Private Chat.")

    cmd = message.command[0]
    query = " ".join(message.command[1:])
    if not query: return await message.reply("❌ Please provide a title.")
    
    is_video = cmd in ["ytvid", "play"]
    mode = "Video" if is_video else "Music"
    
    msg = await message.reply(f"🔍 Searching {mode}...")
    
    video_data = search_yt(query)
    if not video_data:
        return await msg.edit("❌ Not Found.")
    
    url = video_data['link']
    title = video_data['title']
    duration_str = video_data['duration']
    thumb = video_data['thumb']
    
    await msg.edit(f"📥 Downloading (Max 2 Min)...")
    
    file_path = download_and_save(url, is_video)
    
    if not file_path:
        return await msg.edit("❌ Download Failed or Timeout (API Slow).")
    
    if not await ensure_userbot_in_group(message.chat.id):
        return await msg.edit(f"❌ Failed to add Userbot. Please add @{userbot.me.username} manually.")

    await msg.edit(f"▶️ Starting Stream from Server...")
    
    if is_video:
        stream = MediaStream(
            file_path, 
            audio_parameters=AudioQuality.HIGH, 
            video_parameters=VideoQuality.SD_480p
        )
    else:
        stream = MediaStream(
            file_path, 
            audio_parameters=AudioQuality.HIGH, 
            video_flags=MediaStream.Flags.IGNORE
        )
    
    await call_py.play(message.chat.id, stream)
    
    duration_sec = parse_duration(duration_str)
    
    active_players[message.chat.id] = {
        'title': title,
        'duration': duration_sec,
        'current': 0,
        'is_paused': False,
        'thumb': thumb
    }

    bar = generate_bar(0, duration_sec)
    caption = f"💿 <b>{title}</b>\n\n{bar}\n\n👤 <b>Req:</b> {message.from_user.mention}"
    
    await message.reply_photo(
        thumb,
        caption=caption,
        reply_markup=get_player_keyboard(False)
    )
    await msg.delete()

async def update_display(chat_id, message):
    if chat_id not in active_players: return
    player = active_players[chat_id]
    bar = generate_bar(player['current'], player['duration'])
    state_icon = "⏸️" if player['is_paused'] else "▶️"
    caption = f"💿 <b>{player['title']}</b>\n\n{bar}\n\n👤 <b>Status:</b> {state_icon}"
    try:
        await message.edit_caption(caption=caption, reply_markup=get_player_keyboard(player['is_paused']))
    except: pass

@bot.on_callback_query()
async def cb_handler(client, cb):
    chat_id = cb.message.chat.id
    if chat_id not in active_players:
        return await cb.answer("No active player.", show_alert=True)
    
    data = cb.data
    player = active_players[chat_id]
    
    try:
        if data == "stop":
            await call_py.leave_call(chat_id)
            del active_players[chat_id]
            await cb.message.delete()
        elif data == "pause":
            await call_py.pause_stream(chat_id)
            player['is_paused'] = True
            await update_display(chat_id, cb.message)
            await cb.answer("Paused")
        elif data == "resume":
            await call_py.resume_stream(chat_id)
            player['is_paused'] = False
            await update_display(chat_id, cb.message)
            await cb.answer("Resumed")
        elif data == "forward":
            player['current'] = min(player['current'] + 5, player['duration'])
            await update_display(chat_id, cb.message)
            await cb.answer("Forward 5s")
        elif data == "rewind":
            player['current'] = max(player['current'] - 5, 0)
            await update_display(chat_id, cb.message)
            await cb.answer("Rewind 5s")
    except Exception as e:
        print(e)

async def main():
    if not os.path.exists("downloads"): os.mkdir("downloads")
    await bot.start()
    success, msg = await start_userbot_system()
    print(f"System Ready. Userbot Status: {msg}")
    await asyncio.Event().wait()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
EOF

echo "[+] Install Library..."
pip3 install -r requirements.txt

echo "[+] Membuat Script Start (Screen)..."
cat <<EOF > start.sh
#!/bin/bash
screen -S XayzStream python3 bot.py
echo "Bot berjalan di background screen 'XayzStream' dan di lokasi ./root/Xayz-stream"
EOF
chmod +x start.sh

echo ""
echo "=== SELESAI ==="
echo "Ketik perintah ini untuk menyalakan bot:"
echo "./start.sh"
echo ""
echo "Untuk melihat log bot, ketik:"
echo "screen -r XayzStream"
