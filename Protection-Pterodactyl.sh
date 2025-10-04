#!/bin/bash
# --- Variabel Warna & Direktori ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
PANEL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/root/pterodactyl_backups"

# --- Fungsi untuk Menampilkan Judul ---
display_title() {
    echo -e "${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}       POWERED BY XΛYZ ƬΣCΉ                      ${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# --- Fungsi untuk Backup ---
backup_files() {
    echo -e "${C_YELLOW}Memulai proses backup direktori panel...${C_RESET}"
    mkdir -p "$BACKUP_DIR"
    FILENAME="$BACKUP_DIR/panel_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    if tar -czvf "$FILENAME" -C "$(dirname "$PANEL_DIR")" "$(basename "$PANEL_DIR")" > /dev/null 2>&1; then
        echo -e "${C_GREEN}✔ Backup berhasil dibuat di:${C_RESET} ${C_CYAN}$FILENAME${C_RESET}"
        return 0
    else
        echo -e "${C_RED}✘ Gagal membuat backup. Proses dibatalkan.${C_RESET}"
        return 1
    fi
}

# --- FUNGSI BARU: Untuk Melepas Fitur / Restore ---
uninstall_features() {
    echo -e "\n${C_YELLOW}===== Memulai Proses Melepas Fitur (Restore Panel) =====${C_RESET}"
    echo -e "${C_RED}${C_BOLD}PERINGATAN: Operasi ini akan menghapus semua file panel saat ini${C_RESET}"
    echo -e "${C_RED}${C_BOLD}dan menggantinya dengan file dari backup yang Anda pilih.${C_RESET}\n"

    # Cek apakah ada backup
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        echo -e "${C_RED}Tidak ada backup yang ditemukan di direktori $BACKUP_DIR. Proses dibatalkan.${C_RESET}"
        return
    fi

    # Tampilkan daftar backup
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/panel_backup_*.tar.gz 2>/dev/null)
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${C_RED}Tidak ada file backup valid (*.tar.gz) yang ditemukan.${C_RESET}"
        return
    fi

    echo -e "${C_YELLOW}Pilih file backup yang akan dipulihkan (restore):${C_RESET}"
    for i in "${!backups[@]}"; do
        filename=$(basename "${backups[$i]}")
        echo "  ${C_CYAN}$((i+1)))${C_RESET} $filename"
    done
    echo ""

    read -p "Masukkan nomor backup pilihan Anda: " choice
    # Validasi input
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        echo -e "${C_RED}Pilihan tidak valid. Proses dibatalkan.${C_RESET}"
        return
    fi

    SELECTED_BACKUP="${backups[$((choice-1))]}"
    echo -e "Anda memilih untuk restore dari: ${C_CYAN}$(basename "$SELECTED_BACKUP")${C_RESET}"

    # Konfirmasi terakhir
    read -p "ANDA YAKIN? Ketik 'YA' untuk melanjutkan: " confirmation
    if [ "$confirmation" != "YA" ]; then
        echo -e "${C_YELLOW}Proses restore dibatalkan.${C_RESET}"
        return
    fi

    echo -e "\n${C_YELLOW}Memulai proses restore...${C_RESET}"
    echo " -> Menghapus instalasi panel saat ini..."
    rm -rf "$PANEL_DIR"
    echo " -> Mengekstrak file dari backup..."
    if tar -xzvf "$SELECTED_BACKUP" -C "$(dirname "$PANEL_DIR")"; then
        echo " -> Membersihkan cache..."
        (cd "$PANEL_DIR" && php artisan optimize:clear)
        echo -e "\n${C_GREEN}${C_BOLD}✔ RESTORE SELESAI! Panel telah kembali ke kondisi semula.${C_RESET}"
    else
        echo -e "\n${C_RED}✘ Gagal mengekstrak file backup. Panel mungkin dalam kondisi tidak stabil!${C_RESET}"
    fi
}

# --- Fungsi untuk Instalasi Fitur ---
install_features() {
    echo -e "\n${C_YELLOW}===== Memulai Pemasangan Fitur Anti Rusuh =====${C_RESET}"

    # --- MODIFIKASI: Pengecekan Backup ---
    mkdir -p "$BACKUP_DIR"
    # Cari backup yang dibuat hari ini
    LATEST_BACKUP=$(find "$BACKUP_DIR" -name "panel_backup_$(date +%Y%m%d)*.tar.gz" -print -quit)

    if [ -n "$LATEST_BACKUP" ]; then
        echo -e "${C_GREEN}Ditemukan backup untuk hari ini. Apakah Anda ingin membuat backup baru lagi?${C_RESET}"
        read -p "Jawab [y/N]: " make_new_backup
        if [[ "$make_new_backup" =~ ^[Yy]$ ]]; then
            if ! backup_files; then return 1; fi
        else
            echo -e "${C_YELLOW}OK, melewati backup dan langsung melanjutkan instalasi...${C_RESET}"
        fi
    else
        echo "Belum ada backup untuk hari ini. Menjalankan backup otomatis..."
        if ! backup_files; then return 1; fi
    fi
    # --- Akhir Modifikasi ---
    
    sleep 2
    cd "$PANEL_DIR" || { echo -e "${C_RED}Direktori $PANEL_DIR tidak ditemukan!${C_RESET}"; return 1; }
    echo -e "\n${C_BOLD}Memasang proteksi...${C_RESET}"

    # PHP Code Snippets...
    PROTECTION_CODE='if (Auth::user()->id != 1) { return redirect()->back()->withErrors(["error" => "Lu Siapa Mau Delet User Lain Tolol?!Izin Dulu Sama Id 1 Kalo Mau Delet@Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); }'
    PROTECTION_CODE_SERVER='if (Auth::user()->id != 1) { return redirect()->back()->withErrors(["error" => "Lu Siapa Mau Delet Server Lain Tolol?!Izin Dulu Sama Id 1 Kalo Mau Delet@Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); }'
    PROTECTION_CODE_VIEW='if (Auth::user()->id != 1) { abort(403, "AKSES DITOLAK"); }'
    UPDATE_USER_PROTECTION='if (Auth::user()->id != 1) { if (!empty($request->input("password"))) { return redirect()->back()->withErrors(["error" => "Anti Ubah Data User Aktif! '\''password'\'' hanya bisa diubah oleh user ID 1 @Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); } if ($user->email !== $request->input("email")) { return redirect()->back()->withErrors(["error" => "Anti Ubah Data User Aktif! '\''email'\'' hanya bisa diubah oleh user ID 1 @Protect By 𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ V1"]); } }'
    
    # Modifikasi file-file controller...
    sed -i "/public function destroy(User \$user)/a \        ${PROTECTION_CODE}" app/Http/Controllers/Admin/UserController.php
    sed -i "/public function update(UpdateUserRequest \$request, User \$user)/a \        ${UPDATE_USER_PROTECTION}" app/Http/Controllers/Admin/UserController.php
    sed -i "/public function destroy(Server \$server)/a \        ${PROTECTION_CODE_SERVER}" app/Http/Controllers/Admin/ServersController.php
    sed -i "/public function index()/a \        ${PROTECTION_CODE_VIEW}" app/Http/Controllers/Admin/NodesController.php
    sed -i "/public function index()/a \        ${PROTECTION_CODE_VIEW}" app/Http/Controllers/Admin/LocationController.php
    sed -i "/public function index(IndexFormRequest \$request)/a \        ${PROTECTION_CODE_VIEW}" app/Http/Controllers/Admin/Settings/IndexController.php
    
    echo -e "${C_GREEN}✔ Semua proteksi telah dipasang.${C_RESET}"
    
    echo -e "\n${C_BOLD}Membersihkan cache Pterodactyl${C_RESET}"
    if php artisan optimize:clear; then
        echo -e "${C_GREEN}✔ Cache berhasil dibersihkan.${C_RESET}"
    else
        echo -e "${C_RED}✘ Gagal membersihkan cache.${C_RESET}"
    fi

    echo -e "\n${C_GREEN}${C_BOLD}===== Pemasangan Selesai! Fitur Anti Rusuh sudah aktif. =====${C_RESET}"
}

# --- Fungsi Menu Utama (dengan opsi baru) ---
main_menu() {
    clear
    display_title
    echo -e "${C_YELLOW}Pilih salah satu opsi:${C_RESET}"
    echo -e "  ${C_CYAN}1)${C_RESET} Pasang Fitur Anti Rusuh"
    echo -e "  ${C_CYAN}2)${C_RESET} ${C_RED}Lepas Fitur Anti Rusuh (Restore Panel)${C_RESET}"
    echo -e "  ${C_CYAN}3)${C_RESET} Buat Backup Manual"
    echo -e "  ${C_CYAN}4)${C_RESET} Keluar"
    echo ""
    read -p "Masukkan pilihan Anda [1-4]: " choice
    case $choice in
        1) install_features ;;
        2) uninstall_features ;;
        3) backup_files ;;
        4) echo -e "${C_GREEN}Terima kasih telah menggunakan skrip ini! Sampai jumpa!${C_RESET}"; exit 0 ;;
        *) echo -e "${C_RED}Pilihan tidak valid. Silakan coba lagi.${C_RESET}" ;;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -r
}

# --- Loop Utama Skrip ---
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${C_RED}Skrip ini harus dijalankan sebagai root.${C_RESET}"
  exit 1
fi

while true; do
    main_menu
done
