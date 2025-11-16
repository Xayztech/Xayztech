const fs = require("fs");
const path = require("path");

const FILE_SIZE = 25 * 1024 * 1024 * 1024; // 25 GB
const TARGET_SIZE = 999 * 1024 ** 4;       // 999 TB
const BLOCK_SIZE = 1024 * 1024;            // 1 MB per write

function formatSize(bytes) {
  const gb = (bytes / 1024 ** 3).toFixed(2);
  return `${gb} GB`;
}

async function createFile(filePath, size) {
  return new Promise((resolve, reject) => {
    const stream = fs.createWriteStream(filePath, { highWaterMark: BLOCK_SIZE });
    const buf = Buffer.alloc(BLOCK_SIZE, 0);
    let written = 0;

    function writeMore() {
      let ok = true;
      while (ok && written < size) {
        const remaining = size - written;
        const chunk = remaining >= BLOCK_SIZE ? buf : buf.subarray(0, remaining);
        ok = stream.write(chunk);
        written += chunk.length;

        // tampilkan progress
        const percent = ((written / size) * 100).toFixed(2);
        process.stdout.write(
          `\r📂 Writing ${path.basename(filePath)}: ${percent}% (${formatSize(written)} dari ${formatSize(size)})`
        );
      }
      if (written >= size) {
        stream.end();
      }
    }

    stream.on("drain", writeMore);
    stream.on("error", reject);
    stream.on("finish", () => {
      process.stdout.write("\n"); // newline setelah selesai
      console.log(`✅ Selesai bikin ${filePath} (${formatSize(size)})`);
      resolve();
    });

    writeMore();
  });
}

(async () => {
  let totalWritten = 0;
  let fileIndex = 1;

  while (totalWritten < TARGET_SIZE) {
    const filePath = path.join(__dirname, `file_${fileIndex}XayzTech.bin`);
    await createFile(filePath, FILE_SIZE);
    totalWritten += FILE_SIZE;
    fileIndex++;

    console.log(
      `📊 Total progress: ${(totalWritten / 1024 ** 4).toFixed(2)} TB dari 999 TB`
    );
  }

  console.log("🎉 Semua file selesai dibuat!");
})();
