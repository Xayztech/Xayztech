#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER BOT (PUBLIC ACCESS / NO LIMIT) ===${NC}"
echo ""

read -p "Masukkan Token Bot: " INPUT_TOKEN
if [ -z "$INPUT_TOKEN" ]; then
  exit 1
fi

echo ""
read -p "Masukkan URL Thumbnail: " INPUT_THUMB
if [ -z "$INPUT_THUMB" ]; then
  INPUT_THUMB="https://files.catbox.moe/fm0qng.jpg"
fi

echo ""
read -p "Masukkan Username Owner (tanpa @): " INPUT_OWNER
if [ -z "$INPUT_OWNER" ]; then
  INPUT_OWNER="XYCoolcraft"
fi

sudo apt-get update -y
sudo apt-get install -y screen curl build-essential git ffmpeg python3

if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

rm -rf my_yt_bot
mkdir -p my_yt_bot
CURRENT_DIR=$(pwd)
BOT_DIR="$CURRENT_DIR/my_yt_bot"
cd "$BOT_DIR"

cat << 'EOF' > package.json
{
  "name": "yt-bot-public",
  "version": "9.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "node-telegram-bot-api": "latest",
    "axios": "latest",
    "yt-search": "latest",
    "gram-tgcalls": "latest",
    "telegram": "latest",
    "input": "latest"
  }
}
EOF

cat << EOF > config.js
module.exports = {
    token: "$INPUT_TOKEN",
    thumb: "$INPUT_THUMB",
    ownerUrl: "https://t.me/$INPUT_OWNER"
};
EOF

cat << 'EOF' > index.js
const TelegramBot = require('node-telegram-bot-api');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const os = require('os');
const yts = require('yt-search');
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { GramTGCalls, AudioVideoContent, AudioContent } = require('gram-tgcalls');
const config = require('./config');

const bot = new TelegramBot(config.token, { polling: true });

const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";
const stringSession = new StringSession("");
let player;

(async () => {
    const client = new TelegramClient(stringSession, API_ID, API_HASH, { connectionRetries: 5 });
    await client.start({ botAuthToken: config.token });
    player = new GramTGCalls(client);
    console.log("System Ready");
})();

const settings = { 
    OWNER_URL: config.ownerUrl,
    USER_AGENT: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
};

function txt(m) {
  if (!m) return ""
  return (m.text || m.caption || "").trim()
}

function parseSecs(s) {
  if (typeof s === "number") return s
  if (!s || typeof s !== "string") return 0
  return s.split(":").map(n => parseInt(n, 10)).reduce((a, v) => a * 60 + v, 0)
}

function getRandomImage() { return config.thumb; }
function shouldIgnoreMessage(msg) { return false; }
function urlFrom(msg) { return msg?.text || ""; }

const topVideos = async (q) => {
  const r = await yts.search(q)
  const list = Array.isArray(r) ? r : (r.videos || [])
  return list
    .filter(v => {
      const sec = typeof v.seconds === "number" ? v.seconds : parseSecs(v.timestamp || v.duration)
      return !v.live && sec > 0 && sec <= 1200
    })
    .slice(0, 5)
    .map(v => ({
      url: v.url, title: v.title, author: (v.author && (v.author.name || v.author)) || "YouTube"
    }))
}

function fail(chatId, replyId, tag, err) {
  const msg = err?.message || (typeof err === "string" ? err : "")
  return bot.sendMessage(chatId, `⦸ ${tag}\n• pesan: ${msg}\n© ᴏᴛᴀx (⸙)`, { reply_to_message_id: replyId })
}

const downloadToTemp = async (url, ext = ".bin") => {
  const file = path.join(os.tmpdir(), `xayz_${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`)
  const res = await axios.get(url, { 
      responseType: "stream", 
      timeout: 1200000, 
      headers: { "User-Agent": settings.USER_AGENT } 
  })
  await new Promise((resolve, reject) => {
    const w = fs.createWriteStream(file)
    res.data.pipe(w)
    w.on("finish", resolve)
    w.on("error", reject)
  })
  return file
}

function cleanup(f) { try { fs.unlinkSync(f) } catch {} }

function normalizeYouTubeUrl(raw) {
  if (!raw || typeof raw !== "string") return ""
  const match = raw.match(/(?:v=|youtu\.be\/|shorts\/)([a-zA-Z0-9_-]{11})/)
  return match ? `https://www.youtube.com/watch?v=${match[1]}` : raw
}

const menuText = `
<b><blockquote>==================================</blockquote></b>

<b><blockquote>Olla👋, {username}
私はTelegram用のYouTube MusicとYouTube Video Streamingボットです。作成・開発者：@XYCoolcraft</blockquote></b>

<b><blockquote>============⟩ MENU ⟨============</blockquote></b>
<b>/ytvid [judul]</b>
╰ Video Downloader & Stream
<b>/ytmusic [judul]</b>
╰ Music Downloader & Stream
<b>/stop</b>
╰ Stop Stream

<b><blockquote>==================================</blockquote></b>`;

bot.onText(/\/start|\/menu/, (msg) => {
    bot.sendPhoto(msg.chat.id, getRandomImage(), {
        caption: menuText,
        parse_mode: 'HTML'
    });
});

bot.onText(/\/ytvid(?:\s+(.+))?/, async (msg, match) => {
    const chatId = msg.chat.id;
    const q = match[1];
    
    if (!q) return bot.sendMessage(chatId, "Contoh: /ytvid Judul Video");

    try {
        await bot.sendChatAction(chatId, "typing");
        const videos = await topVideos(q);
        if (!videos.length) return bot.sendMessage(chatId, "Video tidak ditemukan.");

        const vid = videos[0];
        const ytUrl = normalizeYouTubeUrl(vid.url);
        
        const opts = {
            caption: `🎬 <b>${vid.title}</b>\n👤 ${vid.author}\n\nPilih Format:`,
            parse_mode: 'HTML',
            reply_markup: {
                inline_keyboard: [
                    [ { text: "📥 Download Video", callback_data: `dlvid_${ytUrl}` } ],
                    [ { text: "📹 Stream Video", callback_data: `stvid_${ytUrl}` } ]
                ]
            }
        };
        bot.sendPhoto(chatId, getRandomImage(), opts);
    } catch (e) {
        fail(chatId, msg.message_id, "Search Gagal", e);
    }
});

bot.onText(/^\/ytmusic(?:@\w+)?(?:\s+(.+))?$/i, async (msg, match) => {
  const chatId = msg.chat.id;
  const q = (match?.[1] || "").trim() || urlFrom(msg.reply_to_message) || txt(msg.reply_to_message);

  if (!q) return bot.sendMessage(chatId, "🎧 Ketik judul atau reply judul/link");

  try {
    await bot.sendChatAction(chatId, "typing");
    const candidates = /^https?:/.test(q) ? [{ url: q, title: q }] : await topVideos(q);
    if (!candidates.length) return bot.sendMessage(chatId, "Tidak ada hasil");

    const c = candidates[0];
    const ytUrl = normalizeYouTubeUrl(c.url);

    const opts = {
        caption: `🎧 <b>${c.title}</b>\n👤 ${c.author || 'XYCoolcraft'}\n\nPilih Format:`,
        parse_mode: 'HTML',
        reply_markup: {
            inline_keyboard: [
                [ { text: "📥 Download MP3", callback_data: `dlmus_${ytUrl}` } ],
                [ { text: "📞 Stream Voice", callback_data: `stmus_${ytUrl}` } ]
            ]
        }
    };
    bot.sendPhoto(chatId, getRandomImage(), opts);

  } catch (e) {
    fail(chatId, msg.message_id, "Proses gagal", e);
  }
});

bot.on('callback_query', async (query) => {
    const chatId = query.message.chat.id;
    const data = query.data;
    const msgId = query.message.message_id;

    if (data === 'stop_stream') {
        await player.leave(chatId);
        return bot.sendMessage(chatId, '⏹ Stopped.');
    }

    const type = data.substring(0, 6);
    const url = data.substring(6);

    if (!url) return;

    try {
        if (type === 'dlvid_' || type === 'dlmus_') {
            await bot.editMessageCaption('🔄 Please Wait for process...', { chat_id: chatId, message_id: msgId });
            
            const isVideo = type === 'dlvid_';
            const apiUrl = "https://api.nekolabs.web.id/downloader/youtube/v1";
            
            const params = new URLSearchParams({
                url: url,
                format: isVideo ? "mp4" : "mp3",
                quality: isVideo ? "720" : "128",
                type: isVideo ? "video" : "audio"
            });

            const r = await axios.get(apiUrl + "?" + params.toString(), {
                timeout: 1200000,
                headers: { "User-Agent": settings.USER_AGENT },
                validateStatus: () => true
            });

            const body = r.data;
            if (body.success && body.result && body.result.downloadUrl) {
                const res = body.result;
                const file = await downloadToTemp(res.downloadUrl, isVideo ? ".mp4" : ".mp3");

                if (isVideo) {
                    await bot.sendVideo(chatId, file, { caption: res.title });
                } else {
                    await bot.sendAudio(chatId, file, { caption: res.title, title: res.title });
                }
                cleanup(file);
                bot.deleteMessage(chatId, msgId);
            } else {
                bot.sendMessage(chatId, '❌ Gagal mengambil link download (API Error).');
            }
        }

        if (type === 'stvid_' || type === 'stmus_') {
            await bot.editMessageCaption('🔄 Menghubungkan ke Voice Chat...', { chat_id: chatId, message_id: msgId });
            
            const isVideo = type === 'stvid_';
            const apiUrl = "https://api.nekolabs.web.id/downloader/youtube/v1";
            
            const params = new URLSearchParams({
                url: url,
                format: isVideo ? "mp4" : "mp3",
                quality: isVideo ? "720" : "128",
                type: isVideo ? "video" : "audio"
            });

            const r = await axios.get(apiUrl + "?" + params.toString(), {
                timeout: 1200000,
                headers: { "User-Agent": settings.USER_AGENT },
                validateStatus: () => true
            });

            if (r.data.success && r.data.result.downloadUrl) {
                const streamLink = r.data.result.downloadUrl;
                
                const media = isVideo 
                    ? new AudioVideoContent({ video: { url: streamLink }, audio: { url: streamLink } })
                    : new AudioContent({ url: streamLink });
                
                await player.join(chatId, media);
                
                await bot.editMessageCaption(`▶️ <b>Streaming...</b>\n🎵 ${r.data.result.title}`, { 
                    chat_id: chatId, 
                    message_id: msgId,
                    parse_mode: 'HTML',
                    reply_markup: { inline_keyboard: [[{ text: "⏹ Stop", callback_data: "stop_stream" }]] }
                });

                player.on('finish', () => { player.leave(chatId); });
            }
        }

    } catch (e) {
        fail(chatId, msgId, "Callback Error", e);
    }
});

bot.onText(/\/stop/, async (msg) => {
    await player.leave(msg.chat.id);
    bot.sendMessage(msg.chat.id, "⏹ Player stopped.");
});

console.log("BOT AKTIF...");
EOF

npm cache clean --force
npm install

screen -X -S ytbot quit 2>/dev/null
screen -S ytbot node index.js

echo ""
echo -e "${GREEN}BERHASIL! Cek log: screen -r ytbot${NC}"
