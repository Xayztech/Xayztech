#!/bin/bash

# --- KONFIGURASI ---
FILE_ID="1ZeFXIA2nRcU-TkDU4jT-N_VBSDgbKpZU"
FILENAME="pinoo-litex.zip" # Nama file disesuaikan dengan screenshotmu
TARGET_DIR="${GITHUB_WORKSPACE:-$(pwd)}"

# --- FUNGSI UI (Disesuaikan untuk Layar HP) ---
draw_progress_bar() {
    local percent=$1
    local process_name=$2
    local status=$3
    # Saya kecilkan jadi 25 agar muat di layar Android Portrait
    local bar_size=25 
    local filled_len=$(( (percent * bar_size) / 100 ))
    local empty_len=$(( bar_size - filled_len ))
    local bar_filled=$(printf "%0.s█" $(seq 1 $filled_len))
    local bar_empty=$(printf "%0.s░" $(seq 1 $empty_len))
    
    # Clear line manual agar tidak menumpuk
    printf "\r\033[K"
    printf "\033[1;36m(%s)\033[0m\n" "$process_name"
    printf "\r\033[K"
    printf "\033[1;33m(%s)\033[0m\n" "$status"
    printf "\r[%s%s] %d%%" "$bar_filled" "$bar_empty" "$percent"
    # Pindah kursor naik 2 baris
    printf "\033[2A" 
}

# Spinner sederhana
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- MULAI ---
clear
echo ""
echo "==================================="
echo "   AUTO EXTRACTOR (GDOWN FIX)      "
echo "==================================="
echo ""

# 1. PERSIAPAN (Install gdown jika belum ada)
# Cek apakah gdown sudah terinstall
if ! command -v gdown &> /dev/null; then
    printf "\033[1;36m(SYSTEM)\033[0m\n"
    printf "\033[1;33m(Menginstall modul gdown...)\033[0m\n"
    pip install gdown --quiet --no-cache-dir &
    PID_INSTALL=$!
    show_spinner $PID_INSTALL
    wait $PID_INSTALL
    echo ""
fi

# 2. DOWNLOAD (Menggunakan gdown)
# Hapus file lama jika ada agar tidak konflik
rm -f "$FILENAME"

printf "\n\033[1;36m(DOWNLOAD PROSES)\033[0m\n"
printf "\033[1;33m(Sedang mengunduh dari GDrive...)\033[0m\n"

# Download menggunakan gdown (lebih stabil daripada wget/curl)
# Opsi --fuzzy membantu menemukan file jika link sedikit berbeda
gdown "$FILE_ID" -O "$FILENAME" --quiet --fuzzy &

PID=$!
show_spinner $PID
wait $PID

printf "\n\n"
draw_progress_bar 100 "DOWNLOAD PROSES" "Selesai."
echo "" 
echo ""

# 3. EKSTRAK
# Cek apakah file benar-benar ZIP valid
if unzip -t "$FILENAME" > /dev/null 2>&1; then
    
    # Jalankan unzip di background
    unzip -q -o "$FILENAME" -d "$TARGET_DIR" &
    PID_UNZIP=$!
    
    # Animasi Loading
    for i in {1..100}; do
        if ! ps -p $PID_UNZIP > /dev/null; then
            draw_progress_bar 100 "EKSTRAKSI FILE" "Finalizing..."
            break
        fi
        # Kecepatan loading disesuaikan agar terlihat smooth
        draw_progress_bar $i "EKSTRAKSI FILE" "Mengekstrak..."
        sleep 0.05
    done
    wait $PID_UNZIP
    
    echo ""
    echo ""
    draw_progress_bar 100 "EKSTRAKSI FILE" "Selesai!"
    echo ""
    echo ""

    # 4. BERSIH-BERSIH
    rm -f "$FILENAME"
    echo -e "\n\033[1;32m[SUKSES] Repository siap digunakan di:\033[0m"
    echo -e "\033[1;37m$TARGET_DIR\033[0m"
else
    echo -e "\n\033[1;31m[ERROR] File rusak atau Link Salah.\033[0m"
    echo "Cek apakah Link Google Drive sudah di-set ke 'Anyone with the link'?"
    # Hapus file rusak
    rm -f "$FILENAME"
fi
