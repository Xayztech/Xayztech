#!/bin/bash

# Warna untuk tampilan teks agar lebih menarik
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}     AUTOSCRIPT INSTALLER XAYZ AI BOT v1 Pro+          ${NC}"
echo -e "${CYAN}         Created and Developer By: @XYCoolcraft              ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo ""

# 1. Meminta Input HANYA Bot Token
echo -e "${YELLOW}[?] Silakan masukkan data:${NC}"
read -p "Masukkan Telegram Bot Token: " INPUT_BOT_TOKEN

if [ -z "$INPUT_BOT_TOKEN" ]; then
    echo -e "${YELLOW}[!] Token Bot wajib diisi! Membatalkan...${NC}"
    exit 1
fi

# 2. Persiapan Folder
FOLDER_NAME="xayz-ai-bot"
echo -e "\n${GREEN}[+] Membuat folder project: $FOLDER_NAME...${NC}"

if [ -d "$FOLDER_NAME" ]; then
    echo "Folder sudah ada, masuk ke folder..."
else
    mkdir "$FOLDER_NAME"
fi
cd "$FOLDER_NAME"

# 3. Membuat File config.js (Token dari input, Key lain OTOMATIS terisi)
echo -e "${GREEN}[+] Membuat file config.js...${NC}"
cat <<EOF > config.js
const { HarmCategory, HarmBlockThreshold } = require('@google/generative-ai');

// Kunci API
const TELEGRAM_TOKEN = "$INPUT_BOT_TOKEN";
const GEMINI_KEY = "AIzaSyCqTL0YkNnCVPbaNJyPz64DTSqMp7xnzfk"; // Otomatis dari script
const BOTCAHX_API_KEY = "XYCoolcraftNihBoss"; // Otomatis dari script

const config = {
  TELEGRAM_TOKEN: TELEGRAM_TOKEN,
  GEMINI_KEY: GEMINI_KEY,
  
  IMAGE_GEN_API_URL: 'https://api.botcahx.eu.org/api/search/openai-image',
  IMAGE_GEN_API_KEY: BOTCAHX_API_KEY,
  
  NAKED_API_URL: 'https://api.nekolabs.my.id/tools/convert/remove-clothes',
  CATBOX_API_URL: 'https://catbox.moe/user/api.php',
  
  TIKTOK_API_URL: 'https://www.tikwm.com/api/',
  
  SPOTIFY_SEARCH_URL: 'https://api.botcahx.eu.org/api/search/spotify',
  SPOTIFY_DOWNLOAD_URL: 'https://api.botcahx.eu.org/api/download/spotify',
  SPOTIFY_API_KEY: BOTCAHX_API_KEY,
  
  YTMUSIC_API_URL: 'https://api.nekolabs.web.id/downloader/youtube/v1',
  
  NULIS_API_URL: 'https://lemon-write.vercel.app/api/generate-book',

  WEB2APK_CDN_URL: 'https://cdn.yupra.my.id/upload',
  WEB2APK_BUILD_URL: 'https://api.fikmydomainsz.xyz/tools/toapp/build-complete',

  MSG_MAX_LEN: 3000,
  GRUP_JSON_PATH: './grup.json',
  GEMINI_MODEL_NAME: 'gemini-flash-latest',
  
  NAKED_KEYWORDS: ['telanjang', 'tidak memakai', 'bugil', 'tanpa busana', 'tonaked'],

  SYSTEM_PROMPT: \`Anda adalah bot Xayz AI serba guna. Anda adalah "All-in-One" asisten.
Tugas Anda adalah membantu pengguna dengan berbagai hal (pengetahuan, koding, dll).

ATURAN PALING PENTING:
1.  Jika pengguna meminta Anda 'membuat' atau 'generate' gambar, respons HANYA dengan:
    [GENERATE_IMAGE: <deskripsi_gambar_yang_jelas_untuk_API>]

2.  Jika pengguna mengirim gambar DAN meminta untuk 'memperjelas', 'HD', 'restore', 'hd', 'enhance', atau 'memperbaiki' gambar itu, respons HANYA dengan:
    [ENHANCE_IMAGE]

3.  Jika pengguna meminta untuk 'memainkan', 'memutar', 'menyetel', atau 'mencari lagu' (tanpa menyebut Spotify) respons HANYA dengan: 
    [PLAY_MUSIC: <judul_lagu_atau_artis>], Jika ada kata 'spotify', 'Spotify' maka respons HANYA dengan: 
    [PLAY_MUSIC_SPOTIFY: <judul_lagu_atau_artis>]

4.  Jika pengguna meminta untuk 'menulis', 'tulis', 'bertulisan', 'bertulis', 'bertuliskan', 'tuliskan', 'gambar tulisan', 'gambar bertulis', 'gambar menulis', 'gambar bertulisan', 'gambar bertuliskan', 'Gambar tulisan', 'Gambar menulis', 'Gambar bertulisan', 'Gambar bertulis', 'Gambar bertuliskan', 'buku tulis', 'gambar buku tulis', 'nulis', 'tulisin' sesuatu di buku, respons HANYA dengan:
    [WRITE_TO_BOOK: <teks_yang_ingin_ditulis>]

Jika permintaan tidak cocok dengan 4 aturan di atas, jawablah seperti biasa.\`,

  SAFETY_SETTINGS: [
    { category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.BLOCK_NONE },
    { category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.BLOCK_NONE },
    { category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.BLOCK_NONE },
    { category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.BLOCK_NONE },
  ]
};

module.exports = config;
EOF

# 4. Membuat File package.json
echo -e "${GREEN}[+] Membuat file package.json...${NC}"
cat <<EOF > package.json
{
  "name": "Xayz-AI-Bot",
  "version": "1.0.0",
  "description": "Bot AI Created And Developer By: @XYCoolcraft",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "google": "latest",
    "@google/generative-ai": "latest",
    "moment": "^2.30.1",
    "systeminformation": "^5.23.10",
    "axios": "^1.6.8",
    "chalk": "^4.1.2",
    "crypto": "^1.0.1",
    "fs-extra": "^11.2.0",
    "js-confuser": "latest",
    "dotenv": "^16.4.7",
    "@octokit/rest": "^18.12.0",
    "node-telegram-bot-api": "latest",
    "os": "latest",
    "pino": "^9.6.0",
    "qrcode": "^1.5.0",
    "node-cache": "^5.1.2",
    "cheerio": "^1.0.0-rc.10",
    "node-fetch": "^2.6.1",
    "form-data": "^4.0.0",
    "telegram": "latest",
    "sharp": "latest",
    "adm-zip": "latest",
    "tar": "latest",
    "file-type": "16.5.3",
    "yt-search": "latest",
    "url": "latest",
    "puppeteer": "latest",
    "archiver": "latest",
    "https": "latest",
    "googleapis": "latest",
    "http": "latest",
    "@hapi/boom": "latest",
    "dns": "latest",
    "child_process": "latest",
    "net": "latest",
    "ssh2": "latest",
    "gradient-string": "latest",
    "unzipper" : "latest",
    "vm": "latest",
    "fast-glob": "latest",
    "node-ssh": "latest"
  },
  "keywords": [],
  "author": "XYCoolcraft",
  "license": "ISC"
}
EOF

# 5. Membuat File index.js
echo -e "${GREEN}[+] Membuat file index.js...${NC}"
cat <<'EOF' > index.js
const TelegramBot = require('node-telegram-bot-api');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const fs = require('fs');
const axios = require('axios');
const FormData = require('form-data');
const path = require('path');
const os = require('os');
const yts = require('yt-search');
const config = require('./config.js');

// Menggunakan Token dari config.js
const bot = new TelegramBot(config.TELEGRAM_TOKEN, { polling: true });
const genAI = new GoogleGenerativeAI(config.GEMINI_KEY);

const model = genAI.getGenerativeModel({
  model: config.GEMINI_MODEL_NAME,
  safetySettings: config.SAFETY_SETTINGS,
  systemInstruction: config.SYSTEM_PROMPT,
});

const chatHistories = new Map();
const groupIds = loadGroupIds();

function loadGroupIds() {
  try {
    if (fs.existsSync(config.GRUP_JSON_PATH)) {
      const data = fs.readFileSync(config.GRUP_JSON_PATH, 'utf8');
      return new Set(JSON.parse(data));
    }
    return new Set();
  } catch (err) {
    console.error("Gagal memuat grup.json:", err);
    return new Set();
  }
}

function saveGroupIds() {
  try {
    const data = JSON.stringify([...groupIds]);
    fs.writeFileSync(config.GRUP_JSON_PATH, data, 'utf8');
  } catch (err) {
    console.error("Gagal menyimpan ke grup.json:", err);
  }
}

function addGroupId(chatId) {
  if (!groupIds.has(chatId)) {
    groupIds.add(chatId);
    saveGroupIds();
    console.log(`Grup baru ditambahkan: ${chatId}`);
  }
}

async function sendSplitMessage(chatId, text) {
  const codeBlockRegex = /(```[\s\S]*?```)/g;
  const parts = text.split(codeBlockRegex);

  for (const part of parts) {
    if (part.trim() === '') continue;

    if (codeBlockRegex.test(part)) {
      try {
        await bot.sendMessage(chatId, part, { parse_mode: 'Markdown' });
      } catch (e) {
        await bot.sendMessage(chatId, part);
      }
    } else {
      for (let i = 0; i < part.length; i += config.MSG_MAX_LEN) {
        const chunk = part.substring(i, i + config.MSG_MAX_LEN);
        await bot.sendMessage(chatId, chunk);
      }
    }
  }
}

async function getPhotoBuffer(fileId) {
  try {
    const fileStream = bot.getFileStream(fileId);
    const chunks = [];
    for await (const chunk of fileStream) {
      chunks.push(chunk);
    }
    return Buffer.concat(chunks);
  } catch (error) {
    console.error('Error mengunduh foto:', error);
    return null;
  }
}

async function getFileContent(fileId, mimeType) {
  try {
    const allowedMimeTypes = [
      'text/plain', 'text/html', 'text/css', 'text/csv', 'text/xml',
      'application/javascript', 'application/x-javascript',
      'application/json', 'application/xml',
      'application/x-python', 'text/x-python',
      'text/markdown', 'text/x-markdown'
    ];
    
    if (!allowedMimeTypes.includes(mimeType) && !mimeType.startsWith('text/')) {
      console.log(`Mime type ditolak: ${mimeType}`);
      return { error: 'Bot hanya dapat membaca file teks (seperti .txt, .js, .py, .json, .html).' };
    }

    const fileLink = await bot.getFileLink(fileId);
    const response = await axios.get(fileLink, { responseType: 'text' });
    
    if (Buffer.byteLength(response.data, 'utf8') > 100000000) { // Batas 1MB
      return { error: 'File terlalu besar untuk dibaca (batas 100MB).' };
    }

    return { content: response.data };
  } catch (error) {
    console.error('Error mengunduh file dokumen:', error);
    return { error: 'Gagal mengunduh atau membaca file.' };
  }
}

async function uploadToCatbox(buffer) {
  try {
    const form = new FormData();
    form.append('reqtype', 'fileupload');
    form.append('fileToUpload', buffer, { filename: 'upload.jpg' });

    const res = await axios.post(config.CATBOX_API_URL, form, {
      headers: form.getHeaders(),
    });

    if (res.status === 200 && res.data && !res.data.startsWith('Error')) {
      return res.data;
    } else {
      throw new Error(res.data || 'Gagal mengunggah ke Catbox');
    }
  } catch (error) {
    console.error("Catbox upload error:", error.message);
    return null;
  }
}

async function showProgress(chatId, messageId, steps = 5, delay = 400) {
  for (let i = 1; i <= steps; i++) {
    await new Promise(resolve => setTimeout(resolve, delay));
    const progress = "█".repeat(i);
    const remaining = "░".repeat(steps - i);
    try {
      await bot.editMessageText(`⌛ Sedang menulis...\n[${progress}${remaining}]`, {
        chat_id: chatId,
        message_id: messageId,
      });
    } catch (e) {
      return; 
    }
  }
}

async function writeToBook(chatId, text, messageId) {
  try {
    const progressMessage = await bot.sendMessage(chatId, "⌛ Sedang menulis...\n[░░░░░]", { reply_to_message_id: messageId });
    await showProgress(chatId, progressMessage.message_id, 5, 400);

    const response = await axios.post(
      config.NULIS_API_URL,
      {
        text: text,
        font: "default",
        color: "#000000",
        size: "32",
      },
      {
        responseType: "arraybuffer",
        headers: { "Content-Type": "application/json" },
      }
    );

    await bot.deleteMessage(chatId, progressMessage.message_id);
    await bot.sendPhoto(chatId, Buffer.from(response.data), { reply_to_message_id: messageId });
  } catch (error) {
    console.error("Nulis error:", error.message);
    bot.sendMessage(chatId, "❌ Error saat menulis, coba lagi nanti ya.", { reply_to_message_id: messageId });
  }
}

async function buildApk(chatId, url, appName, email, messageId, photoBuffer) {
  let waitMsg;
  try {
    waitMsg = await bot.sendMessage(chatId, 'Upload icon & build APK dimulai... (perkiraan 3-8 menit)', { reply_to_message_id: messageId });

    const form = new FormData();
    form.append('files', photoBuffer, { filename: 'icon.png', contentType: 'image/png' });

    const up = await axios.post(config.WEB2APK_CDN_URL, form, {
      headers: form.getHeaders(),
      timeout: 30000
    });

    if (!up.data?.success || !up.data.files?.[0]) throw new Error('CDN (upload icon) gagal');
    const iconUrl = 'https://cdn.yupra.my.id' + up.data.files[0].url;

    await bot.editMessageText(`Icon berhasil di-upload. Memulai proses build...`, { chat_id: chatId, message_id: waitMsg.message_id });

    const buildUrl = `${config.WEB2APK_BUILD_URL}?url=${encodeURIComponent(url)}&email=${encodeURIComponent(email)}&appName=${encodeURIComponent(appName)}&appIcon=${encodeURIComponent(iconUrl)}`;

    const { data: job } = await axios.get(buildUrl, { timeout: 0 }); 
    if (!job.status) throw new Error(job.error || 'Build API gagal');

    const caption = `Aplikasi berhasil dibuat!\n\n` +
                    `Nama: ${appName}\n` +
                    `Email: ${email}\n` +
                    `Web: ${url}\n` +
                    `Download APK: ${job.downloadUrl}`;

    await bot.deleteMessage(chatId, waitMsg.message_id);
    await bot.sendMessage(chatId, caption, { 
      parse_mode: 'Markdown',
      disable_web_page_preview: true,
      reply_to_message_id: messageId
    });

  } catch (err) {
    console.error('[Web2Apk Error]', err);
    if (waitMsg) {
      await bot.editMessageText(`❌ ${err.message || 'Terjadi kesalahan'}`, { chat_id: chatId, message_id: waitMsg.message_id });
    } else {
      await bot.sendMessage(chatId, `❌ ${err.message || 'Terjadi kesalahan'}`, { reply_to_message_id: messageId });
    }
  }
}

async function generateImage(chatId, prompt, replyToMessageId = null) {
  if (!config.IMAGE_GEN_API_KEY) {
    await bot.sendMessage(chatId, "Fitur gambar tidak aktif. System pihak tidak diatur.");
    return;
  }

  let options = {};
  if (replyToMessageId) {
    options.reply_to_message_id = replyToMessageId;
  }
  
  const processingMsg = await bot.sendMessage(chatId, `🎨 _Membuat gambar: "${prompt}"..._`, { parse_mode: 'Markdown', ...options });

  try {
    const fullApiUrl = `${config.IMAGE_GEN_API_URL}?text=${encodeURIComponent(prompt)}&apikey=${config.IMAGE_GEN_API_KEY}`;
    
    const response = await axios.get(fullApiUrl, {
      responseType: 'arraybuffer',
      timeout: 1200000 
    });

    if (response.data && response.data.length > 0) {
      await bot.sendPhoto(chatId, response.data, { 
        caption: `*Hasil untuk:* ${prompt}`, 
        parse_mode: 'Markdown', 
        reply_to_message_id: replyToMessageId
      });
      
      await bot.deleteMessage(chatId, processingMsg.message_id);
    } else {
      throw new Error('Respons System gambar tidak valid atau kosong.');
    }

  } catch (error) {
    await bot.deleteMessage(chatId, processingMsg.message_id);
    console.error("Error saat generate gambar:", error.message);
    
    if (error.code === 'ECONNABORTED') {
      await bot.sendMessage(chatId, "Maaf, System gambar gagal merespons. Coba lagi nanti.");
    } else {
      await bot.sendMessage(chatId, "Maaf, terjadi kesalahan saat membuat gambar. System mungkin sedang down atau format respons salah.");
    }
  }
}

async function processNakedImage(chatId, imageUrl, senderName) {
  const status = await bot.sendMessage(chatId, "Memproses gambar...");

  try {
    const res = await fetch(`${config.NAKED_API_URL}?imageUrl=${encodeURIComponent(imageUrl)}`, { 
      method: "GET", 
      headers: { accept: "*/*" } 
    });
    
    const data = await res.json();
    const hasil = data.result || null;

    if (!hasil) {
      return bot.editMessageText("Gagal memproses gambar. Pastikan URL atau foto valid.", {
        chat_id: chatId,
        message_id: status.message_id
      });
    }

    await bot.deleteMessage(chatId, status.message_id);

    await bot.sendPhoto(chatId, hasil, {
      caption: 
`**Ini Hasilnya...**`,
      parse_mode: "Markdown"
    });
  } catch (e) {
    console.error("Kesalahan System 'tonaked':", e);
    await bot.editMessageText("Terjadi kesalahan saat memproses gambar.", {
      chat_id: chatId,
      message_id: status.message_id
    });
  }
}

async function Pxpic(path, func) {
  const tool = ['removebg', 'enhance', 'upscale', 'restore', 'colorize'];
  if (!tool.includes(func)) return null;

  const buffer = fs.readFileSync(path);
  const ext = 'jpg';
  const mime = 'image/jpeg';
  const fileName = Math.random().toString(36).slice(2, 8) + '.' + ext;

  const { data } = await axios.post("https://pxpic.com/getSignedUrl", {
    folder: "uploads",
    fileName
  });

  await axios.put(data.presignedUrl, buffer, {
    headers: { "Content-Type": mime }
  });

  const url = "https://files.fotoenhancer.com/uploads/" + fileName;

  const api = await axios.post("https://pxpic.com/callAiFunction", new URLSearchParams({
    imageUrl: url,
    targetFormat: 'png',
    needCompress: 'no',
    imageQuality: '100',
    compressLevel: '6',
    fileOriginalExtension: 'png',
    aiFunction: func,
    upscalingLevel: ''
  }).toString(), {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'Mozilla/5.0',
      'accept-language': 'id-ID'
    }
  });

  return api.data;
}

async function remini(imagePath) {
  return new Promise((resolve, reject) => {
    const form = new FormData();
    form.append('model_version', 1);
    form.append('image', fs.readFileSync(imagePath), {
      filename: 'image.jpg',
      contentType: 'image/jpeg'
    });

    const req = form.submit({
      protocol: 'https:',
      host: 'inferenceengine.vyro.ai',
      path: '/enhance',
      headers: {
        'User-Agent': 'okhttp/4.9.3',
        'Accept-Encoding': 'gzip'
      }
    }, (err, res) => {
      if (err) return reject(err);
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    });
  });
}

async function enhanceImage(buffer, chatId, messageId) {
  const tempFile = path.join(os.tmpdir(), `xayz_hd_${Date.now()}.jpg`);
  const status = await bot.sendMessage(chatId, '📸 Memproses gambar HD... (Ini mungkin butuh waktu)', { reply_to_message_id: messageId });
  
  try {
    fs.writeFileSync(tempFile, buffer);

    const hasil = await Pxpic(tempFile, 'enhance');
    if (hasil?.resultImageUrl) {
      await bot.sendPhoto(chatId, hasil.resultImageUrl, {
        caption: 'Gambar berhasil di-HD-kan!',
        reply_to_message_id: messageId
      });
      await bot.deleteMessage(chatId, status.message_id);
      return; 
    }

    await bot.editMessageText('Pxpic gagal, mencoba fallback Remini...', { chat_id: chatId, message_id: status.message_id });
    const fallback = await remini(tempFile);
    
    if (fallback && fallback.length > 0) {
      await bot.sendPhoto(chatId, fallback, {
        caption: 'HD Success!',
        reply_to_message_id: messageId
      });
      await bot.deleteMessage(chatId, status.message_id);
      return; 
    }

    await bot.editMessageText('Gagal meningkatkan kualitas gambar. Kedua System gagal.', { chat_id: chatId, message_id: status.message_id });

  } catch (err) {
    console.error("EnhanceImage Error:", err);
    await bot.editMessageText('Terjadi kesalahan: ' + err.message, {
      chat_id: chatId,
      message_id: status.message_id
    });
  } finally {
    if (fs.existsSync(tempFile)) {
      fs.unlinkSync(tempFile);
    }
  }
}

async function tiktokDl(url) {
  return new Promise(async (resolve, reject) => {
      try {
          let data = [];
          function formatNumber(integer) {
              return Number(parseInt(integer)).toLocaleString().replace(/,/g, ".");
          }

          function formatDate(n, locale = "id-ID") {
              let d = new Date(n);
              return d.toLocaleDateString(locale, {
                  weekday: "long",
                  day: "numeric",
                  month: "long",
                  year: "numeric",
                  hour: "numeric",
                  minute: "numeric",
                  second: "numeric",
              });
          }

          let domain = config.TIKTOK_API_URL;
          let res = await (
              await axios.post(
                  domain,
                  {},
                  {
                      headers: {
                          Accept: "application/json, text/javascript, */*; q=0.01",
                          "Accept-Language": "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7",
                          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                          Origin: "https://www.tikwm.com",
                          Referer: "https://www.tikwm.com/",
                          "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36",
                      },
                      params: {
                          url: url,
                          count: 12,
                          cursor: 0,
                          web: 1,
                          hd: 2,
                      },
                  }
              )
          ).data.data;

          if (!res) return reject("⚠️ *Gagal mengambil data!*");

          if (res.duration == 0) {
              res.images.forEach((v) => {
                  data.push({ type: "photo", url: v });
              });
          } else {
              data.push(
                  {
                      type: "watermark",
                      url: "https://www.tikwm.com" + res?.wmplay || "/undefined",
                  },
                  {
                      type: "nowatermark",
                      url: "https://www.tikwm.com" + res?.play || "/undefined",
                  },
                  {
                      type: "nowatermark_hd",
                      url: "https://www.tikwm.com" + res?.hdplay || "/undefined",
                  }
              );
          }

          resolve({
              status: true,
              title: res.title,
              taken_at: formatDate(res.create_time).replace("1970", ""),
              region: res.region,
              id: res.id,
              duration: res.duration + " detik",
              cover: "https://www.tikwm.com" + res.cover,
              stats: {
                  views: formatNumber(res.play_count),
                  likes: formatNumber(res.digg_count),
                  comment: formatNumber(res.comment_count),
                  share: formatNumber(res.share_count),
                  download: formatNumber(res.download_count),
              },
              author: {
                  id: res.author.id,
                  fullname: res.author.unique_id,
                  nickname: res.author.nickname,
                  avatar: "https://www.tikwm.com" + res.author.avatar,
              },
              links: data,
          });
      } catch (e) {
          reject("⚠️ *Terjadi kesalahan saat mengambil video!*");
      }
  });
}

async function handleTikTok(url, chatId, messageId) {
  let loadingMessage = await bot.sendMessage(chatId, "⏳ *Mengunduh video, mohon tunggu...*", { parse_mode: "Markdown", reply_to_message_id: messageId });
  try {
      const result = await tiktokDl(url);
      const caption = `✅ *Video TikTok Berhasil Diunduh!*\n\n` + `📌 *${result.title || 'Tanpa Judul'}*\n` + `👤 *${result.author?.nickname || 'Anonim'}*\n\n` + `❤️ *${result.stats?.likes || 0}* suka · ` + `💬 *${result.stats?.comment || 0}* komentar · ` + `🔄 *${result.stats?.share || 0}* dibagikan`;

      if (result.duration === "0 detik") {
          const mediaGroup = result.links.map((v, i) => ({
              type: 'photo',
              media: v.url,
              caption: i === 0 ? caption : '',
              parse_mode: "Markdown"
          }));
          await bot.sendMediaGroup(chatId, mediaGroup, { reply_to_message_id: messageId });
      } else {
          const video = result.links.find(v => v.type === "nowatermark_hd" || v.type === "nowatermark");
          if (!video || !video.url) {
              await bot.deleteMessage(chatId, loadingMessage.message_id);
              return bot.sendMessage(chatId, "⚠️ *Gagal mendapatkan video tanpa watermark!*", { reply_to_message_id: messageId, parse_mode: "Markdown" });
          }
          await bot.sendVideo(chatId, video.url, { caption, reply_to_message_id: messageId, parse_mode: "Markdown" });
      }
      
      await bot.deleteMessage(chatId, loadingMessage.message_id);
  } catch (err) {
      if (loadingMessage) await bot.deleteMessage(chatId, loadingMessage.message_id);
      console.error("Error saat mengunduh TikTok:", err);
      bot.sendMessage(chatId, `❌ *Gagal mengambil video:*\n\n${err.toString()}`, { parse_mode: "Markdown", reply_to_message_id: messageId });
  }
}

function parseSecs(s) {
  if (typeof s === "number") return s;
  if (!s || typeof s !== "string") return 0;
  return s
    .split(":")
    .map(n => parseInt(n, 10))
    .reduce((a, v) => a * 60 + v, 0);
}

async function topVideos(q) {
  const r = await yts.search(q);
  const list = Array.isArray(r) ? r : (r.videos || []);
  return list
    .filter(v => {
      const sec = typeof v.seconds === "number"
        ? v.seconds
        : parseSecs(v.timestamp || v.duration?.timestamp || v.duration);
      return !v.live && sec > 0 && sec <= 1200;
    })
    .slice(0, 5)
    .map(v => ({
      url: v.url,
      title: v.title,
      author: (v.author && (v.author.name || v.author)) || "YouTube"
    }));
}

async function downloadToTemp(url, ext = ".bin") {
  const file = path.join(
    os.tmpdir(),
    `xayz_${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`
  );

  const res = await axios.get(url, {
    responseType: "stream",
    timeout: 180000,
    maxRedirects: 5,
    headers: {
      "User-Agent": "Mozilla/5.0",
      "Accept": "*/*"
    },
    validateStatus: s => s >= 200 && s < 400
  });

  await new Promise((resolve, reject) => {
    const w = fs.createWriteStream(file);
    res.data.pipe(w);
    w.on("finish", resolve);
    w.on("error", reject);
  });

  return file;
}

function cleanup(f) {
  try { fs.unlinkSync(f) } catch {}
}

function normalizeYouTubeUrl(raw) {
  if (!raw || typeof raw !== "string") return "";
  let u = raw.trim();
  const shortsMatch = u.match(/(?:youtube\.com\/shorts\/|youtu\.be\/shorts\/)([A-Za-z0-9_\-]+)/i);
  if (shortsMatch && shortsMatch[1]) {
    return `https://www.youtube.com/watch?v=${shortsMatch[1]}`;
  }
  const youtuMatch = u.match(/^https?:\/\/youtu\.be\/([A-Za-z0-9_\-]+)/i);
  if (youtuMatch && youtuMatch[1]) {
    return `https://www.youtube.com/watch?v=${youtuMatch[1]}`;
  }
  const watchMatch = u.match(/v=([A-Za-z0-9_\-]+)/i);
  if (watchMatch && watchMatch[1]) {
    return `https://www.youtube.com/watch?v=${watchMatch[1]}`;
  }
  return u;
}

async function fail(chatId, replyId, tag, err) {
  const name = err?.name || "";
  const code = err?.code || "";
  const status = err?.response?.status || "";
  const statusText = err?.response?.statusText || "";
  const msg = err?.message || (typeof err === "string" ? err : "");
  const apiMsg = typeof err?.response?.data === "string"
    ? err.response.data.slice(0, 300)
    : JSON.stringify(err?.response?.data || {}, null, 0).slice(0, 300);

  return bot.sendMessage(
    chatId,
    `${tag}\n• Nama: ${name}\n• Kode: ${code}\n• Status: ${status} ${statusText}\n• Pesan: ${msg}\n• Isi: ${apiMsg}`,
    { reply_to_message_id: replyId }
  );
}

async function downloadYtMusic(q, chatId, messageId) {
  try {
    await bot.sendChatAction(chatId, "typing");

    const isLink = /^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\//i.test(q);
    const candidates = isLink
      ? [{ url: q, title: q }]
      : await topVideos(q);

    if (!candidates.length) {
      return bot.sendMessage(
        chatId,
        "Tidak ada hasil",
        { reply_to_message_id: messageId }
      );
    }

    const c = candidates[0];
    const ytUrl = normalizeYouTubeUrl(c.url || "");

    if (!/^https?:\/\/(www\.)?youtube\.com\/watch\?v=/i.test(ytUrl)) {
      return bot.sendMessage(
        chatId,
        "Hasil teratas bukan video YouTube valid",
        { reply_to_message_id: messageId }
      );
    }

    const params = new URLSearchParams({
      url: ytUrl,
      format: "mp3",
      quality: "128",
      type: "audio"
    });
    const apiUrl = config.YTMUSIC_API_URL + "?" + params.toString();

    const r = await axios.get(apiUrl, {
      timeout: 1200000,
      validateStatus: () => true
    });

    const body = r.data;

    if (r.status === 200 && body?.success === true && body.result?.downloadUrl) {
      const titleFromApi = body.result.title || c.title || "YouTube";
      const audioUrl = body.result.downloadUrl;
      const file = await downloadToTemp(audioUrl, ".mp3");

      try {
        await bot.sendAudio(chatId, file, {
          caption: `🎧 ${titleFromApi}`,
          title: titleFromApi,
          performer: "Xayz (Ai) System",
          reply_to_message_id: messageId,
          thumbnail: body.result.cover
            ? body.result.cover 
            : undefined
        });
      } finally {
        cleanup(file);
      }
      return;
    }

    let apiMsg = "";
    try {
      apiMsg = JSON.stringify(body || {}).slice(0, 200);
    } catch (_) {}

    return bot.sendMessage(
      chatId,
      `Server error (${r.status} ${r.statusText || ""})\n• Api: ${apiMsg}`,
      { reply_to_message_id: messageId }
    );
  } catch (e) {
    await fail(chatId, messageId, "Proses Play gagal", e);
  }
}

async function downloadSpotify(query, chatId, messageId) {
  if (!config.SPOTIFY_API_KEY) {
    return bot.sendMessage(chatId, "Fitur Spotify tidak aktif. System Key tidak diatur.", { reply_to_message_id: messageId });
  }
  
  const proses_msg = await bot.sendMessage(chatId, "🔎 Mencari lagu di Spotify...", { reply_to_message_id: messageId });
  
  try {
    const searchUrl = `${config.SPOTIFY_SEARCH_URL}?query=${encodeURIComponent(query)}&apikey=${config.SPOTIFY_API_KEY}`;
    const search_response = await axios.get(searchUrl);

    if (!search_response.data?.status || !search_response.data.result?.status) {
      return await bot.editMessageText("Gagal mencari lagu.", { chat_id: chatId, message_id: proses_msg.message_id });
    }
    
    const tracks = search_response.data.result.data;
    if (!tracks || tracks.length === 0) {
      return await bot.editMessageText("Tidak ditemukan hasil untuk pencarian tersebut.", { chat_id: chatId, message_id: proses_msg.message_id });
    }
    
    const track_url = tracks[0].url;
    
    await bot.editMessageText("📥 Mengunduh lagu dari Spotify...", { chat_id: chatId, message_id: proses_msg.message_id });
    
    const download_url = `${config.SPOTIFY_DOWNLOAD_URL}?url=${track_url}&apikey=${config.SPOTIFY_API_KEY}`;
    const download_response = await axios.get(download_url);
    
    if (!download_response.data?.status) {
      return await bot.editMessageText("Gagal mengunduh lagu.", { chat_id: chatId, message_id: proses_msg.message_id });
    }
    
    const data = download_response.data.result.data;
    const file_url = data.url;
    const track_title = data.title;
    const track_duration = data.duration;
    const artist_name = data.artist.name;
    const spotify_url = data.artist.external_urls.spotify;
    
    const audio_file = await downloadToTemp(file_url, ".mp3");

    const caption = `🎵 <b>${track_title}</b>\n` +
                    `👤 Artis: ${artist_name}\n` +
                    `⏳ Durasi: ${track_duration}\n` +
                    `🔗 <a href='${spotify_url}'>Dengarkan di Spotify</a>`;
    
    await bot.sendAudio(chatId, audio_file, {
      caption: caption,
      parse_mode: 'HTML',
      title: track_title,
      performer: artist_name,
      reply_to_message_id: messageId
    });
    
    cleanup(audio_file);
    await bot.deleteMessage(chatId, proses_msg.message_id);

  } catch (error) {
    console.error("Spotify Error:", error);
    await bot.editMessageText("❌ Gagal mengunduh lagu Spotify. " + (error.message || ""), { chat_id: chatId, message_id: proses_msg.message_id });
  }
}

async function callGeminiAPI(chatId, promptText, photoBuffer = null, fileContent = null, messageId = null) {
  try {
    let history = chatHistories.get(chatId);
    if (!history) {
      history = model.startChat({ history: [] });
      chatHistories.set(chatId, history);
    }

    const parts = [];
    let finalPrompt = promptText;

    if (fileContent) {
      finalPrompt = `[KONTEKS FILE YANG DI-REPLY]:\n\`\`\`\n${fileContent}\n\`\`\`\n\n[PROMPT PENGGUNA]:\n${promptText}`;
    }
    parts.push({ text: finalPrompt });

    if (photoBuffer) {
      parts.unshift({
        inlineData: {
          data: photoBuffer.toString('base64'),
          mimeType: 'image/jpeg',
        },
      });
    }

    const result = await history.sendMessage(parts);
    const responseText = await result.response.text();

    if (responseText.startsWith('[GENERATE_IMAGE:')) {
      const imagePrompt = responseText.replace('[GENERATE_IMAGE:', '').replace(']', '').trim();
      await generateImage(chatId, imagePrompt, messageId);
      
    } else if (responseText.startsWith('[ENHANCE_IMAGE]')) {
      if (!photoBuffer) {
        await bot.sendMessage(chatId, "Tolong kirimkan atau reply gambar yang ingin Anda perjelas.", { reply_to_message_id: messageId });
        return;
      }
      await enhanceImage(photoBuffer, chatId, messageId);

    } else if (responseText.startsWith('[PLAY_MUSIC:')) {
      const query = responseText.replace('[PLAY_MUSIC:', '').replace(']', '').trim();
      await downloadYtMusic(query, chatId, messageId);
        
     } else if (responseText.startsWith('[PLAY_MUSIC_SPOTIFY:')) {
      const query = responseText.replace('[PLAY_MUSIC_SPOTIFY:', '').replace(']', '').trim();
      await downloadSpotify(query, chatId, messageId);

    } else if (responseText.startsWith('[WRITE_TO_BOOK:')) {
      const text = responseText.replace('[WRITE_TO_BOOK:', '').replace(']', '').trim();
      await writeToBook(chatId, text, messageId);

    } else {
      await sendSplitMessage(chatId, responseText);
    }

  } catch (error) {
    console.error("Error saat memanggil System:", error);
    await bot.sendMessage(chatId, "Maaf, terjadi kesalahan saat memproses permintaan Anda.");
  }
}

bot.on('new_chat_members', (msg) => {
  const chatId = msg.chat.id;
  if (msg.chat.type === 'group' || msg.chat.type === 'supergroup') {
    msg.new_chat_members.forEach((member) => {
      bot.getMe().then((botInfo) => {
        if (member.id === botInfo.id) {
          addGroupId(chatId);
        }
      });
    });
  }
});

bot.on('photo', async (msg) => {
  const chatId = msg.chat.id;
  const caption = msg.caption || "";

  if (msg.chat.type === 'private') {
    const triggerWord = config.NAKED_KEYWORDS.find(word => caption.toLowerCase().includes(word));
    
    if (triggerWord) {
      const status = await bot.sendMessage(chatId, "Mendeteksi kata kunci, memproses...");
      try {
        const fileId = msg.photo[msg.photo.length - 1].file_id;
        const buffer = await getPhotoBuffer(fileId);
        if (!buffer) throw new Error("Gagal mengambil buffer");

        await bot.editMessageText("Mengunggah ke Catbox...", { chat_id: chatId, message_id: status.message_id });
        const catboxUrl = await uploadToCatbox(buffer);
        if (!catboxUrl) throw new Error("Gagal mengunggah ke Catbox");
        
        await bot.deleteMessage(chatId, status.message_id);
        const senderName = msg.from.first_name;
        await processNakedImage(chatId, catboxUrl, senderName);
      } catch (e) {
        console.error(e);
        await bot.editMessageText(e.message || "Terjadi kesalahan", { chat_id: chatId, message_id: status.message_id });
      }
    } else {
      const prompt = caption || "Tolong jelaskan gambar ini.";
      const fileId = msg.photo[msg.photo.length - 1].file_id;
      
      const photoBuffer = await getPhotoBuffer(fileId);
      if (photoBuffer) {
        await callGeminiAPI(chatId, prompt, photoBuffer, null, msg.message_id);
      } else {
        await bot.sendMessage(chatId, "Gagal memproses gambar untuk System.");
      }
    }
  }
});

bot.on('text', async (msg) => {
  const chatId = msg.chat.id;
  const text = msg.text;

  if (msg.chat.type === 'private' && !text.startsWith('/')) {
    
    if (/^(https?:\/\/)?(www\.|vm\.|vt\.)?tiktok\.com\/.+/.test(text)) {
      await handleTikTok(text, chatId, msg.message_id);
      return;
    }

    const repliedMsg = msg.reply_to_message;
    let photoBuffer = null;
    let fileContent = null; 
    const prompt = msg.text;

    if (repliedMsg) {
      if (repliedMsg.photo) {
        const fileId = repliedMsg.photo[repliedMsg.photo.length - 1].file_id;
        photoBuffer = await getPhotoBuffer(fileId);
      }
      
    }
    
    await callGeminiAPI(chatId, prompt, photoBuffer, fileContent, msg.message_id);
  }
});

bot.onText(/\/ai(.+)?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const chatType = msg.chat.type;
  const promptText = match[1] ? match[1].trim() : (msg.caption || "");

  if (!promptText) {
    return bot.sendMessage(chatId, "Gunakan /ai <pertanyaan> atau reply file/foto dengan /ai <pertanyaan>.", { reply_to_message_id: msg.message_id });
  }

  if (chatType === 'group' || chatType === 'supergroup') {
    addGroupId(chatId);
  }

  const repliedMsg = msg.reply_to_message;
  let photoBuffer = null;
  let fileContent = null;

  if (repliedMsg) {
    if (repliedMsg.photo) {
      const photoFileId = repliedMsg.photo[repliedMsg.photo.length - 1].file_id;
      photoBuffer = await getPhotoBuffer(photoFileId);
    } else if (repliedMsg.document) {
      const doc = repliedMsg.document;
      const result = await getFileContent(doc.file_id, doc.mime_type);
      if (result.content) {
        fileContent = result.content;
      } else {
        await bot.sendMessage(chatId, `❌ ${result.error}`, { reply_to_message_id: msg.message_id });
        return;
      }
    }
  }

  await callGeminiAPI(chatId, promptText, photoBuffer, fileContent, msg.message_id);
});


bot.onText(/\/gambar(.+)?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const chatType = msg.chat.type;
  const prompt = match[1] ? match[1].trim() : "";

  if (chatType === 'group' || chatType === 'supergroup') {
    if (!prompt) {
      await bot.sendMessage(chatId, "Gunakan format /gambar <deskripsi gambar yang Anda inginkan>.");
      return;
    }
    await generateImage(chatId, prompt, msg.message_id);

  } else if (chatType === 'private') {
    await bot.sendMessage(chatId, "Di chat pribadi, Anda tidak perlu menggunakan perintah /gambar. Cukup ketik permintaan Anda seperti:\n\n'Buatkan gambar kucing terbang'");
  }
});

bot.onText(/\/nulis(?:\s+(.+))?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const text = match[1];
  
  if (msg.chat.type === 'private') {
     await bot.sendMessage(chatId, "Di chat pribadi, Anda tidak perlu menggunakan perintah. Cukup ketik 'Tolong nulis...'");
     return;
  }
  
  if (!text) {
    return bot.sendMessage(chatId, "Mau nulis apa? Contoh:\n/nulis aku sayang kamu");
  }
  
  await writeToBook(chatId, text, msg.message_id);
});

bot.onText(/\/webtoapk(?:\s+(.+))?/, async (msg, match) => {
  const chatId = msg.chat.id;
  const argsText = match[1];
  
  if (!argsText) {
    return bot.sendMessage(chatId, "Format salah. Gunakan:\n`/webtoapk <url> <namaApp> <email>`\n\nContoh:\n`/webtoapk https://google.com Google mail@gmail.com`\n\nAnda *harus* me-reply foto untuk dijadikan ikon.", { parse_mode: 'Markdown', reply_to_message_id: msg.message_id });
  }
  
  const args = argsText.split(' ');
  if (args.length < 3) {
    return bot.sendMessage(chatId, "Argumen tidak lengkap. Butuh URL, Nama Aplikasi, dan Email.", { reply_to_message_id: msg.message_id });
  }

  if (!msg.reply_to_message || !msg.reply_to_message.photo) {
    return bot.sendMessage(chatId, 'Anda harus me-reply sebuah foto untuk dijadikan ikon APK!', { reply_to_message_id: msg.message_id });
  }

  const [url, appName, email] = args;
  
  try { new URL(url); } catch { return bot.sendMessage(chatId, 'URL tidak valid. Pastikan dimulai dengan http:// atau https://', { reply_to_message_id: msg.message_id }); }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return bot.sendMessage(chatId, 'Email tidak valid', { reply_to_message_id: msg.message_id });

  let photoBuffer = null;
  try {
    const photo = msg.reply_to_message.photo.pop();
    photoBuffer = await getPhotoBuffer(photo.file_id);
  } catch (e) {
    return bot.sendMessage(chatId, 'Gagal mengambil foto yang di-reply.', { reply_to_message_id: msg.message_id });
  }

  await buildApk(chatId, url, appName, email, msg.message_id, photoBuffer);
});

bot.onText(/^\/tonaked(?:\s+([\s\S]+))?/i, async (msg, match) => {
  const chatId = msg.chat.id;
  const chatType = msg.chat.type;
  const senderName = msg.from.first_name;
  const urlArg = match[1] ? match[1].trim() : "";
  const repliedMsg = msg.reply_to_message;

  let finalImageUrl = urlArg || null;

  try {
    if (urlArg) {
      finalImageUrl = urlArg;
    
    } else if (repliedMsg && repliedMsg.photo) {
      const status = await bot.sendMessage(chatId, "Mengambil buffer gambar...", { reply_to_message_id: msg.message_id });
      
      const fileId = repliedMsg.photo[repliedMsg.photo.length - 1].file_id;
      const buffer = await getPhotoBuffer(fileId);
      if (!buffer) {
        await bot.editMessageText("Gagal mengambil buffer.", { chat_id: chatId, message_id: status.message_id });
        return;
      }

      await bot.editMessageText("Mengunggah ke Catbox...", { chat_id: chatId, message_id: status.message_id });
      const catboxUrl = await uploadToCatbox(buffer);
      if (!catboxUrl) {
        await bot.editMessageText("Gagal mengunggah ke Catbox.", { chat_id: chatId, message_id: status.message_id });
        return;
      }

      await bot.deleteMessage(chatId, status.message_id);
      finalImageUrl = catboxUrl;
    
    } else {
      let errorMsg = "Balas ke foto atau sertakan URL gambar setelah perintah /tonaked.";
      if(chatType === 'group' || chatType === 'supergroup') {
         errorMsg = "Di grup, gunakan /tonaked sambil me-reply sebuah foto.";
      }
      return bot.sendMessage(chatId, errorMsg, { reply_to_message_id: msg.message_id });
    }

    if (finalImageUrl) {
      await processNakedImage(chatId, finalImageUrl, senderName);
    }

  } catch (e) {
    console.error(e);
    await bot.sendMessage(chatId, "Terjadi kesalahan internal saat memproses permintaan Anda.");
  }
});

bot.onText(/^\/hd$/, async (msg) => {
  const chatId = msg.chat.id;
  const chatType = msg.chat.type;
  
  if (chatType === 'private') {
    await bot.sendMessage(chatId, "Di chat pribadi, cukup kirim foto dengan caption 'perjelas' atau 'HD', atau reply foto Anda dengan 'HD-in'.", { reply_to_message_id: msg.message_id });
    return;
  }

  if (chatType === 'group' || chatType === 'supergroup') {
    const repliedMsg = msg.reply_to_message;

    if (!repliedMsg || !repliedMsg.photo) {
      await bot.sendMessage(chatId, "Gunakan /hd sambil me-reply sebuah foto.", { reply_to_message_id: msg.message_id });
      return;
    }

    try {
      const fileId = repliedMsg.photo[repliedMsg.photo.length - 1].file_id;
      const buffer = await getPhotoBuffer(fileId);
      
      if (buffer) {
        await enhanceImage(buffer, chatId, msg.message_id);
      } else {
        await bot.sendMessage(chatId, "Gagal mengambil buffer foto yang di-reply.", { reply_to_message_id: msg.message_id });
      }
    } catch (e) {
      console.error(e);
      await bot.sendMessage(chatId, "Terjadi kesalahan saat memproses gambar.", { reply_to_message_id: msg.message_id });
    }
  }
});

bot.onText(/^\/(tiktok|tt) (.+)/, async (msg, match) => {
    const chatId = msg.chat.id;
    const chatType = msg.chat.type;
    const url = match[2];

    if (chatType === 'group' || chatType === 'supergroup') {
      if (!/^(https?:\/\/)?(www\.|vm\.|vt\.)?tiktok\.com\/.+/.test(url)) {
          return bot.sendMessage(chatId, "⚠️ *URL TikTok tidak valid!*", { parse_mode: "Markdown" });
      }
      await handleTikTok(url, chatId, msg.message_id);
    }
});

bot.onText(/^\/ytmusic (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const chatType = msg.chat.type;
  const query = match[1];

  if (chatType === 'group' || chatType === 'supergroup') {
    await downloadYtMusic(query, chatId, msg.message_id);
  } else {
     await bot.sendMessage(chatId, "Di chat pribadi, Anda tidak perlu menggunakan perintah. Cukup ketik 'Putar lagu...'", { reply_to_message_id: msg.message_id });
  }
});

bot.onText(/^\/spotify (.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const chatType = msg.chat.type;
  const query = match[1];

  if (chatType === 'group' || chatType === 'supergroup') {
    await downloadSpotify(query, chatId, msg.message_id);
  } else {
     await bot.sendMessage(chatId, "Di chat pribadi, Anda tidak perlu menggunakan perintah. Cukup ketik 'Putarkan lagu Spotify'", { reply_to_message_id: msg.message_id });
  }
});

bot.on('polling_error', (error) => {
  console.error(`Polling error: ${error.code} - ${error.message}`);
});

console.log("Bot Ai Activate ✓\n Created And Developer By: @XYCoolcraft");
EOF

# 6. Install Dependency
echo -e "${GREEN}[+] Menginstall dependency (npm install)...${NC}"
echo -e "${YELLOW}Ini mungkin memakan waktu beberapa menit tergantung koneksi internet...${NC}"

# Cek apakah nodejs terinstall
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}[!] NodeJS belum terinstall. Menginstall NodeJS dan NPM...${NC}"
    sudo apt-get update
    sudo apt-get install -y nodejs npm
fi

# Cek apakah screen terinstall
if ! command -v screen &> /dev/null; then
    echo -e "${YELLOW}[!] Screen belum terinstall. Menginstall Screen...${NC}"
    sudo apt-get install -y screen
fi

npm install

# 7. Menjalankan Bot dengan Screen
echo -e "${GREEN}[+] Menjalankan bot di dalam Screen session 'xayzbot'...${NC}"

# Matikan sesi sebelumnya jika ada
screen -S xayzbot -X quit 2>/dev/null

# Jalankan sesi baru
screen -S xayzbot node index.js

echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}   SUKSES! BOT SEDANG BERJALAN DI LATAR BELAKANG    ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Untuk melihat log bot, ketik: ${YELLOW}screen -r xayzbot${NC}"
echo -e "Untuk keluar dari log tanpa mematikan bot, tekan: ${YELLOW}CTRL + A, lalu tekan D${NC}"
echo -e "Folder project: ${GREEN}$(pwd)${NC}"
echo ""
