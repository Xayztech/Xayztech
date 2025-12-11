const https = require('https');
const vm = require('vm');
const crypto = require('crypto');
const readlineSync = require('readline-sync');

const SERVERS = {
  '1': {
    name: 'Server 1 Kill Panel [ON]',
    url: 'https://xayztech.vercel.app/XayzV1.js'
  },
  '2': {
    name: 'Server 2 Kill Panel [ON]',
    url: 'https://xayzsecure.vercel.com/XayzV2.js'
  }
};

function createHash(data) {
    return crypto.createHash('sha256').update(data).digest('hex');
}

function fetchData(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(new Error('Eror: File nya gak bisa!'));
                }
            });
        }).on('error', (err) => {
            reject(new Error(`Eror: ${err.message}`));
        });
    });
}

async function validasiInteraktif() {
    console.log('Memulai menjalankan...');
    
    const xayzTechVX = 'https://xayzsecure.vercel.app/Xayzprotech.json';

    let authorizedUsers;
    try {
        console.log('Mengambil data warga...');
        authorizedUsers = await fetchData(xayzTechVX);
        if (!Array.isArray(authorizedUsers)) {
            throw new Error('Format tidak valid dan tidak sesuai.');
        }
    } catch (error) {
        throw new Error(`Gagal mengambil data: ${error.message}`);
    }
    console.log('Masukkan Username nya');
    const username = readlineSync.question('Username: ');
    const pengguna = authorizedUsers.find(u => u.username === username);
    if (!pengguna) {
        throw new Error('Username tidak ditemukan.');
    }
    console.log('Masukkan Password nya');
    const password = readlineSync.question('Password: ', {
        hideEchoBack: true
    });
    const localPassHash = createHash(password);
    if (pengguna.password_hash !== localPassHash) {
        throw new Error('Password salah.');
    }
    if (pengguna.active !== true) {
        throw new Error('Akun ini tidak aktif. Silakan hubungi admin @XYCoolcraft (TELEGRAM).');
    }
    console.log(`\nBerhasil: Selamat datang, ${pengguna.username} yang suka ngewe!`);
    return true;
}


function fetchAndRun(scriptUrl) {
  console.log(`Menghubungkan Server.....`);
  https.get(scriptUrl, (res) => {
    let scriptContent = '';
    if (res.statusCode !== 200) {
      console.error(`Gagal Membaca Server. Status: ${res.statusCode} ${res.statusMessage}`);
      return;
    }
    res.on('data', (chunk) => {
      scriptContent += chunk;
    });
    res.on('end', () => {
      try {
        console.log('Server Berhasil Terhubung..., Menjalankan....');
        const scriptContext = {
          require: require, console: console, process: process,
          __dirname: __dirname, __filename: __filename, Buffer: Buffer,
          setTimeout: setTimeout, setInterval: setInterval, setImmediate: setImmediate,
          clearTimeout: clearTimeout, clearInterval: clearInterval, clearImmediate: clearImmediate
        };
        vm.runInNewContext(scriptContent, scriptContext);
      } catch (error) {
        console.error('Terjadi error saat menjalankan server:');
        console.error(error.message);
        console.error(error.stack);
      }
    });
  }).on('error', (err) => {
    console.error('Gagal terhubung ke Server:');
    console.error(err.message);
  });
}

function showMenuAndGetChoice() {
  console.log('=================================');
  console.log('🔥 Silakan Pilih Server 🔥');
  console.log('=================================');
  for (const key in SERVERS) {
    console.log(` ${key}. ${SERVERS[key].name}`);
  }
  console.log('=================================');
  
  const choice = readlineSync.question('Masukkan pilihan (misal: 1): ');
  const selectedServer = SERVERS[choice];

  if (selectedServer) {
    console.log(`Pilihan: ${selectedServer.name}`);
    return selectedServer.url;
  } else {
    throw new Error('Pilihan tidak valid. Keluar.');
  }
}

async function main() {
    try {
        await validasiInteraktif();
        
        const selectedUrl = showMenuAndGetChoice();
        
        fetchAndRun(selectedUrl);

    } catch (error) {
        console.error('===================================');
        console.error(`EROR: ${error.message}`);
        console.error('===================================');
        process.exit(1); 
    }
}

main();
