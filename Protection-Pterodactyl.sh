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
    echo -e "\n${C_YELLOW}===== Memasang Fitur Anti Rusuh ( Protection ) V1 =====${C_RESET}"
    mkdir -p "$BACKUP_DIR"
    LATEST_BACKUP=$(find "$BACKUP_DIR" -name "panel_backup_$(date +%Y%m%d)*.tar.gz" -print -quit)
    if [ -n "$LATEST_BACKUP" ]; then
        echo -e "${C_GREEN}Ditemukan backup untuk hari ini. Lewati pembuatan backup baru?${C_RESET}"
        read -p "Jawab [Y/n]: " skip_backup
        if [[ "$skip_backup" =~ ^[Nn]$ ]]; then
            if ! backup_files; then return 1; fi
        else
            echo -e "${C_YELLOW}OK, melewati backup dan langsung melanjutkan instalasi...${C_RESET}"
        fi
    else
        echo "Belum ada backup untuk hari ini. Menjalankan backup otomatis..."
        if ! backup_files; then return 1; fi
    fi
    cd "$PANEL_DIR" || { echo -e "${C_RED}Direktori $PANEL_DIR tidak ditemukan!${C_RESET}"; return 1; }
    echo -e "\n${C_BOLD}Memasang proteksi...${C_RESET}"
    PROTECTION_CODE_DELETE_USER='if ($request->user()->id !== 1) { throw new \Pterodactyl\Exceptions\DisplayException("Lu Siapa Mau Delet User Lain Tolol?! Izin Dulu Sama Id 1 Kalo Mau Delete @Protect By XΛYZ ƬΣCΉ V1"); }'
    PROTECTION_CODE_DELETE_SERVER_SERVICE='$user = Auth::user(); if ($user && $user->id !== 1) { throw new \Pterodactyl\Exceptions\DisplayException("Lu Siapa Mau Delet Server Lain Tolol?! Izin Dulu Sama Id 1 Kalo Mau Delete @Protect By XΛYZ ƬΣCΉ V1"); }'
    PROTECTION_CODE_VIEW='$user = Auth::user(); if (!$user || $user->id != 1) { abort(403, "XΛYZ ƬΣCΉ PROTECTION - AKSES DITOLAK"); }'
    UPDATE_USER_PROTECTION='if ($request->user()->id !== 1) { $restricted = ["email", "username", "name_first", "name_last", "password", "root_admin"]; foreach ($restricted as $field) { if ($request->input($field) != $user->$field && $field != "password") { throw new \Pterodactyl\Exceptions\DisplayException("PERUBAHAN DITOLAK! Hanya user ID 1 yang dapat mengubah data sensitif pengguna."); } if ($field == "password" && !empty($request->input("password"))) { throw new \Pterodactyl\Exceptions\DisplayException("PERUBAHAN DITOLAK! Hanya user ID 1 yang dapat mengubah data sensitif pengguna."); } } }'
    ANTI_INTIP_CODE_API='$authUser = $request->user(); if ($authUser->id !== 1 && $server->owner_id !== $authUser->id) { abort(403, "𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ Protection - Ngapain ngintip? Mikir Kidz"); }'
    ANTI_DOWNLOAD_CODE_API='$authUser = $request->user(); if ($authUser->id !== 1 && $server->owner_id !== $authUser->id) { abort(403, "𝗫Λ𝗬𝗭 Ƭ̀̍Σͫ̾C̑̈Ή̐ Protection - Si Monyet Berusaha Download.. wkwkwkwkwkwk cuakzz..."); }'
    inject_code() {
        sed -i "/$2/s/{/{\n    $3/" "$1"
    }
    echo " -> Melindungi Service Layer (Hapus Server)..."
    inject_code "app/Services/Servers/ServerDeletionService.php" "public function handle(Server \$server)" "$PROTECTION_CODE_DELETE_SERVER_SERVICE"
    echo " -> Melindungi Controller Aksi (Hapus/Ubah User)..."
    inject_code "app/Http/Controllers/Admin/UserController.php" "public function destroy(Request \$request, User \$user)" "$PROTECTION_CODE_DELETE_USER"
    inject_code "app/Http/Controllers/Admin/UserController.php" "public function update(UpdateUserRequest \$request, User \$user)" "$UPDATE_USER_PROTECTION"
    echo " -> Memasang Fitur Anti-Intip (melalui API)..."
    inject_code "app/Http/Controllers/Api/Client/Servers/ServerController.php" "public function index(GetServerRequest \$request, Server \$server)" "$ANTI_INTIP_CODE_API"
    inject_code "app/Http/Controllers/Api/Client/Servers/FileController.php" "public function download(Request \$request, Server \$server)" "$ANTI_DOWNLOAD_CODE_API"
    echo " -> Melindungi Semua Halaman Admin secara menyeluruh..."
    inject_code "app/Http/Controllers/Admin/LocationController.php" "public function index()" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/LocationController.php" "public function create(LocationFormRequest \$request)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/LocationController.php" "public function store(LocationFormRequest \$request)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/LocationController.php" "public function edit(Location \$location, UpdateLocationFormRequest \$request)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/LocationController.php" "public function update(UpdateLocationFormRequest \$request, Location \$location)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/LocationController.php" "public function destroy(Location \$location)" "$PROTECTION_CODE_VIEW";
    inject_code "app/Http/Controllers/Admin/NodesController.php" "public function index()" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/NodesController.php" "public function create()" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/NodesController.php" "public function store(StoreNodeRequest \$request)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/NodesController.php" "public function view(Node \$node)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/NodesController.php" "public function edit(Node \$node)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/NodesController.php" "public function update(UpdateNodeRequest \$request, Node \$node)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/NodesController.php" "public function destroy(Node \$node)" "$PROTECTION_CODE_VIEW";
    inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function index()" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function create()" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function store(StoreNestFormRequest \$request)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function view(Nest \$nest)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function edit(Nest \$nest)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function update(UpdateNestFormRequest \$request, Nest \$nest)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Nests/NestController.php" "public function destroy(Nest \$nest)" "$PROTECTION_CODE_VIEW";
    inject_code "app/Http/Controllers/Admin/Settings/IndexController.php" "public function index(IndexFormRequest \$request)" "$PROTECTION_CODE_VIEW"; inject_code "app/Http/Controllers/Admin/Settings/IndexController.php" "public function update(IndexFormRequest \$request)" "$PROTECTION_CODE_VIEW";
    echo -e "${C_GREEN}✔ Semua proteksi telah dipasang.${C_RESET}"
    echo -e "\n${C_BOLD}Membersihkan dan membangun ulang cache Pterodactyl...${C_RESET}"
    php artisan view:clear; php artisan config:clear; php artisan route:clear; php artisan cache:clear; php artisan config:cache; php artisan route:cache;
    echo -e "${C_GREEN}✔ Cache berhasil dioptimalkan.${C_RESET}"
    restart_php_fpm
    echo -e "\n${C_GREEN}${C_BOLD}===== PEMASANGAN SELESAI! Keamanan penuh telah aktif. =====${C_RESET}"
}

main_menu() {
    clear
    display_title
    echo -e "${C_YELLOW}Pilih salah satu opsi:${C_RESET}"
    echo -e "  ${C_CYAN}1)${C_RESET} Pasang Fitur (Final)"
    echo -e "  ${C_CYAN}2)${C_RESET} ${C_RED}Lepas Fitur (Restore Panel)${C_RESET}"
    echo -e "  ${C_CYAN}3)${C_RESET} Buat Backup Manual"
    echo -e "  ${C_CYAN}4)${C_RESET} Keluar"
    echo ""
    read -p "Masukkan pilihan Anda [1-4]: " choice
    case $choice in
        1) install_features ;;
        2) uninstall_features ;;
        3) backup_files ;;
        4) echo -e "${C_GREEN}Sampai jumpa!${C_RESET}"; exit 0 ;;
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
