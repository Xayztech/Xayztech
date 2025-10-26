#!/bin/bash

REPO_TUJUAN_URL="https://github.com/Xayztech/minecraft122.git"
SOURCE_PATH_IN_CURRENT_REPO="a4/packs"
DEST_PATH_IN_TARGET_REPO="PvPmc/packs"
TEMP_CLONE_DIR="repo-tujuan-temp"

echo "🔄 Memulai proses penyalinan..."

CURRENT_WORKSPACE_DIR=$(pwd)
SOURCE_FULL_PATH="$CURRENT_WORKSPACE_DIR/$SOURCE_PATH_IN_CURRENT_REPO"

if [ ! -d "$SOURCE_FULL_PATH" ]; then
    echo "❌ ERROR: Folder sumber tidak ditemukan di $SOURCE_FULL_PATH"
    echo "Pastikan kamu menjalankan ini dari direktori root Codespaces 'happinessad/html'."
    exit 1
fi
echo "✅ Folder sumber ditemukan: $SOURCE_PATH_IN_CURRENT_REPO"

cd .. 

rm -rf $TEMP_CLONE_DIR

echo "📥 Mengkloning repositori tujuan ($REPO_TUJUAN_URL)..."
git clone $REPO_TUJUAN_URL $TEMP_CLONE_DIR

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Gagal mengkloning repositori tujuan."
    echo "Pastikan URL benar dan repo tersebut publik (atau kamu punya akses)."
    exit 1
fi

cd $TEMP_CLONE_DIR

echo "📁 Membuat struktur direktori di tujuan: $DEST_PATH_IN_TARGET_REPO"
mkdir -p $DEST_PATH_IN_TARGET_REPO

echo "📑 Menyalin file..."
cp -rT "$SOURCE_FULL_PATH" "$DEST_PATH_IN_TARGET_REPO"

echo "✅ File berhasil disalin."

echo "🚀 Mempersiapkan untuk push ke GitHub..."

git config --global user.name "$(git log -1 --pretty=format:'%an')"
git config --global user.email "$(git log -1 --pretty=format:'%ae')"

if [ -z "$(git status --porcelain)" ]; then
    echo "👍 Tidak ada perubahan file. Repositori tujuan sudah ter-update."
    cd ..
    rm -rf $TEMP_CLONE_DIR
    echo "✨ Selesai."
    exit 0
fi

git add .

git commit -m "Menambahkan/memperbarui file di $DEST_PATH_IN_TARGET_REPO"

echo "📤 Mendorong (push) perubahan ke repositori tujuan..."
git push origin main

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Gagal melakukan push ke GitHub."
    echo "🔴 PENTING: Pastikan kamu memiliki izin TULIS (write access) ke repositori 'Xayztech/minecraft122'."
    exit 1
fi

echo "🧹 Membersihkan folder sementara..."
cd ..
rm -rf $TEMP_CLONE_DIR

echo "---"
echo "🎉 SUKSES! ---"
echo "File dari 'happinessad/html/$SOURCE_PATH_IN_CURRENT_REPO' telah disalin ke 'Xayztech/minecraft122/$DEST_PATH_IN_TARGET_REPO'."
