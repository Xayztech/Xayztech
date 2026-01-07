#!/bin/bash

# --- KONFIGURASI ---
FILE_ID="1R01j0Is7vg1f5hDckHukzl9FFvWTTK6w"
FILENAME="xayz-litex.zip" 
TARGET_DIR="${GITHUB_WORKSPACE:-$(pwd)}"

# --- FUNGSI UI ---
draw_progress_bar() {
    local percent=$1
    local process_name=$2
    local status=$3
    local bar_size=25 
    local filled_len=$(( (percent * bar_size) / 100 ))
    local empty_len=$(( bar_size - filled_len ))
    local bar_filled=$(printf "%0.s█" $(seq 1 $filled_len))
    local bar_empty=$(printf "%0.s░" $(seq 1 $empty_len))
    
    printf "\r\033[K"
    printf "\033[1;36m(%s)\033[0m\n" "$process_name"
    printf "\r\033[K"
    printf "\033[1;33m(%s)\033[0m\n" "$status"
    printf "\r[%s%s] %d%%" "$bar_filled" "$bar_empty" "$percent"
    printf "\033[2A" 
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
echo "==================================="
echo "   AUTO EXTRACTOR & GIT PUSH       "
echo "==================================="
echo ""

# 1. PERSIAPAN (Install gdown)
if ! command -v gdown &> /dev/null; then
    printf "\033[1;36m(SYSTEM)\033[0m\n"
    printf "\033[1;33m(Menginstall modul gdown...)\033[0m\n"
    pip install gdown --quiet --no-cache-dir &
    PID_INSTALL=$!
    show_spinner $PID_INSTALL
    wait $PID_INSTALL
    echo ""
fi

# 2. DOWNLOAD 
rm -f "$FILENAME"
printf "\n\033[1;36m(DOWNLOAD PROSES)\033[0m\n"
printf "\033[1;33m(Sedang mengunduh dari GDrive...)\033[0m\n"

gdown "$FILE_ID" -O "$FILENAME" --quiet --fuzzy &

PID=$!
show_spinner $PID
wait $PID

printf "\n\n"
draw_progress_bar 100 "DOWNLOAD PROSES" "Selesai."
echo "" 
echo ""

# 3. EKSTRAK
if unzip -t "$FILENAME" > /dev/null 2>&1; then
    
    unzip -q -o "$FILENAME" -d "$TARGET_DIR" &
    PID_UNZIP=$!
    
    for i in {1..100}; do
        if ! ps -p $PID_UNZIP > /dev/null; then
            draw_progress_bar 100 "EKSTRAKSI FILE" "Finalizing..."
            break
        fi
        draw_progress_bar $i "EKSTRAKSI FILE" "Mengekstrak..."
        sleep 0.05
    done
    wait $PID_UNZIP
    
    echo ""
    echo ""
    draw_progress_bar 100 "EKSTRAKSI FILE" "Ekstraksi Selesai!"
    echo ""
    echo ""

    # 4. BERSIH-BERSIH
    rm -f "$FILENAME"
    echo -e "\n\033[1;32m[SUKSES] File zip berhasil dihapus.\033[0m"

    # --- PENAMBAHAN GIT OTOMATIS (SOLUSI PENTING) ---
    
    printf "\n\033[1;36m(GIT COMMIT & PUSH PROSES)\033[0m\n"
    printf "\033[1;33m(Menambahkan file ke Repository GitHub...)\033[0m\n"

    # Pindah ke folder repository
    cd "$TARGET_DIR"

    # Cek apakah ada file baru yang perlu ditambahkan
    if [ $(git status --porcelain | wc -l) -gt 0 ]; then
        # 4a. Add (menambahkan semua file yang diekstrak)
        git add . > /dev/null 2>&1
        # 4b. Commit
        git commit -m "Auto: Added extracted files from Google Drive" > /dev/null 2>&1
        
        # 4c. Push (mendorong ke remote/GitHub)
        printf "\n\033[1;33m(Mendorong perubahan ke GitHub...)\033[0m\n"
        git push &
        PID_PUSH=$!
        show_spinner $PID_PUSH
        wait $PID_PUSH
        
        echo -e "\n\033[1;32m[SUKSES] Semua file telah di-Push ke GitHub!\033[0m"
        echo -e "\033[1;37m$TARGET_DIR\033[0m"
    else
        echo -e "\n\033[1;34m[INFO] Tidak ada file baru yang perlu di-Push.\033[0m"
    fi
    # --------------------------------------------------

else
    echo -e "\n\033[1;31m[ERROR] File rusak atau Link Salah.\033[0m"
    rm -f "$FILENAME"
fi
