#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}=== AUTO INSTALLER BOT (SEPARATE ENDPOINTS) ===${NC}"
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
  "name": "Xayz YouTube Stream Telegram",
  "version": "3.0.0",
  "description": "Created And Developer By: @XYCoolcraft",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "telegraf": "latest",
    "gram-tgcalls": "latest",
    "telegram": "latest",
    "input": "latest",
    "axios": "latest",
    "yt-search": "latest"
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
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { GramTGCalls, AudioVideoContent, AudioContent } = require('gram-tgcalls');
const axios = require('axios');
const yts = require('yt-search');
const config = require('./config');

const API_ID = 2040;
const API_HASH = "b18441a1ff607e10a989891a5462e627";
const stringSession = new StringSession("");

(async () => {
    const bot = new Telegraf(config.botToken);
    const client = new TelegramClient(stringSession, API_ID, API_HASH, { connectionRetries: 5 });
    await client.start({ botAuthToken: config.botToken });

    const player = new GramTGCalls(client);
    const playerState = {};

    const createMenuText = (name) => `
<b><blockquote>==================================</blockquote></b>\n

<b><blockquote>Olla👋, ${name}
これは、Telegram でのストリーム用の YouTube ミュージックおよび YouTube ビデオ ボットです || 作成および開発者: @XYCoolcraft</blockquote></b>\n

<b><blockquote>============⟩ MENU ⟨============</blockquote></b>
<b>/ytvid [judul]</b>
╰ Video Stream & Download
<b>/ytmusic [judul]</b>
╰ Music Stream & Download
<b>/stop</b>
╰ Stop Player\n

<b><blockquote>==================================</blockquote></b>`;

    bot.start((ctx) => {
        ctx.replyWithPhoto(config.thumbUrl, {
            caption: createMenuText(ctx.from.first_name || 'User'),
            parse_mode: 'HTML'
        });
    });

    bot.command('menu', (ctx) => {
        ctx.replyWithPhoto(config.thumbUrl, {
            caption: createMenuText(ctx.from.first_name || 'User'),
            parse_mode: 'HTML'
        });
    });

    bot.command('ytmusic', async (ctx) => {
        const query = ctx.message.text.split(' ').slice(1).join(' ');
        if (!query) return ctx.reply('Contoh: /ytmusic Judul Lagu');

        await ctx.sendChatAction('typing');

        try {
            const apiUrl = "https://api.nekolabs.web.id/downloader/youtube/play/v1";
            const { data } = await axios.get(apiUrl, { params: { q: query } });

            if (!data.status || !data.result) return ctx.reply('Lagu tidak ditemukan.');

            const r = data.result;
            const title = r.title;
            const downloadUrl = r.downloadUrl;
            const thumb = r.thumbnail || config.thumbUrl;
            const channel = r.channel;

            const btns = [
                [Markup.button.callback('📂 Kirim Audio', 'send_mus')],
                [Markup.button.callback('📞 Voice Call', 'stream_mus')]
            ];

            const msg = await ctx.replyWithPhoto(thumb, {
                caption: `🎵 <b>${title}</b>\n👤 ${channel}\n\n<i>Pilih metode:</i>`,
                parse_mode: 'HTML',
                ...Markup.inlineKeyboard(btns)
            });

            playerState[ctx.chat.id] = {
                msgId: msg.message_id,
                url: downloadUrl,
                title: title,
                type: 'mus'
            };

        } catch (e) {
            ctx.reply(`Error: ${e.message}`);
        }
    });

    bot.command('ytvid', async (ctx) => {
        const query = ctx.message.text.split(' ').slice(1).join(' ');
        if (!query) return ctx.reply('Contoh: /ytvid Judul Video');

        await ctx.sendChatAction('typing');

        try {
            const search = await yts(query);
            if (!search.videos.length) return ctx.reply('Video tidak ditemukan di YouTube.');
            const video = search.videos[0];

            const apiUrl = "https://api.nekolabs.web.id/downloader/youtube/v3";
            const { data } = await axios.get(apiUrl, { 
                params: { 
                    url: video.url,
                    type: 'video',
                    format: '720'
                } 
            });

            if (!data.result || !data.result.downloadUrl) return ctx.reply('Gagal mengambil link video dari API.');

            const r = data.result;
            const title = r.title || video.title;
            const downloadUrl = r.downloadUrl;
            const thumb = r.thumbnail || video.thumbnail;
            const channel = r.channel || video.author.name;

            const btns = [
                [Markup.button.callback('📂 Kirim Video', 'send_vid')],
                [Markup.button.callback('📹 Video Call', 'stream_vid')]
            ];

            const msg = await ctx.replyWithPhoto(thumb, {
                caption: `🎬 <b>${title}</b>\n👤 ${channel}\n⏱ ${video.timestamp}\n\n<i>Pilih metode:</i>`,
                parse_mode: 'HTML',
                ...Markup.inlineKeyboard(btns)
            });

            playerState[ctx.chat.id] = {
                msgId: msg.message_id,
                url: downloadUrl,
                title: title,
                type: 'vid'
            };

        } catch (e) {
            ctx.reply(`Error: ${e.message}`);
        }
    });

    bot.action(['stream_vid', 'stream_mus'], async (ctx) => {
        const chatId = ctx.chat.id;
        const state = playerState[chatId];
        const isVideo = ctx.match[0] === 'stream_vid';

        if (!state || !state.url) return ctx.answerCbQuery('Sesi habis.');
        
        await ctx.answerCbQuery('Menghubungkan Stream...');

        try {
            const media = isVideo
                ? new AudioVideoContent({ video: { url: state.url }, audio: { url: state.url } })
                : new AudioContent({ url: state.url });

            await player.join(chatId, media);
            
            state.isPlaying = true;
            await sendPlayerInterface(ctx, chatId);

            player.on('finish', () => {
                player.leave(chatId);
                state.isPlaying = false;
            });

        } catch (e) {
            ctx.reply(`Gagal: ${e.message}`);
        }
    });

    bot.action(['send_vid', 'send_mus'], async (ctx) => {
        const chatId = ctx.chat.id;
        const state = playerState[chatId];
        const isVideo = ctx.match[0] === 'send_vid';

        if (!state || !state.url) return ctx.answerCbQuery('Sesi habis.');

        await ctx.answerCbQuery('Mengirim...');
        await ctx.reply('⬇️ Mengambil file dari API...');

        try {
            if (isVideo) {
                await ctx.replyWithVideo({ url: state.url }, { caption: state.title });
            } else {
                await ctx.replyWithAudio({ url: state.url }, { caption: state.title });
            }
        } catch (e) {
            ctx.reply(`Gagal kirim: ${e.message}`);
        }
    });

    async function sendPlayerInterface(ctx, chatId, isEdit = false) {
        const state = playerState[chatId];
        if (!state) return;

        const caption = `<b>${state.type === 'vid'?'📹':'📞'} Player</b>\n${state.isPlaying ? '▶️ Playing' : '⏸ Paused'}\n🎵 ${state.title}`;
        
        const kb = Markup.inlineKeyboard([
            [Markup.button.callback(state.isPlaying?'⏸ Pause':'▶️ Resume', 'toggle_play')],
            [Markup.button.callback('⏹ Stop', 'stop_stream')]
        ]);

        if (isEdit) {
            try { await ctx.editMessageCaption(caption, { parse_mode: 'HTML', ...kb }); } catch(e){}
        } else {
            await ctx.reply(caption, { parse_mode: 'HTML', ...kb });
        }
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
    console.log('BOT STARTED');
    process.once('SIGINT', () => { bot.stop('SIGINT'); client.disconnect(); });
    process.once('SIGTERM', () => { bot.stop('SIGTERM'); client.disconnect(); });
})();
EOF

npm cache clean --force
npm install

screen -X -S ytbot quit 2>/dev/null
screen -S ytbot bash -c "cd '$BOT_DIR' && npm start"

echo ""
echo -e "${GREEN}BERHASIL! Cek: screen -r ytbot${NC}"
