#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER BOT (FIXED DIRECTORY PATH) ===${NC}"
echo ""

# 1. INPUT
read -p "Masukkan Token Bot: " INPUT_TOKEN
if [ -z "$INPUT_TOKEN" ]; then
  echo "Token wajib diisi."
  exit 1
fi

echo ""
read -p "Masukkan URL Thumbnail: " INPUT_THUMB
if [ -z "$INPUT_THUMB" ]; then
  INPUT_THUMB="https://files.catbox.moe/fm0qng.jpg"
fi

# 2. SYSTEM UPDATE
echo ""
echo -e "${YELLOW}Update System...${NC}"
sudo apt-get update -y
sudo apt-get install -y screen curl build-essential git ffmpeg

if ! command -v node &> /dev/null
then
    echo "Install Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 3. BUAT FOLDER (FIXED)
# Kita hapus folder lama biar bersih
rm -rf my_yt_bot
# Buat folder baru
mkdir -p my_yt_bot

# Simpan lokasi folder saat ini (Absolute Path) untuk dipakai Screen nanti
CURRENT_DIR=$(pwd)
BOT_DIR="$CURRENT_DIR/my_yt_bot"

echo -e "${GREEN}Folder Bot dibuat di: $BOT_DIR${NC}"
# Masuk ke folder
cd my_yt_bot

# 4. BUAT FILE
echo ""
echo -e "${YELLOW}Menulis File...${NC}"

cat << 'EOF' > package.json
{
  "name": "yt-stream-bot",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "telegraf": "latest",
    "yt-search": "latest",
    "@distube/ytdl-core": "latest",
    "gram-tgcalls": "latest",
    "@discordjs/opus": "latest"
  }
}
EOF

cat << EOF > config.js
module.exports = {
    botToken: "$INPUT_TOKEN",
    thumbUrl: "$INPUT_THUMB"
};
EOF

cat << 'EOF' > index.js
const { Telegraf, Markup } = require('telegraf');
const yts = require('yt-search');
const ytdl = require('@distube/ytdl-core');
const { GramTGCalls, AudioVideoContent, AudioContent } = require('gram-tgcalls');
const config = require('./config');

const bot = new Telegraf(config.botToken);
const player = new GramTGCalls(bot);
const playerState = {};

const createMenuText = (name) => {
    return `
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
};

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
    await ctx.answerCbQuery('Menghubungkan...');
    try {
        const videoUrl = `https://www.youtube.com/watch?v=${id}`;
        const info = await ytdl.getInfo(videoUrl);
        const format = type === 'vid' 
            ? ytdl.chooseFormat(info.formats, { quality: '18' }) 
            : ytdl.chooseFormat(info.formats, { quality: 'highestaudio' });
        if (!format || !format.url) throw new Error('No stream URL');
        let media = type === 'vid' 
            ? new AudioVideoContent({ video: { url: format.url }, audio: { url: format.url } })
            : new AudioContent({ url: format.url });
        await player.join(chatId, media);
        playerState[chatId] = { isPlaying: true, currentTime: 0, duration: parseInt(info.videoDetails.lengthSeconds), title: info.videoDetails.title, type: type };
        await sendPlayerInterface(ctx, chatId);
        player.on('finish', () => { player.leave(chatId); delete playerState[chatId]; });
    } catch (e) { ctx.reply(`Error: ${e.message}`); }
});

bot.action(/dl_(vid|mus)_(.+)/, (ctx) => ctx.answerCbQuery('Download nonaktif.'));

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
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));
EOF

# 5. INSTALL & RUN (FIXED EXECUTION PATH)
echo ""
echo -e "${YELLOW}Install Module...${NC}"
npm install

echo ""
echo -e "${YELLOW}Menjalankan Screen...${NC}"
screen -X -S ytbot quit 2>/dev/null

# INI BAGIAN TERPENTING:
# Kita perintahkan screen untuk pindah (cd) ke $BOT_DIR dulu, baru npm start
screen -dmS ytbot bash -c "cd '$BOT_DIR' && npm start"

echo ""
echo -e "${GREEN}BERHASIL!${NC}"
echo -e "Lokasi Bot: ${CYAN}$BOT_DIR${NC}"
echo -e "Cek Log: ${YELLOW}screen -r ytbot${NC}"
