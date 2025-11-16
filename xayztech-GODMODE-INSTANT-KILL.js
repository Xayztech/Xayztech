const { Worker, isMainThread } = require('worker_threads');
const { spawn } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');

const TARGET_TB_BYTES = 999 * 1024 * 1024 * 1024 * 1024;

function runCpuStress() {
    while (true) {}
}

function runRamStress() {
    console.log('📈 [RAM-SYSTEM] Dimulai (Mode GODMODE). Dashboard RAM akan FREEZE.');
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

async function runDiskStress() {
    const TARGET_DISK_BYTES = TARGET_TB_BYTES;
    const DISK_FILE_BYTES = 40 * 1024 * 1024 * 1024;
    
    const WRITE_BLOCK_BYTES = 1 * 1024 * 1024 * 1024;

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
    console.log('WARNING: This version is brutal and causes fast OOM crash loops.');
    console.log('============================================\n');

    const { cpu, ram, disk } = dashboardStatus;

    console.log(`💻 CPU: ${cpu.cores} Cores [${cpu.status}]`);

    let ramStatus = ram.status === 'Running' ? 
        `${formatSize(ram.progress)} / 999 TB` : `[${ram.status}]`;
    console.log(`📈 RAM: ${ramStatus}`);

    let diskStatus = disk.status === 'Running' ?
        `${formatSize(disk.totalProgress)} / 999 TB  (File: ${disk.fileName} [${formatSize(disk.fileProgress)} / ${formatSize(disk.fileSize)}])` : `[${disk.status}]`;
    console.log(`💾 DISK: ${diskStatus}`);

    console.log('\n--- System Logs (Last 5) ---');
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
            logError(logPrefix, `GAGAL TULIS PADA ${formatSize(msg.progress)}: ${msg.message}`);
        }
    });

    worker.on('close', (code) => {
        logError(logPrefix, `SYSTEM BERHENTI! (Kode: ${code}). Me-restart...`);
        
        if (workerArg === '--run-ram') dashboardStatus.ram.status = 'Restarting...';
        if (workerArg === '--run-disk') dashboardStatus.disk.status = 'Restarting...';

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

if (process.argv.includes('--run-cpu')) {
    runCpuStress();
} 
else if (process.argv.includes('--run-ram')) {
    runRamStress();
} 
else if (process.argv.includes('--run-disk')) {
    runDiskStress();
} 
else {
    const numCPUs = os.cpus().length;
    dashboardStatus.cpu = { status: 'RUNNING', cores: numCPUs };
    
    setInterval(drawDashboard, 500);

    for (let i = 0; i < numCPUs; i++) {
        launchWorker('--run-cpu', `💻 [CPU-${i + 1}]`);
    }

    launchWorker('--run-ram', '📈 [RAM]');
    
    launchWorker('--run-disk', '💾 [DISK]');
}