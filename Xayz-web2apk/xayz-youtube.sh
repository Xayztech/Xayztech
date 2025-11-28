import os
import asyncio
from pyrogram import Client, filters
from pyrogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from pytgcalls import PyTgCalls
from pytgcalls.types import MediaStream, AudioQuality, VideoQuality
from yt_dlp import YoutubeDL

# ================= K O N F I G U R A S I =================
# ISI DENGAN DATA KAMU LAGI YA (WAJIB!)
API_ID = 33422941             # Ganti Angka Ini
API_HASH = "72b12f6f5d00b852f0b0aadeffa99f10"    # Ganti String Ini
BOT_TOKEN = "8034551680:AAFwKiWPI4UOzfUsgcnh4hWZ7zWksnJZXGg"   # Token BotFather
# =========================================================

app = Client("video_music_session", api_id=API_ID, api_hash=API_HASH, bot_token=BOT_TOKEN)
call_py = PyTgCalls(app)

# --- FUNGSI DOWNLOADER (Video & Audio Terpisah) ---

def download_video(url):
    ydl_opts = {
        'format': 'best[ext=mp4]', # Format Video MP4
        'outtmpl': 'downloads/%(id)s_video.%(ext)s',
        'quiet': True,
        'noplaylist': True
    }
    with YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        filename = ydl.prepare_filename(info)
        if not os.path.exists(filename):
            ydl.download([url])
        return filename, info['title'], info['thumbnail'], info['duration_string']

def download_audio(url):
    ydl_opts = {
        'format': 'bestaudio', # Format Audio Saja (Ringan)
        'outtmpl': 'downloads/%(id)s_audio.%(ext)s',
        'quiet': True,
        'noplaylist': True
    }
    with YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        filename = ydl.prepare_filename(info)
        if not os.path.exists(filename):
            ydl.download([url])
        return filename, info['title'], info['thumbnail'], info['duration_string']

# --- MENU START ---
@app.on_message(filters.command("start"))
async def start(client, message):
    user = message.from_user.first_name
    await message.reply_photo(
        photo="https://cdn-icons-png.flaticon.com/512/1384/1384060.png",
        caption=f"""
<b><blockquote>==================================</blockquote></b>
<b><blockquote>Olla👋, {user}</blockquote></b>
<b><blockquote>Bot Video & Musik Player</blockquote></b>
<b><blockquote>==================================</blockquote></b>

<b>==⟩ MENU ⟨==</b>

/ytvid [judul] - Video Call (Nonton Bareng)
/ytmusic [judul] - Voice Call (Dengar Musik)
/stop - Matikan Player
/pause - Jeda
/resume - Lanjut
"""
    )

# --- FITUR 1: VIDEO CALL (/ytvid) ---
@app.on_message(filters.command(["ytvid", "playvid"]) & filters.group)
async def stream_video(client, message):
    query = " ".join(message.command[1:])
    if not query:
        return await message.reply("❌ Judulnya mana?\nContoh: <code>/ytvid Tulus Monokrom</code>")
    
    msg = await message.reply("🔍 <b>Mencari Video...</b>")

    try:
        # Cari URL
        proc = await asyncio.create_subprocess_shell(
            f"yt-dlp --print '%(id)s' --get-title 'ytsearch1:{query}'",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()
        result = stdout.decode().strip().split('\n')
        
        if not result or result[0] == '':
            return await msg.edit("❌ Video tidak ditemukan.")

        video_id = result[-1]
        video_url = f"https://www.youtube.com/watch?v={video_id}"

        await msg.edit("📥 <b>Mendownload Video (MP4)...</b>\n<i>Mohon tunggu sebentar...</i>")
        
        # Download mode Video
        file_path, title, thumb, durasi = download_video(video_url)

        await msg.edit(f"🎥 <b>Memulai Video Stream...</b>")
        
        # Play Video + Audio
        await call_py.play(
            message.chat.id,
            MediaStream(
                file_path,
                audio_parameters=AudioQuality.HIGH,
                video_parameters=VideoQuality.SD_480p, # Video Nyala
            )
        )
        
        # UI Player Video
        await message.reply_photo(
            photo=thumb,
            caption=f"🎥 <b>Sedang Video Call!</b>\n\n💿 <b>Judul:</b> {title}\n⏱ <b>Durasi:</b> {durasi}\n👤 <b>Request:</b> {message.from_user.mention}",
            reply_markup=InlineKeyboardMarkup([
                [InlineKeyboardButton("⏸ Pause", callback_data="pause"), InlineKeyboardButton("▶️ Resume", callback_data="resume")],
                [InlineKeyboardButton("⏹ Stop Stream", callback_data="stop")]
            ])
        )
        await msg.delete()

    except Exception as e:
        await msg.edit(f"❌ Error: {e}")

# --- FITUR 2: MUSIC ONLY (/ytmusic) ---
@app.on_message(filters.command(["ytmusic", "playmusic"]) & filters.group)
async def stream_music(client, message):
    query = " ".join(message.command[1:])
    if not query:
        return await message.reply("❌ Judulnya mana?\nContoh: <code>/ytmusic Tulus Monokrom</code>")
    
    msg = await message.reply("🔍 <b>Mencari Musik...</b>")

    try:
        proc = await asyncio.create_subprocess_shell(
            f"yt-dlp --print '%(id)s' --get-title 'ytsearch1:{query}'",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()
        result = stdout.decode().strip().split('\n')
        
        if not result or result[0] == '':
            return await msg.edit("❌ Musik tidak ditemukan.")

        video_id = result[-1]
        video_url = f"https://www.youtube.com/watch?v={video_id}"

        await msg.edit("📥 <b>Mendownload Audio (MP3)...</b>\n<i>Ini lebih cepat dari video.</i>")
        
        # Download mode Audio Only
        file_path, title, thumb, durasi = download_audio(video_url)

        await msg.edit(f"🎵 <b>Memutar Musik...</b>")
        
        # Play Audio Only (Video Parameters dimatikan/default audio)
        await call_py.play(
            message.chat.id,
            MediaStream(
                file_path,
                audio_parameters=AudioQuality.HIGH,
                video_flags=MediaStream.Flags.IGNORE # Matikan Video
            )
        )
        
        # UI Player Musik
        await message.reply_photo(
            photo=thumb,
            caption=f"🎵 <b>Sedang Memutar Musik!</b>\n\n💿 <b>Judul:</b> {title}\n⏱ <b>Durasi:</b> {durasi}\n👤 <b>Request:</b> {message.from_user.mention}",
            reply_markup=InlineKeyboardMarkup([
                [InlineKeyboardButton("⏸ Pause", callback_data="pause"), InlineKeyboardButton("▶️ Resume", callback_data="resume")],
                [InlineKeyboardButton("⏹ Stop Musik", callback_data="stop")]
            ])
        )
        await msg.delete()

    except Exception as e:
        await msg.edit(f"❌ Error: {e}")

# --- CALLBACK CONTROL (SAMA UNTUK KEDUANYA) ---
@app.on_callback_query()
async def controls(client, cb):
    chat_id = cb.message.chat.id
    if cb.data == "stop":
        await call_py.leave_call(chat_id)
        await cb.message.delete()
    elif cb.data == "pause":
        await call_py.pause_stream(chat_id)
        await cb.answer("⏸ Jeda")
    elif cb.data == "resume":
        await call_py.resume_stream(chat_id)
        await cb.answer("▶️ Lanjut")

# --- AUTO START ---
async def main():
    print("Bot Music & Video Siap 24 Jam!")
    await call_py.start()
    await asyncio.Event().wait()

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
