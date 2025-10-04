#!/bin/bash

# --- Variabel Warna untuk Tampilan ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'

# --- Lokasi Direktori Panel ---
PANEL_DIR="/var/www/pterodactyl"

# --- Fungsi untuk Menampilkan Judul ---
display_title() {
    echo -e "${C_BOLD}${C_MAGENTA}╔══════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}       POWERED BY XΛYZ ƬΣCΉ                      ${C_RESET}"
    echo -e "${C_BOLD}${C_MAGENTA}╚══════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# --- Fungsi untuk Backup ---
backup_files() {
    echo -e "${C_YELLOW}Memulai proses backup direktori panel...${C_RESET}"
    BACKUP_DIR="/root/pterodactyl_backups"
    mkdir -p "$BACKUP_DIR"
    FILENAME="$BACKUP_DIR/panel_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    if tar -czvf "$FILENAME" -C /var/www pterodactyl > /dev/null 2>&1; then
        echo -e "${C_GREEN}✔ Backup berhasil dibuat di:${C_RESET} ${C_CYAN}$FILENAME${C_RESET}"
        return 0
    else
        echo -e "${C_RED}✘ Gagal membuat backup. Proses dibatalkan.${C_RESET}"
        return 1
    fi
}

# --- Fungsi untuk Instalasi Fitur ---
install_features() {
    echo -e "\n${C_YELLOW}===== Memulai Pemasangan Fitur Anti Rusuh =====${C_RESET}"

    # 1. Wajib Backup dulu
    echo -e "\n${C_BOLD}Langkah 1: Melakukan Backup Otomatis${C_RESET}"
    if ! backup_files; then
        return 1
    fi
    sleep 2

    # 2. Pindah ke direktori panel
    cd "$PANEL_DIR" || { echo -e "${C_RED}Direktori $PANEL_DIR tidak ditemukan!${C_RESET}"; return 1; }

    echo -e "\n${C_BOLD}Langkah 2: Memasang proteksi...${C_RESET}"

    # PHP Code Snippet
    PROTECTION_CODE='if (Auth::user()->id != 1) { return redirect()->back()->withErrors(["error" => "Lu Siapa Mau Delet User Lain Tolol?!Izin Dulu Sama Id 1 Kalo Mau Delet@Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); }'
    PROTECTION_CODE_SERVER='if (Auth::user()->id != 1) { return redirect()->back()->withErrors(["error" => "Lu Siapa Mau Delet Server Lain Tolol?!Izin Dulu Sama Id 1 Kalo Mau Delet@Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); }'
    PROTECTION_CODE_VIEW='if (Auth::user()->id != 1) { abort(403, "AKSES DITOLAK"); }'
    UPDATE_USER_PROTECTION='if (Auth::user()->id != 1) { if (!empty($request->input("password"))) { return redirect()->back()->withErrors(["error" => "Anti Ubah Data User Aktif! '\''password'\'' hanya bisa diubah oleh user ID 1 @Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); } if ($user->email !== $request->input("email")) { return redirect()->back()->withErrors(["error" => "Anti Ubah Data User Aktif! '\''email'\'' hanya bisa diubah oleh user ID 1 @Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); } }'
    
    # --- Modifikasi File-file Controller (PATH SUDAH DIPERBAIKI) ---
    
    echo " -> Memasang Anti Hapus User..."
    sed -i "/public function destroy(User \$user)/a \        ${PROTECTION_CODE}" app/Http/Controllers/Admin/UserController.php

    echo " -> Memasang Anti Ubah Data User..."
    sed -i "/public function update(UpdateUserRequest \$request, User \$user)/a \        ${UPDATE_USER_PROTECTION}" app/Http/Controllers/Admin/UserController.php

    echo " -> Memasang Anti Hapus Server..."
    # FIX: Menggunakan ServersController.php tanpa sub-folder
    sed -i "/public function destroy(Server \$server)/a \        ${PROTECTION_CODE_SERVER}" app/Http/Controllers/Admin/ServersController.php

    echo " -> Memasang Anti Intip Halaman (Nodes, Locations, Settings)..."
    # FIX: Menggunakan NodesController.php (dengan 's')
    sed -i "/public function index()/a \        ${PROTECTION_CODE_VIEW}" app/Http/Controllers/Admin/NodesController.php
    sed -i "/public function index()/a \        ${PROTECTION_CODE_VIEW}" app/Http/Controllers/Admin/LocationController.php
    sed -i "/public function index(IndexFormRequest \$request)/a \        ${PROTECTION_CODE_VIEW}" app/Http/Controllers/Admin/Settings/IndexController.php
    
    # CATATAN: Proteksi untuk Egg (NestController) tidak dapat dipasang karena direktorinya tidak terdeteksi.
    # Namun fitur proteksi utama lainnya akan tetap berfungsi.
    
    echo -e "${C_GREEN}✔ Semua proteksi telah dipasang.${C_RESET}"
    sleep 1

    # 3. Membersihkan cache
    echo -e "\n${C_BOLD}Langkah 3: Membersihkan cache Pterodactyl${C_RESET}"
    if php artisan optimize:clear; then
        echo -e "${C_GREEN}✔ Cache berhasil dibersihkan.${C_RESET}"
    else
        echo -e "${C_RED}✘ Gagal membersihkan cache. Coba jalankan manual: php artisan optimize:clear${C_RESET}"
    fi

    echo -e "\n${C_GREEN}${C_BOLD}===== Pemasangan Selesai! Fitur Anti Rusuh sudah aktif. =====${C_RESET}"
}

# --- Fungsi Menu Utama (dan sisa skripnya sama) ---
main_menu() {
    clear
    display_title
    echo -e "${C_YELLOW}Pilih salah satu opsi:${C_RESET}"
    echo -e "  ${C_CYAN}1)${C_RESET} Pasang Fitur Anti Rusuh"
    echo -e "  ${C_CYAN}2)${C_RESET} Buat Backup Manual"
    echo -e "  ${C_CYAN}3)${C_RESET} Keluar"
    echo ""
    read -p "Masukkan pilihan Anda [1-3]: " choice
    case $choice in
        1)
            install_features
            ;;
        2)
            backup_files
            ;;
        3)
            echo -e "${C_GREEN}Terima kasih telah menggunakan skrip ini! Sampai jumpa!${C_RESET}"
            exit 0
            ;;
        *)
            echo -e "${C_RED}Pilihan tidak valid. Silakan coba lagi.${C_RESET}"
            ;;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -r
}

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${C_RED}Skrip ini harus dijalankan sebagai root. Coba gunakan 'sudo bash nama_file_skrip.sh'${C_RESET}"
  exit 1
fi

while true; do
    main_menu
done
