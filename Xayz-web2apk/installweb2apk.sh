#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${YELLOW}   AUTO INSTALLER WEB2APK BY @XYCoolcraft  ${NC}"
echo -e "${CYAN}==============================================${NC}"
echo -e "Bot akan otomatis berjalan menggunakan 'screen' setelah install."
echo ""

echo -e "${GREEN}[?] Masukkan Token Bot Telegram:${NC}"
read -p "> " BOT_TOKEN

echo -e "${GREEN}[?] Masukkan ID Telegram Owner:${NC}"
read -p "> " OWNER_ID

echo -e "${GREEN}[?] Masukkan Link Gambar/GIF Menu:${NC}"
read -p "> " THUMB_URL

echo ""
echo -e "${YELLOW}⏳ Memulai Instalasi Otomatis...${NC}"
sleep 2

echo -e "${CYAN}[1/5] Mengupdate System & Install Java/Screen...${NC}"
apt-get update -y
apt-get install -y screen curl wget git zip unzip

if type -p java > /dev/null; then
    echo -e "✅ Java sudah ada."
else
    echo -e "📦 Menginstall Java JDK..."
    apt-get install -y default-jdk
fi

echo -e "${CYAN}[2/5] Menginstall Node.js...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs build-essential

echo -e "${CYAN}[3/5] Menyiapkan File Bot...${NC}"
mkdir -p /root/bot-web2apk
cd /root/bot-web2apk

cat > package.json <<EOF
{
  "name": "Web2Apk. Created By: @XYCoolcraft",
  "version": "1.0.0",
  "description": "Created And Developer By: @XYCoolcraft",
  "main": "xayz-web2apk.js",
  "scripts": {
    "start": "node xayz-web2apk.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "systeminformation": "^5.21.0",
    "telegraf": "^4.15.0",
    "website-to-apk": "^1.0.4"
  }
}
EOF

cat > config.js <<EOF
module.exports = {
    botToken: "$BOT_TOKEN",
    ownerId: "$OWNER_ID",
    botName: "Web2Apk Premium",
    menuMedia: "$THUMB_URL"
};
EOF

cat > xayz-web2apk.js <<'EOF'
const { Telegraf, Markup, Scenes, session } = require('telegraf');
const si = require('systeminformation');
const fs = require('fs');
const path = require('path');
const websiteToApk = require('website-to-apk');
const axios = require('axios');
const config = require('./config');

const bot = new Telegraf(config.botToken);

function formatRuntime(seconds) {
    const d = Math.floor(seconds / (3600 * 24));
    const h = Math.floor(seconds % (3600 * 24) / 3600);
    const m = Math.floor(seconds % 3600 / 60);
    const s = Math.floor(seconds % 60);
    return `${d}d ${h}h ${m}m ${s}s`;
}

const apkWizard = new Scenes.WizardScene(
    'apk_wizard',
    (ctx) => {
        ctx.reply('🔗 <b>Kirim Link Website</b>\nContoh: <i>https://google.com</i>', { parse_mode: 'HTML' });
        return ctx.wizard.next();
    },
    (ctx) => {
        if (!ctx.message?.text) return ctx.reply('⚠️ Harap kirim link teks.');
        const url = ctx.message.text;
        if (!url.startsWith('http')) return ctx.reply('⚠️ Wajib pakai http:// atau https://');
        ctx.wizard.state.url = url;
        ctx.reply('📱 <b>Nama Aplikasi?</b>', { parse_mode: 'HTML' });
        return ctx.wizard.next();
    },
    (ctx) => {
        ctx.wizard.state.appName = ctx.message.text;
        ctx.reply('🎨 <b>Pilih Icon</b>', Markup.inlineKeyboard([
            [Markup.button.callback('🖼️ Custom', 'icon_custom'), Markup.button.callback('🤖 Default', 'icon_default')]
        ]));
        return ctx.wizard.next();
    },
    async (ctx) => {
        if (ctx.callbackQuery) {
            await ctx.answerCbQuery();
            if (ctx.callbackQuery.data === 'icon_default') {
                ctx.wizard.state.iconPath = null;
                return processBuild(ctx);
            }
            ctx.wizard.state.waitPhoto = true;
            ctx.reply('📤 Kirim Fotonya sekarang (Kotak).');
            return;
        }
        if (ctx.message?.photo && ctx.wizard.state.waitPhoto) {
            const fileLink = await ctx.telegram.getFileLink(ctx.message.photo.pop().file_id);
            const tempIcon = path.resolve(__dirname, `icon_${ctx.from.id}.png`);
            const writer = fs.createWriteStream(tempIcon);
            const res = await axios({ url: fileLink.href, responseType: 'stream' });
            res.data.pipe(writer);
            await new Promise((resolve) => writer.on('finish', resolve));
            ctx.wizard.state.iconPath = tempIcon;
            return processBuild(ctx);
        }
    }
);

async function processBuild(ctx) {
    const { url, appName, iconPath } = ctx.wizard.state;
    await ctx.reply(`⚙️ <b>Membuat APK...</b>\nTarget: ${url}`, { parse_mode: 'HTML' });
    
    const outDir = path.resolve(__dirname, 'apk_out');
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);
    
    try {
        await websiteToApk({ url, icon: iconPath, name: appName, out: outDir });
        const file = fs.readdirSync(outDir).find(f => f.endsWith('.apk'));
        if (!file) throw new Error("Gagal build.");
        
        await ctx.replyWithDocument({ source: path.join(outDir, file), filename: `${appName}.apk` }, 
            { caption: `✅ Selesai!\nApp: ${appName}`, parse_mode: 'HTML' });
            
        fs.unlinkSync(path.join(outDir, file));
        if (iconPath) fs.unlinkSync(iconPath);
    } catch (e) {
        ctx.reply(`❌ Error: ${e.message}`);
    }
    return ctx.scene.leave();
}

const stage = new Scenes.Stage([apkWizard]);
bot.use(session());
bot.use(stage.middleware());

bot.start(async (ctx) => {
    const cpu = await si.currentLoad();
    const mem = await si.mem();
    
    const msg = `
<b><blockquote>こんにちは👋、私は ${config.botName}. 所有者: ${config.ownerId}. 作成および開発者: @XYCoolcraft</blockquote></b>
<b><blockquote>Status:
💻 CPU: ${cpu.currentLoad.toFixed(1)}%
💾 RAM: ${(mem.active/1e9).toFixed(2)}GB / ${(mem.total/1e9).toFixed(2)}GB
Runtime: ${formatRuntime(process.uptime())}
</blockquote></b>
User: ${ctx.from.first_name}`;

    try {
        await ctx.replyWithPhoto(config.menuMedia, { 
            caption: msg, parse_mode: 'HTML', 
            ...Markup.inlineKeyboard([[Markup.button.callback('📱 BUAT APK', 'start_convert')]]) 
        });
    } catch {
        ctx.reply(msg, { parse_mode: 'HTML' });
    }
});

bot.action('start_convert', ctx => ctx.scene.enter('apk_wizard'));
bot.launch().then(() => console.log('✅ Bot ON!'));
process.once('SIGINT', () => bot.stop('SIGINT'));
EOF

echo -e "${CYAN}[4/5] Menginstall Library Bot...${NC}"
npm install

echo -e "${CYAN}[5/5] Menjalankan Bot dengan Screen...${NC}"

screen -S web2apk -X quit > /dev/null 2>&1

screen -dmS web2apk node index.js

echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}      ✅ SUKSES! BOT SUDAH BERJALAN           ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "Bot sekarang berjalan di background dalam sesi Screen bernama 'web2apk'."
echo -e "Terima Kasih Telah Menggunakan Script Auto Install Web2Apk! Created And Developer By: @XYCoolcraft"
echo ""
echo -e "${YELLOW}👉 Cara Mengecek/Melihat Log Bot:${NC}"
echo -e "   Ketik: ${CYAN}screen -r web2apk${NC}"
echo ""
echo -e "${YELLOW}👉 Cara Keluar dari Log (Tanpa mematikan bot):${NC}"
echo -e "   Tekan tombol: ${CYAN}CTRL + A${NC}, lalu tekan ${CYAN}D${NC}"
echo ""
