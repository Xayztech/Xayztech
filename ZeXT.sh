#!/bin/bash

# --- KONFIGURASI ---
FILE_ID="1ZeFXIA2nRcU-TkDU4jT-N_VBSDgbKpZU"
FILENAME="pinoo-litex.zip"
TARGET_DIR="${GITHUB_WORKSPACE:-$(pwd)}"

# --- FUNGSI UI ---
draw_progress_bar() {
    local percent=$1
    local process_name=$2
    local status=$3
    local bar_size=40 
    local filled_len=$(( (percent * bar_size) / 100 ))
    local empty_len=$(( bar_size - filled_len ))
    local bar_filled=$(printf "%0.s█" $(seq 1 $filled_len))
    local bar_empty=$(printf "%0.s░" $(seq 1 $empty_len))
    
    printf "\n\033[1;36m(%s)\033[0m\n" "$process_name"
    printf "\033[1;33m(%s)\033[0m\n" "$status"
    printf "\r[%s%s] %d%%" "$bar_filled" "$bar_empty" "$percent"
    printf "\n\033[3A" 
}

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
echo "=========================================="
echo "   AUTO EXTRACTOR FOR GITHUB CODESPACES   "
echo "   Target: $TARGET_DIR"
echo "=========================================="
echo ""

# 1. DOWNLOAD
printf "\033[1;36m(DOWNLOAD PROSES)\033[0m\n"
printf "\033[1;33m(Menghubungkan ke Google Drive...)\033[0m\n"

CONFIRM=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$FILE_ID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')
wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$CONFIRM&id=$FILE_ID" -O "$FILENAME" > /dev/null 2>&1 &

PID=$!
show_spinner $PID
wait $PID
rm -f /tmp/cookies.txt

printf "\n\n\n"
draw_progress_bar 100 "DOWNLOAD PROSES" "Selesai mendownload data."
echo "" 
echo ""

# 2. EKSTRAK
if [ -f "$FILENAME" ]; then
    unzip -q -o "$FILENAME" -d "$TARGET_DIR" &
    PID_UNZIP=$!
    
    for i in {1..100}; do
        if ! ps -p $PID_UNZIP > /dev/null; then
            draw_progress_bar 100 "EKSTRAKSI FILE" "Finalizing..."
            break
        fi
        draw_progress_bar $i "EKSTRAKSI FILE" "Mengekstrak ke Repository..."
        sleep 0.05
    done
    wait $PID_UNZIP
    
    echo ""
    echo ""
    draw_progress_bar 100 "EKSTRAKSI FILE" "Ekstraksi Selesai!"
    echo ""
    echo ""

    # 3. BERSIH-BERSIH
    rm "$FILENAME"
    echo -e "\n\033[1;32m[SUKSES] File zip dihapus & repository siap digunakan.\033[0m"
else
    echo -e "\n\033[1;31m[ERROR] Gagal download.\033[0m"
fi
