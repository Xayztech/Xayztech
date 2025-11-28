#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER BOT (ULTIMATE VERSION) ===${NC}"
echo -e "${YELLOW}Engine: yt-dlp (Python) | Fix: Sign In Error | Feature: Real Download${NC}"
echo ""

# 1. INPUT
read -p "Masukkan Token Bot: " INPUT_TOKEN
if [ -z "$INPUT_TOKEN" ]; then echo -e "${RED}Token Wajib!${NC}"; exit 1; fi

echo ""
read -p "Masukkan URL Thumbnail: " INPUT_THUMB
if [ -z "$INPUT_THUMB" ]; then INPUT_THUMB="https://files.catbox.moe/fm0qng.jpg"; fi

# 2. SYSTEM UPDATE & INSTALL YT-DLP (THE FIX)
echo ""
echo -e "${YELLOW}[1/6] Menginstall yt-dlp Binary (Engine Terkuat)...${NC}"
sudo apt-get update -y
sudo apt-get install -y screen curl build-essential git ffmpeg python3 python3-pip

# Install yt-dlp langsung dari GitHub (agar selalu versi terbaru untuk bypass blokir)
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

# Cek apakah yt-dlp terinstall
if ! command -v yt-dlp &> /dev/null; then
    echo -e "${RED}Gagal install yt-dlp. Mencoba via pip...${NC}"
    pip3 install yt-dlp
fi

echo -e "${GREEN}✅ Engine yt-dlp siap!${NC}"

# 3. NODE.JS SETUP
if ! command -v node &> /dev/null; then
    echo "Install Node.js v20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 4. RESET FOLDER
echo ""
echo -e "${YELLOW}[2/6] Menyiapkan Folder Project...${NC}"
rm -rf my_yt_bot
mkdir -p my_yt_bot
CURRENT_DIR=$(pwd)
BOT_DIR="$CURRENT_DIR/my_yt_bot"
cd "$BOT_DIR"

# 5. PACKAGE.JSON
# Kita hapus ytdl-core dan ganti logika pakai child_process
echo -e "${YELLOW}[3/6] Membuat package.json...${NC}"
cat << 'EOF' > package.json
{
  "name": "yt-stream-bot-ultimate",
  "version": "5.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "telegraf": "^4.16.3",
    "yt-search": "^2.10.4",
    "gram-tgcalls": "^2.2.0",
    "telegram": "^2.19.10",
    "input": "^1.0.0"
  }
}
EOF

# 6. CONFIG
cat << EOF > config.js
module.exports = { botToken: "$INPUT_TOKEN", thumbUrl: "$INPUT_THUMB" };
EOF

# 7. INDEX.JS (LOGIKA BARU: MEMANGGIL PYTHON DARI NODEJS)
echo -e "${YELLOW}[4/6] Menulis Kode Bot (Real Download Logic)...${NC}"
cat << 'EOF' > index.js
const { Telegraf, Markup } = require('telegraf');
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { GramTGCalls, AudioVideoContent, AudioContent } = require('gram-tgcalls');
const yts = require('yt-search');
const { exec } = require('child_process'); // Kita pakai ini untuk kontrol yt-dlp
const fs = require('fs');
const config = require('./config');

const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";
const stringSession = new StringSession(""); 

// Helper: Eksekusi yt-dlp
const getStreamLink = (url) => {
    return new Promise((resolve, reject) => {
        // -g: Get URL, -f: Format Best
        exec(`yt-dlp -g -f best "${url}"`, (error, stdout, stderr) => {
            if (error) return reject(stderr || error);
            resolve(stdout.trim());
        });
    });
};

const getAudioLink = (url) => {
    return new Promise((resolve, reject) => {
        exec(`yt-dlp -g -f bestaudio "${url}"`, (error, stdout, stderr) => {
            if (error) return reject(stderr || error);
            resolve(stdout.trim());
        });
    });
};

(async () => {
    console.log("🔄 Engine Starting...");

    const bot = new Telegraf(config.botToken);
    const client = new TelegramClient(stringSession, API_ID, API_HASH, { connectionRetries: 5 });
    await client.start({ botAuthToken: config.botToken });
    console.log("✅ MTProto Connected");

    const player = new GramTGCalls(client);
    const playerState = {};

    const createMenuText = (name) => `
<b><blockquote>==================================</blockquote></b>
<b><blockquote>Olla👋, ${name}
Ultimate YouTube Bot (yt-dlp Engine)
|| Developer: @XYCoolcraft</blockquote></b>
<b><blockquote>============⟩ MENU ⟨============</blockquote></b>
<b>/ytvid [judul]</b>
╰ Video Stream & Download
<b>/ytmusic [judul]</b>
╰ Music Stream & Download
<b>/stop</b>
╰ Stop Player
<b><blockquote>==================================</blockquote></b>`;

    bot.start((ctx) => {
        const name = ctx.from.first_name || 'User';
        ctx.replyWithPhoto(config.thumbUrl, { caption: createMenuText(name), parse_mode: 'HTML' });
    });

    // --- SEARCH ---
    async function searchYouTube(query) {
        const r = await yts(query);
        return r.videos.length > 0 ? r.videos[0] : null;
    }

    bot.command(['ytvid', 'ytmusic'], async (ctx) => {
        const isMusic = ctx.message.text.includes('ytmusic');
        const query = ctx.message.text.split(' ').slice(1).join(' ');
        if (!query) return ctx.reply(`Contoh: /${isMusic ? 'ytmusic' : 'ytvid'} Judul`);
        
        const video = await searchYouTube(query);
        if (!video) return ctx.reply('Tidak ditemukan.');

        const btns = [
            [Markup.button.callback(isMusic ? '📂 Kirim File Audio (Real)' : '📂 Kirim File Video (Real)', `dl_${isMusic?'mus':'vid'}_${video.videoId}`)],
            [Markup.button.callback(isMusic ? '📞 Voice Call (Live)' : '📹 Video Call (Live)', `stream_${isMusic?'mus':'vid'}_${video.videoId}`)]
        ];

        await ctx.replyWithPhoto(video.thumbnail, {
            caption: `🎬 <b>${video.title}</b>\n⏱ ${video.timestamp}\n👤 ${video.author.name}`,
            parse_mode: 'HTML',
            ...Markup.inlineKeyboard(btns)
        });
    });

    // --- STREAM HANDLER (BYPASS SIGN IN) ---
    bot.action(/stream_(vid|mus)_(.+)/, async (ctx) => {
        const type = ctx.match[1];
        const id = ctx.match[2];
        const chatId = ctx.chat.id;
        
        await ctx.answerCbQuery('Memproses Link Stream (yt-dlp)...');
        try {
            const videoUrl = `https://www.youtube.com/watch?v=${id}`;
            let streamUrl;

            // Gunakan yt-dlp untuk ambil link mentah (Bypass IP Block)
            if (type === 'vid') {
                 streamUrl = await getStreamLink(videoUrl);
            } else {
                 streamUrl = await getAudioLink(videoUrl);
            }
            
            if (!streamUrl) throw new Error('Gagal mengambil link stream.');
            
            let media = type === 'vid' 
                ? new AudioVideoContent({ video: { url: streamUrl }, audio: { url: streamUrl } })
                : new AudioContent({ url: streamUrl });
                
            await player.join(chatId, media);
            
            playerState[chatId] = { isPlaying: true, currentTime: 0, duration: 300, title: 'Streaming...', type: type };
            await sendPlayerInterface(ctx, chatId);
            
            player.on('finish', () => { player.leave(chatId); delete playerState[chatId]; });

        } catch (e) {
            console.error(e);
            ctx.reply(`❌ Gagal: ${e.message}\n(Coba lagi nanti atau update yt-dlp)`);
        }
    });

    // --- REAL DOWNLOAD HANDLER ---
    bot.action(/dl_(vid|mus)_(.+)/, async (ctx) => {
        const type = ctx.match[1]; // vid or mus
        const id = ctx.match[2];
        const videoUrl = `https://www.youtube.com/watch?v=${id}`;
        
        await ctx.answerCbQuery('Sedang mendownload ke server... Mohon tunggu.');
        await ctx.reply(`⬇️ Sedang mendownload file... (Bisa memakan waktu tergantung durasi)`);

        const filename = `download_${id}.${type === 'vid' ? 'mp4' : 'mp3'}`;
        
        // Command yt-dlp untuk download file nyata
        // -o : output filename
        // --max-filesize 50M : Batas limit bot telegram (bisa dihapus kalau pakai local server)
        let cmd;
        if (type === 'vid') {
            cmd = `yt-dlp -f "best[ext=mp4]" -o "${filename}" "${videoUrl}"`;
        } else {
            cmd = `yt-dlp -x --audio-format mp3 -o "${filename}" "${videoUrl}"`;
        }

        exec(cmd, async (error, stdout, stderr) => {
            if (error) {
                return ctx.reply(`❌ Gagal Download: ${stderr}`);
            }

            try {
                await ctx.replyWithChatAction(type === 'vid' ? 'upload_video' : 'upload_voice');
                
                if (type === 'vid') {
                    await ctx.replyWithVideo({ source: filename }, { caption: '✅ Video Downloaded by Bot' });
                } else {
                    await ctx.replyWithAudio({ source: filename }, { caption: '✅ Music Downloaded by Bot' });
                }

                // Hapus file setelah dikirim agar server tidak penuh
                fs.unlinkSync(filename);
            } catch (err) {
                ctx.reply(`❌ Gagal Mengirim File (Mungkin terlalu besar > 50MB): ${err.message}`);
                // Bersihkan file sisa jika gagal
                if (fs.existsSync(filename)) fs.unlinkSync(filename);
            }
        });
    });

    async function sendPlayerInterface(ctx, chatId, isEdit = false) {
        const state = playerState[chatId];
        if (!state) return;
        const status = state.isPlaying ? '▶️ Playing' : '⏸ Paused';
        const caption = `<b>${state.type === 'vid'?'📹':'📞'} Player (Live)</b>\n${status}\n⚠ <i>Seekbar dimatikan di mode live yt-dlp</i>`;
        
        const kb = Markup.inlineKeyboard([
            [Markup.button.callback(state.isPlaying?'⏸ Pause':'▶️ Resume', 'toggle_play')],
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

    bot.launch();
    console.log('🚀 BOT BERJALAN!');
    process.once('SIGINT', () => { bot.stop('SIGINT'); client.disconnect(); });
    process.once('SIGTERM', () => { bot.stop('SIGTERM'); client.disconnect(); });
})();
EOF

# 8. INSTALL & RUN
echo ""
echo -e "${YELLOW}[5/6] Menginstall Modules...${NC}"
npm cache clean --force
npm install --unsafe-perm --force

# Cek manual
if [ ! -d "node_modules/gram-tgcalls" ]; then
    echo -e "${RED}[WARN] Mengulang instalasi tgcalls...${NC}"
    npm install gram-tgcalls --unsafe-perm
fi

echo ""
echo -e "${YELLOW}[6/6] Menjalankan Bot di Background...${NC}"
screen -X -S ytbot quit 2>/dev/null
screen -dmS ytbot bash -c "cd '$BOT_DIR' && npm start"

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   ✅ SUKSES! SYSTEM ENGINE TELAH DIGANTI    ${NC}"
echo -e "${CYAN}   Sekarang bot menggunakan yt-dlp (Python)  ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo -e "Cek Log: ${YELLOW}screen -r ytbot${NC}"
