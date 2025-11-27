#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER BOT (FIXED: INSTALLATION PROCESS) ===${NC}"
echo -e "${YELLOW}Memperbaiki Error: Cannot find module 'telegraf'${NC}"
echo ""

# 1. INPUT
read -p "Masukkan Token Bot: " INPUT_TOKEN
if [ -z "$INPUT_TOKEN" ]; then echo -e "${RED}Token Wajib!${NC}"; exit 1; fi

echo ""
read -p "Masukkan URL Thumbnail: " INPUT_THUMB
if [ -z "$INPUT_THUMB" ]; then INPUT_THUMB="https://files.catbox.moe/fm0qng.jpg"; fi

# 2. PERSIAPAN SYSTEM
echo ""
echo -e "${YELLOW}[1/6] Update System & Install Tools...${NC}"
sudo apt-get update -y
sudo apt-get install -y screen curl build-essential git ffmpeg python3

if ! command -v node &> /dev/null; then
    echo "Install Node.js v20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 3. BERSIHKAN & BUAT FOLDER
echo ""
echo -e "${YELLOW}[2/6] Reset Folder Project...${NC}"
rm -rf my_yt_bot
mkdir -p my_yt_bot
CURRENT_DIR=$(pwd)
BOT_DIR="$CURRENT_DIR/my_yt_bot"
cd "$BOT_DIR"

# 4. BUAT PACKAGE.JSON
echo -e "${YELLOW}[3/6] Membuat package.json...${NC}"
cat << 'EOF' > package.json
{
  "name": "yt-stream-bot-final",
  "version": "3.0.0",
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

# 5. CONFIG FILE
cat << EOF > config.js
module.exports = { botToken: "$INPUT_TOKEN", thumbUrl: "$INPUT_THUMB" };
EOF

# 6. BUAT INDEX.JS (DUAL CLIENT LOGIC - YANG BENAR)
echo -e "${YELLOW}[4/6] Menulis Kode Bot (index.js)...${NC}"
cat << 'EOF' > index.js
const { Telegraf, Markup } = require('telegraf');
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { GramTGCalls, AudioVideoContent, AudioContent } = require('gram-tgcalls');
const yts = require('yt-search');
const ytdl = require('@distube/ytdl-core');
const config = require('./config');

const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";
const stringSession = new StringSession(""); 

(async () => {
    console.log("🔄 System Starting...");

    // 1. Bot API
    const bot = new Telegraf(config.botToken);

    // 2. MTProto Client
    const client = new TelegramClient(stringSession, API_ID, API_HASH, { connectionRetries: 5 });
    await client.start({ botAuthToken: config.botToken });
    console.log("✅ MTProto Connected");

    // 3. Player
    const player = new GramTGCalls(client);
    const playerState = {};

    // --- MENU ---
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
<b><blockquote>==================================</blockquote></b>`;

    bot.start((ctx) => {
        const name = ctx.from.first_name || 'User';
        ctx.replyWithPhoto(config.thumbUrl, { caption: createMenuText(name), parse_mode: 'HTML' });
    });

    bot.command('menu', (ctx) => {
        const name = ctx.from.first_name || 'User';
        ctx.replyWithPhoto(config.thumbUrl, { caption: createMenuText(name), parse_mode: 'HTML' });
    });

    // --- SEARCH ---
    async function searchYouTube(query) {
        const r = await yts(query);
        return r.videos.length > 0 ? r.videos[0] : null;
    }

    // --- COMMANDS ---
    bot.command(['ytvid', 'ytmusic'], async (ctx) => {
        const isMusic = ctx.message.text.includes('ytmusic');
        const query = ctx.message.text.split(' ').slice(1).join(' ');
        if (!query) return ctx.reply(`Contoh: /${isMusic ? 'ytmusic' : 'ytvid'} Judul Lagu`);
        
        const video = await searchYouTube(query);
        if (!video) return ctx.reply('Tidak ditemukan.');

        const btns = [
            [Markup.button.callback(isMusic ? '📂 Kirim Audio' : '📂 Kirim Video', `dl_${isMusic?'mus':'vid'}_${video.videoId}`)],
            [Markup.button.callback(isMusic ? '📞 Voice Call' : '📹 Video Call', `stream_${isMusic?'mus':'vid'}_${video.videoId}`)]
        ];

        await ctx.replyWithPhoto(video.thumbnail, {
            caption: `🎬 <b>${video.title}</b>\n⏱ ${video.timestamp}\n👤 ${video.author.name}`,
            parse_mode: 'HTML',
            ...Markup.inlineKeyboard(btns)
        });
    });

    // --- STREAM HANDLER ---
    bot.action(/stream_(vid|mus)_(.+)/, async (ctx) => {
        const type = ctx.match[1];
        const id = ctx.match[2];
        const chatId = ctx.chat.id;
        
        await ctx.answerCbQuery('Menghubungkan...');
        try {
            const videoUrl = `https://www.youtube.com/watch?v=${id}`;
            const info = await ytdl.getInfo(videoUrl);
            const format = type === 'vid' 
                ? ytdl.chooseFormat(info.formats, { quality: '18' }) 
                : ytdl.chooseFormat(info.formats, { quality: 'highestaudio' });
            
            if (!format || !format.url) throw new Error('Url Stream Error');
            
            let media = type === 'vid' 
                ? new AudioVideoContent({ video: { url: format.url }, audio: { url: format.url } })
                : new AudioContent({ url: format.url });
                
            await player.join(chatId, media);
            
            playerState[chatId] = { isPlaying: true, currentTime: 0, duration: parseInt(info.videoDetails.lengthSeconds), title: info.videoDetails.title, type: type };
            await sendPlayerInterface(ctx, chatId);
            
            player.on('finish', () => { player.leave(chatId); delete playerState[chatId]; });

        } catch (e) {
            console.error(e);
            ctx.reply(`❌ Gagal: ${e.message}\n(Pastikan Bot sudah jadi ADMIN!)`);
        }
    });

    bot.action(/dl_(.+)/, (ctx) => ctx.answerCbQuery('Fitur Download matikan di demo.'));

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
    console.log('🚀 BOT BERJALAN!');
    process.once('SIGINT', () => { bot.stop('SIGINT'); client.disconnect(); });
    process.once('SIGTERM', () => { bot.stop('SIGTERM'); client.disconnect(); });
})();
EOF

# 7. INSTALL DEPENDENCIES (CRUCIAL STEP)
echo ""
echo -e "${YELLOW}[5/6] Menginstall Modules (Mohon Tunggu, Jangan di-Cancel)...${NC}"

# Bersihkan cache npm agar tidak ada file korup
npm cache clean --force > /dev/null 2>&1

# Install dan TAMPILKAN OUTPUT agar kita tahu kalau gagal
npm install

# CEK APAKAH TELEGRAF BERHASIL DIINSTALL
if [ ! -d "node_modules/telegraf" ]; then
    echo ""
    echo -e "${RED}[ERROR] Instalasi Gagal! 'telegraf' tidak ditemukan.${NC}"
    echo -e "${YELLOW}Mencoba install ulang secara manual...${NC}"
    npm install telegraf yt-search @distube/ytdl-core gram-tgcalls telegram input
fi

# 8. JALANKAN
echo ""
echo -e "${YELLOW}[6/6] Menjalankan Bot...${NC}"

# Matikan screen lama
screen -X -S ytbot quit 2>/dev/null

# Jalankan screen baru dengan perintah pindah folder yang ketat
screen -dmS ytbot bash -c "cd '$BOT_DIR' && npm start"

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   ✅ FIX SELESAI! SILAKAN CEK LOG SEKARANG  ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Cek Log: ${YELLOW}screen -r ytbot${NC}"
