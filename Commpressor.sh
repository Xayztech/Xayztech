#!/bin/bash

REPO_SUMBER_URL="https://github.com/happinessad/html.git"
SOURCE_PATH_IN_REMOTE_REPO="a4/packs"
DEST_PATH_IN_CURRENT_REPO="PvPmc/packs"
TEMP_CLONE_DIR="repo-sumber-temp"

echo "🔄 Memulai proses pengambilan file..."

CURRENT_REPO_DIR=$(pwd) 

cd .. 

rm -rf $TEMP_CLONE_DIR

echo "📥 Mengkloning repositori sumber (happinessad/html)..."
git clone --depth 1 --filter=blob:none --sparse $REPO_SUMBER_URL $TEMP_CLONE_DIR
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Gagal mengkloning repositori sumber."
    exit 1
fi

cd $TEMP_CLONE_DIR
git sparse-checkout set $SOURCE_PATH_IN_REMOTE_REPO
cd ..

echo "✅ Repositori sumber berhasil dikloning."

SOURCE_FULL_PATH="$(pwd)/$TEMP_CLONE_DIR/$SOURCE_PATH_IN_REMOTE_REPO"
DEST_FULL_PATH="$CURRENT_REPO_DIR/$DEST_PATH_IN_CURRENT_REPO"

if [ ! -d "$SOURCE_FULL_PATH" ]; then
    echo "❌ ERROR: Folder sumber '$SOURCE_PATH_IN_REMOTE_REPO' tidak ditemukan di repo sumber."
    rm -rf $TEMP_CLONE_DIR
    exit 1
fi

echo "📁 Membuat struktur direktori di tujuan: $DEST_PATH_IN_CURRENT_REPO"
mkdir -p "$DEST_FULL_PATH"

echo "📑 Menyalin file..."
cp -rT "$SOURCE_FULL_PATH" "$DEST_FULL_PATH"
echo "✅ File berhasil disalin."

cd "$CURRENT_REPO_DIR"

if [ -z "$(git status --porcelain)" ]; then
    echo "👍 Tidak ada perubahan file. Repositori sudah ter-update."
else
    echo "🚀 Mempersiapkan untuk push..."
    
    git config --global user.name "$(git log -1 --pretty=format:'%an')"
    git config --global user.email "$(git log -1 --pretty=format:'%ae')"

    git add .
    git commit -m "Menambahkan/memperbarui file di $DEST_PATH_IN_CURRENT_REPO"
    
    echo "📤 Mendorong (push) perubahan ke repositori tujuan..."
    git push origin main
    
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Gagal melakukan push. (Ini seharusnya tidak terjadi jika dijalankan di Codespaces Xayztech)"
    else
        echo "✅ Perubahan telah di-push ke GitHub."
    fi
fi

echo "🧹 Membersihkan folder sementara..."
cd ..
rm -rf $TEMP_CLONE_DIR

echo "---"
echo "🎉 SUKSES! ---"
echo "File telah disalin ke repositori 'Xayztech/minecraft122'."
