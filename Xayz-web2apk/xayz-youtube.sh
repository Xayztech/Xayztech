#!/bin/bash

# Konfigurasi Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER BOT || CREATED AND DEVELOPER BY: @XYCoolcraft ===${NC}"
echo -e "${YELLOW}Fixing: TypeError addEventHandler${NC}"
echo ""

# 1. INPUT DATA
read -p "Masukkan Token Bot: " INPUT_TOKEN
if [ -z "$INPUT_TOKEN" ]; then
  echo -e "${RED}Token wajib diisi!${NC}"
  exit 1
fi

echo ""
read -p "Masukkan URL Thumbnail: " INPUT_THUMB
if [ -z "$INPUT_THUMB" ]; then
  INPUT_THUMB="https://files.catbox.moe/fm0qng.jpg"
fi

# 2. SYSTEM UPDATE
echo ""
echo -e "${YELLOW}[System] Update & Install FFmpeg...${NC}"
sudo apt-get update -y
sudo apt-get install -y screen curl build-essential git ffmpeg python3

# 3. NODEJS CHECK
if ! command -v node &> /dev/null
then
    echo -e "${YELLOW}[NodeJS] Menginstall Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 4. SETUP FOLDER (ABSOLUTE PATH)
rm -rf my_yt_bot
mkdir -p my_yt_bot
CURRENT_DIR=$(pwd)
BOT_DIR="$CURRENT_DIR/my_yt_bot"

echo -e "${GREEN}[Folder] $BOT_DIR${NC}"
cd "$BOT_DIR"

# 5. BUAT PACKAGE.JSON (Menambahkan 'telegram' dan 'input')
echo ""
echo -e "${YELLOW}[File] Membuat package.json...${NC}"
cat << 'EOF' > package.json
{
  "name": "Xayz Stream",
  "version": "2.0.0",
  "description": "Created And Developer By: @XYCoolcraft",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "telegraf": "latest",
    "yt-search": "latest",
    "@distube/ytdl-core": "latest",
    "gram-tgcalls": "latest",
    "telegram": "latest",
    "input": "latest"
  }
}
EOF

# 6. BUAT CONFIG.JS
echo -e "${YELLOW}[File] Membuat config.js...${NC}"
cat << EOF > config.js
module.exports = {
    botToken: "$INPUT_TOKEN",
    thumbUrl: "$INPUT_THUMB"
};
EOF

# 7. BUAT INDEX.JS (REVISI TOTAL: DUAL CLIENT)
# Kita menggunakan API ID public Telegram Desktop agar user tidak perlu input manual
echo -e "${YELLOW}[File] Membuat index.js...${NC}"
cat << 'EOF' > index.js
const { Telegraf, Markup } = require('telegraf');
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { GramTGCalls, AudioVideoContent, AudioContent } = require('gram-tgcalls');
const yts = require('yt-search');
const ytdl = require('@distube/ytdl-core');
const config = require('./config');

// --- KONFIGURASI MTPROTO (Public ID Telegram Desktop) ---
const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";

const stringSession = new StringSession(""); // Kosong = Login via Token

(async () => {
    console.log("🔄 Menghubungkan ke Telegram...");

    // 1. Inisialisasi Bot API (Untuk Chat/Command)
    const bot = new Telegraf(config.botToken);

    // 2. Inisialisasi MTProto Client (Untuk Telepon/Streaming)
    const client = new TelegramClient(stringSession, API_ID, API_HASH, {
        connectionRetries: 5,
    });

    // Login MTProto menggunakan Bot Token
    await client.start({
        botAuthToken: config.botToken,
    });
    console.log("✅ MTProto Client Terhubung!");

    // 3. Hubungkan Gram-TgCalls ke MTProto Client
    const player = new GramTGCalls(client);
    const playerState = {};

    // --- LOGIC BOT ---

    const createMenuText = (name) => `
<b><blockquote>==================================</blockquote></b>

<b><blockquote>Olla👋, ${name}
このボットは、YouTube Music と YouTube Video Stream のボットです。
|| 作成および開発者: @XYCoolcraft</blockquote></b>

<b><blockquote>============⟩ MENU ⟨============</blockquote></b>
<b>/ytvid [judul]</b>
╰ Video Stream
<b>/ytmusic [judul]</b>
╰ Music Stream
<b>/stop</b>
╰ Stop Player

<b><blockquote>==================================</blockquote></b>
    `;

    bot.start((ctx) => {
        const name = ctx.from.first_name || 'User';
        ctx.replyWithPhoto(config.thumbUrl, { caption: createMenuText(name), parse_mode: 'HTML' });
    });

    bot.command('menu', (ctx) => {
        const name = ctx.from.first_name || 'User';
        ctx.replyWithPhoto(config.thumbUrl, { caption: createMenuText(name), parse_mode: 'HTML' });
    });

    async function searchYouTube(query) {
        const r = await yts(query);
        return r.videos.length > 0 ? r.videos[0] : null;
    }

    bot.command('ytvid', async (ctx) => {
        const query = ctx.message.text.split(' ').slice(1).join(' ');
        if (!query) return ctx.reply('Contoh: /ytvid Judul');
        
        const video = await searchYouTube(query);
        if (!video) return ctx.reply('Video tidak ditemukan.');

        await ctx.replyWithPhoto(video.thumbnail, {
            caption: `🎬 <b>${video.title}</b>\n⏱ ${video.timestamp}\n👤 ${video.author.name}`,
            parse_mode: 'HTML',
            ...Markup.inlineKeyboard([
                [Markup.button.callback('📂 Kirim Video', `dl_vid_${video.videoId}`)],
                [Markup.button.callback('📹 Video Call', `stream_vid_${video.videoId}`)]
            ])
        });
    });

    bot.command('ytmusic', async (ctx) => {
        const query = ctx.message.text.split(' ').slice(1).join(' ');
        if (!query) return ctx.reply('Contoh: /ytmusic Judul');
        
        const video = await searchYouTube(query);
        if (!video) return ctx.reply('Musik tidak ditemukan.');

        await ctx.replyWithPhoto(video.thumbnail, {
            caption: `🎵 <b>${video.title}</b>\n⏱ ${video.timestamp}\n👤 ${video.author.name}`,
            parse_mode: 'HTML',
            ...Markup.inlineKeyboard([
                [Markup.button.callback('📂 Kirim Audio', `dl_mus_${video.videoId}`)],
                [Markup.button.callback('📞 Voice Call', `stream_mus_${video.videoId}`)]
            ])
        });
    });

    bot.action(/stream_(vid|mus)_(.+)/, async (ctx) => {
        const type = ctx.match[1];
        const id = ctx.match[2];
        const chatId = ctx.chat.id;
        
        await ctx.answerCbQuery('Menghubungkan ke server...');

        try {
            const videoUrl = `https://www.youtube.com/watch?v=${id}`;
            const info = await ytdl.getInfo(videoUrl);
            const format = type === 'vid' 
                ? ytdl.chooseFormat(info.formats, { quality: '18' }) 
                : ytdl.chooseFormat(info.formats, { quality: 'highestaudio' });
            
            if (!format || !format.url) throw new Error('Stream URL tidak ditemukan.');
            
            let media = type === 'vid' 
                ? new AudioVideoContent({ video: { url: format.url }, audio: { url: format.url } })
                : new AudioContent({ url: format.url });
                
            // Gunakan Client MTProto untuk join call
            await player.join(chatId, media);
            
            playerState[chatId] = { 
                isPlaying: true, 
                currentTime: 0, 
                duration: parseInt(info.videoDetails.lengthSeconds), 
                title: info.videoDetails.title, 
                type: type 
            };
            
            await sendPlayerInterface(ctx, chatId);
            
            player.on('finish', () => { 
                player.leave(chatId); 
                delete playerState[chatId]; 
            });

        } catch (e) {
            console.error(e);
            ctx.reply(`❌ Gagal: ${e.message}\n(Pastikan Bot sudah jadi ADMIN di grup ini!)`);
        }
    });

    bot.action(/dl_(vid|mus)_(.+)/, (ctx) => ctx.answerCbQuery('Fitur Download dinonaktifkan di demo.'));

    async function sendPlayerInterface(ctx, chatId, isEdit = false) {
        const state = playerState[chatId];
        if (!state) return;
        const progress = state.duration > 0 ? Math.floor((state.currentTime / state.duration) * 10) : 0;
        const bar = '▬'.repeat(progress) + '🔘' + '▬'.repeat(10 - progress);
        const m = Math.floor(state.currentTime / 60);
        const s = state.currentTime % 60;
        
        const caption = `<b>${state.type === 'vid'?'📹 Video':'📞 Music'} Player</b>\n${state.isPlaying?'▶️':'⏸'} ${bar} [${m}:${s<10?'0':''}${s}]\n🎵 ${state.title}`;
        const kb = Markup.inlineKeyboard([
            [Markup.button.callback('⏪ -10s', 'seek_back'), Markup.button.callback(state.isPlaying?'⏸':'▶️', 'toggle_play'), Markup.button.callback('⏩ +10s', 'seek_fwd')],
            [Markup.button.callback('⏹ Stop', 'stop_stream')]
        ]);
        if (isEdit) try { await ctx.editMessageCaption(caption, {parse_mode:'HTML', ...kb}); } catch(e){}
        else await ctx.reply(caption, {parse_mode:'HTML', ...kb});
    }

    bot.action('toggle_play', async (ctx) => {
        const id = ctx.chat.id;
        if (playerState[id]) {
            playerState[id].isPlaying ? await player.pause(id) : await player.resume(id);
            playerState[id].isPlaying = !playerState[id].isPlaying;
            await sendPlayerInterface(ctx, id, true);
            ctx.answerCbQuery();
        }
    });

    bot.action('stop_stream', async (ctx) => {
        await player.leave(ctx.chat.id);
        delete playerState[ctx.chat.id];
        await ctx.editMessageCaption("⏹ Stopped.", {parse_mode:'HTML'});
    });

    bot.command('stop', async (ctx) => {
        await player.leave(ctx.chat.id);
        delete playerState[ctx.chat.id];
        ctx.reply("⏹ Stopped.");
    });

    bot.action(['seek_back', 'seek_fwd'], async (ctx) => {
        const id = ctx.chat.id;
        if (playerState[id]) {
            playerState[id].currentTime += (ctx.match[0] === 'seek_fwd' ? 10 : -10);
            if (playerState[id].currentTime < 0) playerState[id].currentTime = 0;
            await sendPlayerInterface(ctx, id, true);
            ctx.answerCbQuery();
        }
    });

    bot.launch();
    console.log('🚀 Bot Siap Digunakan!');
    
    // Graceful Stop
    process.once('SIGINT', () => { bot.stop('SIGINT'); client.disconnect(); });
    process.once('SIGTERM', () => { bot.stop('SIGTERM'); client.disconnect(); });

})();
EOF

# 8. INSTALL & RUN (FIXED)
echo ""
echo -e "${YELLOW}[Install] Menginstall Module (Ini agak lama, mohon tunggu)...${NC}"
npm install

echo ""
echo -e "${YELLOW}[Run] Menjalankan Bot di Background...${NC}"
screen -X -S ytbot quit 2>/dev/null
screen -dmS ytbot bash -c "cd '$BOT_DIR' && npm start"

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   ✅ FIX SELESAI! BOT SUDAH BERJALAN        ${NC}"
echo -e "${CYAN}   Lokasi: $BOT_DIR                          ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Cek Log: ${YELLOW}screen -r ytbot${NC}"
