#!/bin/bash

C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
PANEL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/root/pterodactyl_backups"

display_title() {
    echo -e "${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}       POWERED BY XΛYZ ƬΣCΉ                      ${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

teleport_to_v2() {
     echo -e "\n${C_BOLD} Teleport Ke Versi 2 Protection...${C_RESET}"
     bash <(curl -s https://xayztech-installasi-fitur-anti-rusuh.vercel.app/Protection-PterodactylV2.sh)
}

installadmin() {
     echo -e "\n${C_BOLD} Please Wait...${C_RESET}"
     bash <(curl -s https://xayztech-installasi-fitur-anti-rusuh.vercel.app/Protection-PterodactylV3.sh)
}

installfull() {
     echo -e "\n${C_BOLD} Memasang Full Keamanan...${C_RESET}"
     bash <(curl -s https://xayztech-installasi-fitur-anti-rusuh.vercel.app/Protection-PterodactylV2S1.sh)
}

teleport_to_v3() {
     echo -e "\n${C_BOLD} Teleport Ke Versi 3 Protection...${C_RESET}"
     bash <(curl -s https://xayztech-installasi-fitur-anti-rusuh.vercel.app/Protection-PterodactylV3.sh)
}

restart_php_fpm() {
    echo -e "\n${C_BOLD}Langkah Krusial: Merestart service PHP-FPM...${C_RESET}"
    PHP_SERVICE=$(systemctl list-units --type=service | grep -o 'php[0-9]\.[0-9]-fpm\.service' | head -n 1)
    if [ -n "$PHP_SERVICE" ]; then
        echo " -> Merestart ${C_CYAN}$PHP_SERVICE${C_RESET}..."
        if systemctl restart "$PHP_SERVICE"; then
            echo -e "${C_GREEN}✔ Service PHP-FPM berhasil direstart.${C_RESET}"
        else
            echo -e "${C_RED}✘ Gagal merestart $PHP_SERVICE.${C_RESET}"
        fi
    else
        echo -e "${C_YELLOW}⚠️ Tidak dapat mendeteksi service PHP-FPM. Jika fitur tidak aktif, restart manual (contoh: sudo systemctl restart php8.3-fpm).${C_RESET}"
    fi
}

backup_files() {
    echo -e "${C_YELLOW}Memulai proses backup...${C_RESET}"
    mkdir -p "$BACKUP_DIR"
    FILENAME="$BACKUP_DIR/panel_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    if tar -czvf "$FILENAME" -C "$(dirname "$PANEL_DIR")" "$(basename "$PANEL_DIR")" > /dev/null 2>&1; then
        echo -e "${C_GREEN}✔ Backup berhasil dibuat di: ${C_CYAN}$FILENAME${C_RESET}"
        return 0
    else
        echo -e "${C_RED}✘ Gagal membuat backup.${C_RESET}"; return 1
    fi
}

uninstall_features() {
    echo -e "\n${C_YELLOW}===== Memulai Proses Melepas Fitur (Restore Panel) =====${C_RESET}"
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/panel_backup_*.tar.gz 2>/dev/null)
    if [ ${#backups[@]} -eq 0 ]; then echo -e "${C_RED}Tidak ada file backup valid yang ditemukan.${C_RESET}"; return; fi
    echo -e "${C_YELLOW}Pilih file backup untuk dipulihkan:${C_RESET}"
    for i in "${!backups[@]}"; do echo "  ${C_CYAN}$((i+1)))${C_RESET} $(basename "${backups[$i]}")"; done
    read -p "Masukkan nomor backup pilihan Anda: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then echo -e "${C_RED}Pilihan tidak valid.${C_RESET}"; return; fi
    SELECTED_BACKUP="${backups[$((choice-1))]}"
    read -p "ANDA YAKIN ingin menimpa panel dengan backup $(basename "$SELECTED_BACKUP")? Ketik 'YA': " confirmation
    if [ "$confirmation" != "YA" ]; then echo -e "${C_YELLOW}Proses restore dibatalkan.${C_RESET}"; return; fi
    echo -e "\n${C_YELLOW}Memulai proses restore...${C_RESET}"
    rm -rf "$PANEL_DIR"
    if tar -xzvf "$SELECTED_BACKUP" -C "$(dirname "$PANEL_DIR")"; then
        (cd "$PANEL_DIR" && php artisan config:clear && php artisan view:clear && php artisan route:clear && php artisan config:cache)
        restart_php_fpm
        echo -e "\n${C_GREEN}${C_BOLD}✔ RESTORE SELESAI! Panel telah kembali normal.${C_RESET}"
    else
        echo -e "\n${C_RED}✘ Gagal mengekstrak file backup!${C_RESET}"
    fi
}

install_features() {
    echo -e "\n${C_YELLOW}===== Memasang Fitur (Metode Timpa File) =====${C_RESET}"
    if ! backup_files; then return 1; fi

    ZIP_URL="https://xayztech-installasi-fitur-anti-rusuh.vercel.app/Protection-Pterodactyl.zip"
    TMP_FILE="/tmp/Protection-Pterodactyl.zip"

    echo -e "\n${C_BOLD}Langkah 1: Mengunduh proteksi...${C_RESET}"
    if ! curl -Lo "$TMP_FILE" "$ZIP_URL"; then
        echo -e "${C_RED}✘ Gagal mengunduh dari URL. Pastikan URL benar dan server memiliki koneksi internet.${C_RESET}"
        return 1
    fi
    echo -e "${C_GREEN}✔ Berhasil diunduh.${C_RESET}"

    echo -e "\n${C_BOLD}Langkah 2: Memasang terproteksi...${C_RESET}"
    if ! unzip -o "$TMP_FILE" -d /; then
        echo -e "${C_RED}✘ Gagal mengekstrak. Pastikan 'unzip' terinstall.${C_RESET}"
        rm "$TMP_FILE"
        return 1
    fi
    echo -e "${C_GREEN}✔ Protection Berhasil Dipasang!.${C_RESET}"
    
    rm "$TMP_FILE"

    echo -e "\n${C_BOLD}Langkah 3: Membersihkan dan membangun ulang cache...${C_RESET}"
    cd "$PANEL_DIR" || { echo -e "${C_RED}Direktori $PANEL_DIR tidak ditemukan!${C_RESET}"; return 1; }
    php artisan view:clear; php artisan config:clear; php artisan route:clear; php artisan cache:clear; php artisan config:cache; php artisan route:cache;
    echo -e "${C_GREEN}✔ Cache berhasil dioptimalkan.${C_RESET}"
    
    restart_php_fpm
    
    echo -e "\n${C_GREEN}${C_BOLD}===== PEMASANGAN SELESAI! Keamanan penuh telah aktif. =====${C_RESET}"
}

main_menu() {
    clear
    display_title
    echo -e "${C_YELLOW}Pilih salah satu opsi:${C_RESET}"
    echo -e "  ${C_CYAN}1)${C_RESET} Pasang Fitur Protection ( Extra Protection ) [RECOMMENDED]"
    echo -e "  ${C_CYAN}2)${C_RESET} Pasang Full Keamanan [RECOMMENDED]"
    echo -e "  ${C_CYAN}3)${C_RESET} Pasang Admin Protection"
    echo -e "  ${C_CYAN}4)${C_RESET} Teleport (Pindah) Ke Versi 2 Protection"
    echo -e "  ${C_CYAN}5)${C_RESET} Teleport (Pindah) Ke Versi 3 Protection"
    echo -e "  ${C_CYAN}6)${C_RESET} ${C_RED}Lepas Fitur Anti Rusuh (Restore Panel)${C_RESET}"
    echo -e "  ${C_CYAN}7)${C_RESET} Buat Backup Otomatis [MUST!]"
    echo -e "  ${C_CYAN}8)${C_RESET} Keluar"
    echo ""
    read -p "Masukkan pilihan Anda [1-8]: " choice
    case $choice in
        1) install_features ;;
        2) installfull ;;
        3) installadmin ;;
        4) teleport_to_v2 ;;
        5) teleport_to_v3 ;;
        6) uninstall_features ;;
        7) backup_files ;;
        8) echo -e "${C_GREEN}Sampai jumpa!${C_RESET}"; exit 0 ;;
        *) echo -e "${C_RED}Pilihan tidak valid.${C_RESET}" ;;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -r
}

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${C_RED}Skrip ini harus dijalankan sebagai root.${C_RESET}"
  exit 1
fi
while true; do
    main_menu
done
