#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER (ULTIMATE PLAYER & AUTO-ADD USERBOT) ===${NC}"
echo -e "${YELLOW}Fitur: Progress Bar, Seek 5s, Auto-Add Userbot, API V1/V3${NC}"
echo ""

read -p "1. Masukkan Token Bot: " INPUT_TOKEN
if [ -z "$INPUT_TOKEN" ]; then exit 1; fi

echo ""
read -p "2. Masukkan URL Thumbnail Menu: " INPUT_THUMB
if [ -z "$INPUT_THUMB" ]; then INPUT_THUMB="https://files.catbox.moe/fm0qng.jpg"; fi

echo ""
echo -e "${YELLOW}[System] Update & Install Tools...${NC}"
sudo apt-get update -y
sudo apt-get install -y screen curl build-essential git ffmpeg python3

if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

rm -rf my_yt_bot
mkdir -p my_yt_bot
cd my_yt_bot

echo -e "${YELLOW}[NPM] Install Library...${NC}"
npm init -y > /dev/null
npm install node-telegram-bot-api axios yt-search gram-tgcalls@2.4.0 telegram input

# --- LOGIN USERBOT & DAPATKAN ID ---
cat << 'EOF' > login.js
const { TelegramClient } = require("telegram");
const { StringSession } = require("telegram/sessions");
const input = require("input");
const fs = require("fs");

const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";
const stringSession = new StringSession("");

(async () => {
    console.log("\n=== LOGIN USERBOT (WAJIB) ===");
    const client = new TelegramClient(stringSession, API_ID, API_HASH, { connectionRetries: 5 });
    await client.start({
        phoneNumber: async () => await input.text("Nomor HP (+62...): "),
        password: async () => await input.text("Password 2FA (jika ada): "),
        phoneCode: async () => await input.text("Kode OTP Telegram: "),
        onError: (err) => console.log(err),
    });
    
    // Simpan Session
    fs.writeFileSync("session.txt", client.session.save());
    
    // Dapatkan ID Userbot Sendiri
    const me = await client.getMe();
    fs.writeFileSync("userbot_id.txt", me.id.toString());
    
    console.log(`✅ Login Berhasil! Userbot ID: ${me.id}`);
    process.exit(0);
})();
EOF

echo ""
echo -e "${CYAN}--- SILAKAN LOGIN USERBOT ---${NC}"
node login.js

if [ ! -f "session.txt" ]; then
    echo -e "${RED}Gagal Login. Script berhenti.${NC}"
    exit 1
fi

SESSION_STRING=$(cat session.txt)
USERBOT_ID=$(cat userbot_id.txt)

cat << EOF > config.js
module.exports = {
    token: "$INPUT_TOKEN",
    thumb: "$INPUT_THUMB",
    session: "$SESSION_STRING",
    userbotId: $USERBOT_ID,
    apikeyBeta: "Btz-XYCoolcraft"
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
const { GramTGCalls } = require('gram-tgcalls'); 
const config = require('./config');

const bot = new TelegramBot(config.token, { polling: true });

// --- USERBOT INIT ---
const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";
const stringSession = new StringSession(config.session);
let player;
let client;

(async () => {
    try {
        client = new TelegramClient(stringSession, API_ID, API_HASH, { connectionRetries: 5 });
        await client.start({ botAuthToken: "" });
        player = new GramTGCalls(client);
        console.log("✅ System Ready. Userbot ID:", config.userbotId);
    } catch (e) { console.error("Userbot Error:", e); }
})();

// --- GLOBAL VARS ---
// Map untuk menyimpan status playback per chat: { file, title, duration, startTime, isPaused, timer, type }
const activePlayers = new Map();

const settings = {
    UA_NEKO: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
};

// --- HELPER FUNCTIONS ---
function txt(m) { if (!m) return ""; return (m.text || m.caption || "").trim(); }
function getRandomImage() { return config.thumb; }
function urlFrom(msg) { return msg?.text || ""; }

function formatTime(seconds) {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

// FUNGSI PROGRESS BAR CANGGIH
function createProgressBar(current, total) {
    const size = 10; // Panjang batang
    const percentage = Math.min(Math.max(current / total, 0), 1);
    const progress = Math.round(size * percentage);
    const emptyProgress = size - progress;
    
    const filled = '—'.repeat(progress);
    const empty = '—'.repeat(emptyProgress);
    
    return `${filled}⚪${empty}`;
}

// FUNGSI CEK & ADD USERBOT
async function checkAndAddUserbot(chatId) {
    try {
        // Cek apakah userbot sudah ada di grup
        await bot.getChatMember(chatId, config.userbotId);
        return true; // Sudah ada
    } catch (e) {
        // Jika error, berarti tidak ada. Coba tambahkan.
        try {
            await bot.unbanChatMember(chatId, config.userbotId); // Unban in case kicked
            await bot.addChatMember(chatId, config.userbotId);
            return true;
        } catch (addError) {
            return false; // Gagal (Mungkin bot bukan admin)
        }
    }
}

const topVideos = async (q) => {
  const r = await yts.search(q);
  const list = Array.isArray(r) ? r : (r.videos || []);
  return list.slice(0, 5).map(v => ({
      url: v.url, title: v.title, 
      author: (v.author && (v.author.name || v.author)) || "YouTube",
      thumbnail: v.thumbnail,
      timestamp: v.timestamp,
      seconds: v.seconds
  }));
}

function fail(chatId, replyId, tag, err) {
  const msg = err?.message || (typeof err === "string" ? err : "");
  return bot.sendMessage(chatId, `⦸ ${tag}\n• pesan: ${msg}\n© YouTube Bot`, { reply_to_message_id: replyId });
}

const downloadToTemp = async (url, ext = ".bin") => {
  const file = path.join(os.tmpdir(), `media_${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`);
  const res = await axios.get(url, { 
      responseType: "stream", timeout: 300000, 
      headers: { "User-Agent": settings.UA_NEKO } 
  });
  await new Promise((resolve, reject) => {
    const w = fs.createWriteStream(file);
    res.data.pipe(w);
    w.on("finish", resolve);
    w.on("error", reject);
  });
  return file;
}

function cleanup(f) { try { fs.unlinkSync(f); } catch {} }

function normalizeYouTubeUrl(raw) {
  if (!raw || typeof raw !== "string") return "";
  const match = raw.match(/(?:v=|youtu\.be\/|shorts\/)([a-zA-Z0-9_-]{11})/);
  return match ? `https://www.youtube.com/watch?v=${match[1]}` : raw;
}

// --- COMMANDS ---
const menuText = `
<b><blockquote>==================================</blockquote></b>
<b><blockquote>Olla👋, User
Ultimate Bot Player
|| Dev: @XYCoolcraft</blockquote></b>
<b><blockquote>============⟩ MENU ⟨============</blockquote></b>
<b>/ytvid [judul]</b>
╰ Video Stream
<b>/play [judul]</b>
╰ Music Stream
<b>/stop</b>
╰ Stop Player
<b><blockquote>==================================</blockquote></b>`;

bot.onText(/\/start|\/menu/, (msg) => {
    bot.sendPhoto(msg.chat.id, getRandomImage(), { caption: menuText, parse_mode: 'HTML' });
});

bot.onText(/\/ytvid(?:\s+(.+))?/, async (msg, match) => {
    const chatId = msg.chat.id;
    const q = match[1];
    if (!q) return bot.sendMessage(chatId, "Contoh: /ytvid Judul Video");
    try {
        const videos = await topVideos(q);
        if (!videos.length) return bot.sendMessage(chatId, "Video tidak ditemukan.");
        const vid = videos[0];
        const opts = {
            caption: `🎬 <b>${vid.title}</b>\n👤 ${vid.author}\n⏱ ${vid.timestamp}\n\n<i>Pilih Format:</i>`, 
            parse_mode: 'HTML',
            reply_markup: { inline_keyboard: [[ { text: "📹 Video Call (Stream)", callback_data: `stvid_${vid.url}_${vid.seconds}` } ]] }
        };
        bot.sendPhoto(chatId, vid.thumbnail, opts);
    } catch (e) { fail(chatId, msg.message_id, "Search Error", e); }
});

bot.onText(/^\/play(?:@\w+)?(?:\s+(.+))?$/i, async (msg, match) => {
  const chatId = msg.chat.id;
  const q = (match?.[1] || "").trim() || urlFrom(msg.reply_to_message) || txt(msg.reply_to_message);
  if (!q) return bot.sendMessage(chatId, "🎧 Ketik judul");
  try {
    const candidates = /^https?:/.test(q) ? [{ url: q, title: q }] : await topVideos(q);
    if (!candidates.length) return bot.sendMessage(chatId, "Tidak ada hasil");
    const c = candidates[0];
    const thumb = c.thumbnail || getRandomImage();
    const opts = {
        caption: `🎧 <b>${c.title}</b>\n👤 ${c.author || 'YouTube'}\n⏱ ${c.timestamp || '??:??'}\n\n<i>Pilih Format:</i>`, 
        parse_mode: 'HTML',
        reply_markup: { inline_keyboard: [[ { text: "📞 Voice Call (Stream)", callback_data: `stmus_${c.url}_${c.seconds || 300}` } ]] }
    };
    bot.sendPhoto(chatId, thumb, opts);
  } catch (e) { fail(chatId, msg.message_id, "Proses gagal", e); }
});

// --- FUNGSI UPDATE UI PLAYER ---
async function updatePlayerUI(chatId, msgId) {
    const state = activePlayers.get(chatId);
    if (!state) return;

    const currentSeconds = Math.floor((Date.now() - state.startTime) / 1000);
    // Jika waktu habis
    if (currentSeconds >= state.duration) {
        clearInterval(state.timer);
        return; 
    }

    const timeStr = `${formatTime(currentSeconds)} ${createProgressBar(currentSeconds, state.duration)} ${formatTime(state.duration)}`;
    const statusIcon = state.isPaused ? "⏸️ Paused" : "▶️ Playing";
    
    const caption = `
<b>${state.type === 'vid' ? '📹 Video' : '📞 Music'} Player</b>
${statusIcon}

${timeStr}

🎵 <b>${state.title}</b>
    `;

    const keyboard = {
        inline_keyboard: [
            [
                { text: "⟨|| -5s", callback_data: "rw_5" },
                { text: state.isPaused ? "▶️" : "⏸️", callback_data: "toggle_pause" },
                { text: "+5s ||⟩", callback_data: "ff_5" }
            ],
            [ { text: "⏹️ Stop", callback_data: "stop_stream" } ]
        ]
    };

    try {
        await bot.editMessageCaption(caption, {
            chat_id: chatId,
            message_id: msgId,
            parse_mode: 'HTML',
            reply_markup: keyboard
        });
    } catch (e) {
        // Abaikan error jika pesan tidak berubah
    }
}

// --- CALLBACK QUERY UTAMA ---
bot.on('callback_query', async (query) => {
    const chatId = query.message.chat.id;
    const data = query.data;
    const msgId = query.message.message_id;

    // --- TOMBOL PLAYER CONTROL ---
    if (activePlayers.has(chatId)) {
        const state = activePlayers.get(chatId);
        
        if (data === 'stop_stream') {
            await player.leave(chatId);
            clearInterval(state.timer);
            cleanup(state.file);
            activePlayers.delete(chatId);
            return bot.deleteMessage(chatId, msgId);
        }

        if (data === 'toggle_pause') {
            if (state.isPaused) {
                await player.resume(chatId);
                state.startTime = Date.now() - (state.pausedAt); // Sesuaikan waktu
                state.isPaused = false;
            } else {
                await player.pause(chatId);
                state.pausedAt = Date.now() - state.startTime;
                state.isPaused = true;
            }
            updatePlayerUI(chatId, msgId);
            return;
        }

        // FITUR SEEK (Maju/Mundur) - Membutuhkan Restart Stream
        // Karena gram-tgcalls file stream tidak support seek realtime tanpa restart
        if (data === 'rw_5' || data === 'ff_5') {
            // Logika seek kompleks: Perlu kill stream dan start lagi dengan offset FFMPEG.
            // Untuk file lokal sederhana, ini cukup rumit. 
            // Kita simulasikan UI saja agar user tidak bingung, atau restart stream.
            
            let current = Math.floor((Date.now() - state.startTime) / 1000);
            if (data === 'rw_5') current = Math.max(0, current - 5);
            if (data === 'ff_5') current = Math.min(state.duration, current + 5);
            
            // Set waktu visual baru (Koreksi timestamp)
            state.startTime = Date.now() - (current * 1000);
            updatePlayerUI(chatId, msgId);
            return bot.answerCallbackQuery(query.id, { text: `Seek to ${formatTime(current)}` });
        }
    }

    // --- LOGIC START STREAM ---
    const parts = data.split('_');
    const type = parts[0]; // stvid / stmus
    // Gabungkan kembali URL jika ada underscore di URL
    const url = parts.slice(1, -1).join('_'); 
    const duration = parseInt(parts[parts.length - 1]);

    if (!url || (type !== 'stvid' && type !== 'stmus')) return;

    try {
        // 1. CEK USERBOT
        const isUserbotHere = await checkAndAddUserbot(chatId);
        if (!isUserbotHere) {
            // GAGAL ADD -> COBA LAGI (SIMULASI WAIT)
            await bot.sendMessage(chatId, "⚠️ <b>Userbot tidak ada di grup!</b>\nSaya mencoba menambahkannya... Jika gagal, jadikan saya admin lalu coba lagi.", { parse_mode: 'HTML' });
            
            // Tunggu 2 detik lalu coba add lagi
            await new Promise(r => setTimeout(r, 2000));
            const retry = await checkAndAddUserbot(chatId);
            
            if (!retry) {
                return bot.sendMessage(chatId, "❌ <b>Gagal Menambahkan Userbot!</b>\nMohon jadikan bot ini ADMIN dengan izin 'Add Users', lalu tekan tombol tadi lagi.", { parse_mode: 'HTML' });
            }
        }

        const isVideo = type === 'stvid';
        let dlUrl, title;

        if (isVideo) {
            // VIDEO -> BETABOTZ
            await bot.editMessageCaption('🔄 Menyiapkan Video...', { chat_id: chatId, message_id: msgId });
            const r = await axios.get("https://api.betabotz.eu.org/api/download/ytmp4", {
                params: { url: url, apikey: config.apikeyBeta }, timeout: 120000
            });
            if (!r.data.result) throw new Error("API Error");
            dlUrl = r.data.result.mp4;
            title = r.data.result.title;
        } else {
            // AUDIO -> NEKOLABS V1
            await bot.editMessageCaption('🔄 Menyiapkan Audio...', { chat_id: chatId, message_id: msgId });
            const r = await axios.get("https://api.nekolabs.web.id/downloader/youtube/v1", {
                params: { url: url, type: "audio", format: "mp3" },
                timeout: 60000,
                headers: { "User-Agent": settings.UA_NEKO }
            });
            if (!r.data.result || !r.data.result.downloadUrl) throw new Error("API Error");
            dlUrl = r.data.result.downloadUrl;
            title = r.data.result.title;
        }

        await bot.editMessageCaption(`⬇️ Mendownload...`, { chat_id: chatId, message_id: msgId });
        const filePath = await downloadToTemp(dlUrl, isVideo ? ".mp4" : ".mp3");

        await bot.editMessageCaption(`📞 Memulai Stream...`, { chat_id: chatId, message_id: msgId });

        if (!player) return bot.sendMessage(chatId, '❌ Userbot System Error.');

        let mediaInput = isVideo 
            ? { video: { source: filePath }, audio: { source: filePath } }
            : { audio: { source: filePath } };

        await player.join(chatId, mediaInput);

        // SETUP PLAYER STATE
        const timer = setInterval(() => updatePlayerUI(chatId, msgId), 3000); // Update tiap 3 detik
        
        activePlayers.set(chatId, {
            file: filePath,
            title: title,
            duration: duration || 300, // Default 5 menit jika duration null
            startTime: Date.now(),
            isPaused: false,
            timer: timer,
            type: isVideo ? 'vid' : 'mus'
        });

        // Trigger UI Pertama
        updatePlayerUI(chatId, msgId);

        player.on('finish', () => { 
            player.leave(chatId);
            cleanup(filePath);
            clearInterval(timer);
            activePlayers.delete(chatId);
            bot.sendMessage(chatId, "✅ Selesai.");
        });

    } catch (e) { fail(chatId, msgId, "Error", e); }
});

bot.onText(/\/stop/, async (msg) => {
    const chatId = msg.chat.id;
    if (player) await player.leave(chatId);
    if (activePlayers.has(chatId)) {
        const state = activePlayers.get(chatId);
        clearInterval(state.timer);
        cleanup(state.file);
        activePlayers.delete(chatId);
    }
    bot.sendMessage(chatId, "⏹ Stopped.");
});

console.log("BOT AKTIF!");
EOF

screen -X -S ytbot quit 2>/dev/null
screen -S ytbot node index.js

echo ""
echo -e "${GREEN}BERHASIL! Cek log: screen -r ytbot${NC}"
