#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "=================================================="
echo "      Pterodactyl Protection - Strict Mode"
echo "      Developer By XYCoolcraft | Xayz Tech"
echo "=================================================="
echo -e "${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root (Run as user with sudo if needed, but standard user is safer for web files)"
    # Note: Usually Pterodactyl files are owned by www-data or similar, running as root is fine if we fix permissions later.
    # Continuing but warning is shown.
fi

# Check if we're in the correct directory
if [[ ! -d "/var/www/pterodactyl" ]]; then
    print_error "Pterodactyl panel not found in /var/www/pterodactyl"
    print_error "Please run this script from your Pterodactyl installation directory"
    exit 1
fi

# Backup directory
BACKUP_DIR="/var/www/pterodactyl/backups/protect_xycoolcraft_strict_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to create backup
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "$BACKUP_DIR/"
        print_status "Backed up: $(basename "$file")"
    fi
}

# Function to replace file content
replace_file() {
    local file="$1"
    local content="$2"
    local description="$3"
    
    backup_file "$file"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$file")"
    
    # Write content to file
    echo "$content" > "$file"
    
    if [[ $? -eq 0 ]]; then
        print_status "Installed: $description"
    else
        print_error "Failed to install: $description"
        return 1
    fi
}

# ==================================================
# 1. ANTI DELETE SERVER (STRICT)
# ==================================================

SERVER_DELETION_SERVICE='<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;
use Illuminate\Http\Response;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\Log;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Services\Databases\DatabaseManagementService;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

class ServerDeletionService
{
    protected bool $force = false;

    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $daemonServerRepository,
        private DatabaseManagementService $databaseManagementService
    ) {
    }

    public function withForce(bool $bool = true): self
    {
        $this->force = $bool;
        return $this;
    }

    public function handle(Server $server): void
    {
        $user = Auth::user();

        // 🔒 Proteksi: Hanya Admin ID 1
        if ($user) {
            if ($user->id !== 1) {
                // Cek pemilik asli
                $ownerId = $server->owner_id ?? $server->user_id ?? ($server->owner?->id ?? null) ?? ($server->user?->id ?? null);

                if ($ownerId === null) {
                    throw new DisplayException("Akses ditolak: Data pemilik server tidak valid. Hubungi Administrator Utama.");
                }

                if ($ownerId !== $user->id) {
                    throw new DisplayException("❌ AKSES DITOLAK: Anda hanya boleh menghapus server milik Anda sendiri! Protection By XYCoolcraft - Xayz Tech");
                }
            }
        }

        try {
            $this->daemonServerRepository->setServer($server)->delete();
        } catch (DaemonConnectionException $exception) {
            if (!$this->force && $exception->getStatusCode() !== Response::HTTP_NOT_FOUND) {
                throw $exception;
            }
            Log::warning($exception);
        }

        $this->connection->transaction(function () use ($server) {
            foreach ($server->databases as $database) {
                try {
                    $this->databaseManagementService->delete($database);
                } catch (\Exception $exception) {
                    if (!$this->force) {
                        throw $exception;
                    }
                    $database->delete();
                    Log::warning($exception);
                }
            }
            $server->delete();
        });
    }
}'

# ==================================================
# 2. ANTI DELETE USER
# ==================================================

USER_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Pterodactyl\Models\Model;
use Illuminate\Support\Collection;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\Translation\Translator;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Http\Requests\Admin\UserFormRequest;
use Pterodactyl\Http\Requests\Admin\NewUserFormRequest;
use Pterodactyl\Contracts\Repository\UserRepositoryInterface;

class UserController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        protected AlertsMessageBag $alert,
        protected UserCreationService $creationService,
        protected UserDeletionService $deletionService,
        protected Translator $translator,
        protected UserUpdateService $updateService,
        protected UserRepositoryInterface $repository,
        protected ViewFactory $view
    ) {
    }

    public function index(Request $request): View
    {
        $users = QueryBuilder::for(
            User::query()->select("users.*")
                ->selectRaw("COUNT(DISTINCT(subusers.id)) as subuser_of_count")
                ->selectRaw("COUNT(DISTINCT(servers.id)) as servers_count")
                ->leftJoin("subusers", "subusers.user_id", "=", "users.id")
                ->leftJoin("servers", "servers.owner_id", "=", "users.id")
                ->groupBy("users.id")
        )
            ->allowedFilters(["username", "email", "uuid"])
            ->allowedSorts(["id", "uuid"])
            ->paginate(50);

        return $this->view->make("admin.users.index", ["users" => $users]);
    }

    public function create(): View
    {
        return $this->view->make("admin.users.new", [
            "languages" => $this->getAvailableLanguages(true),
        ]);
    }

    public function view(User $user): View
    {
        return $this->view->make("admin.users.view", [
            "user" => $user,
            "languages" => $this->getAvailableLanguages(true),
        ]);
    }

    public function delete(Request $request, User $user): RedirectResponse
    {
        if ($request->user()->id !== 1) {
            throw new DisplayException("❌ HANYA ADMIN UTAMA (ID 1) YANG BISA MENGHAPUS USER! Protection by XYCoolcraft");
        }

        if ($request->user()->id === $user->id) {
            throw new DisplayException($this->translator->get("admin/user.exceptions.user_has_servers"));
        }

        $this->deletionService->handle($user);
        return redirect()->route("admin.users");
    }

    public function store(NewUserFormRequest $request): RedirectResponse
    {
        $user = $this->creationService->handle($request->normalize());
        $this->alert->success($this->translator->get("admin/user.notices.account_created"))->flash();
        return redirect()->route("admin.users.view", $user->id);
    }

    public function update(UserFormRequest $request, User $user): RedirectResponse
    {
        $restrictedFields = ["email", "first_name", "last_name", "password"];
        foreach ($restrictedFields as $field) {
            if ($request->filled($field) && $request->user()->id !== 1) {
                throw new DisplayException("⚠️ Proteksi Aktif: Data sensitif hanya bisa diubah oleh Admin ID 1.");
            }
        }

        if ($user->root_admin && $request->user()->id !== 1) {
            throw new DisplayException("🚫 DILARANG MENGUBAH STATUS ADMIN UTAMA.");
        }

        $this->updateService
            ->setUserLevel(User::USER_LEVEL_ADMIN)
            ->handle($user, $request->normalize());

        $this->alert->success(trans("admin/user.notices.account_updated"))->flash();
        return redirect()->route("admin.users.view", $user->id);
    }

    public function json(Request $request): Model|Collection
    {
        $users = QueryBuilder::for(User::query())->allowedFilters(["email"])->paginate(25);
        if ($request->query("user_id")) {
            $user = User::query()->findOrFail($request->input("user_id"));
            $user->md5 = md5(strtolower($user->email));
            return $user;
        }
        return $users->map(function ($item) {
            $item->md5 = md5(strtolower($item->email));
            return $item;
        });
    }
}'

# ==================================================
# 3. ANTI INTIP LOCATION
# ==================================================

LOCATION_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Location;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Http\Requests\Admin\LocationFormRequest;
use Pterodactyl\Services\Locations\LocationUpdateService;
use Pterodactyl\Services\Locations\LocationCreationService;
use Pterodactyl\Services\Locations\LocationDeletionService;
use Pterodactyl\Contracts\Repository\LocationRepositoryInterface;

class LocationController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected LocationCreationService $creationService,
        protected LocationDeletionService $deletionService,
        protected LocationRepositoryInterface $repository,
        protected LocationUpdateService $updateService,
        protected ViewFactory $view
    ) {
    }

    public function index(): View
    {
        if (Auth::user()->id !== 1) { abort(403, "XYCoolcraft Protection: LOCATION Access Denied"); }
        return $this->view->make("admin.locations.index", [
            "locations" => $this->repository->getAllWithDetails(),
        ]);
    }

    public function view(int $id): View
    {
        if (Auth::user()->id !== 1) { abort(403, "XYCoolcraft Protection: LOCATION Access Denied"); }
        return $this->view->make("admin.locations.view", [
            "location" => $this->repository->getWithNodes($id),
        ]);
    }

    public function create(LocationFormRequest $request): RedirectResponse
    {
        if (Auth::user()->id !== 1) { abort(403, "XYCoolcraft Protection: LOCATION Access Denied"); }
        $location = $this->creationService->handle($request->normalize());
        $this->alert->success("Location was created successfully.")->flash();
        return redirect()->route("admin.locations.view", $location->id);
    }

    public function update(LocationFormRequest $request, Location $location): RedirectResponse
    {
        if (Auth::user()->id !== 1) { abort(403, "XYCoolcraft Protection: LOCATION Access Denied"); }
        if ($request->input("action") === "delete") {
            return $this->delete($location);
        }
        $this->updateService->handle($location->id, $request->normalize());
        $this->alert->success("Location was updated successfully.")->flash();
        return redirect()->route("admin.locations.view", $location->id);
    }

    public function delete(Location $location): RedirectResponse
    {
        if (Auth::user()->id !== 1) { abort(403, "XYCoolcraft Protection: LOCATION Access Denied"); }
        try {
            $this->deletionService->handle($location->id);
            return redirect()->route("admin.locations");
        } catch (DisplayException $ex) {
            $this->alert->danger($ex->getMessage())->flash();
        }
        return redirect()->route("admin.locations.view", $location->id);
    }
}'

# ==================================================
# 4. ANTI INTIP NODES (SUPER STRICT)
# ==================================================

NODE_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Contracts\Repository\NodeRepositoryInterface;
use Illuminate\Http\RedirectResponse;
use Pterodactyl\Http\Requests\Admin\Node\NodeFormRequest;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Services\Nodes\NodeCreationService;
use Pterodactyl\Services\Nodes\NodeUpdateService;
use Pterodactyl\Services\Nodes\NodeDeletionService;

class NodeController extends Controller
{
    public function __construct(
        private ViewFactory $view,
        private NodeRepositoryInterface $repository,
        private NodeCreationService $creationService,
        private NodeDeletionService $deletionService,
        private NodeUpdateService $updateService,
        private AlertsMessageBag $alert
    ) {
    }

    public function index(Request $request): View
    {
        // 🔒 BLOKIR TOTAL
        if (Auth::user()->id !== 1) {
            abort(403, "🚫 AKSES NODES DITOLAK! Protection by XYCoolcraft - Xayz Tech");
        }

        $nodes = QueryBuilder::for(
            Node::query()->with("location")->withCount("servers")
        )
            ->allowedFilters(["uuid", "name"])
            ->allowedSorts(["id"])
            ->paginate(25);

        return $this->view->make("admin.nodes.index", ["nodes" => $nodes]);
    }

    public function view(int $node): View
    {
        // 🔒 BLOKIR VIEW (Ini mencegah akses dari link Server/Mount)
        if (Auth::user()->id !== 1) {
            abort(403, "🚫 ANDA TIDAK DIIZINKAN MELIHAT DETAIL NODE INI! Protection by XYCoolcraft");
        }

        return $this->view->make("admin.nodes.view", [
            "node" => $this->repository->loadLocationAndServerCount($node),
        ]);
    }

    public function create(): View
    {
         if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
         return $this->view->make("admin.nodes.new");
    }

    public function store(NodeFormRequest $request): RedirectResponse
    {
         if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
         $node = $this->creationService->handle($request->normalize());
         $this->alert->success(trans("admin/node.notices.node_created"))->flash();
         return redirect()->route("admin.nodes.view", $node->id);
    }

    public function update(NodeFormRequest $request, Node $node): RedirectResponse
    {
         if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
         $this->updateService->handle($node, $request->normalize());
         $this->alert->success(trans("admin/node.notices.node_updated"))->flash();
         return redirect()->route("admin.nodes.view", $node->id);
    }

    public function delete(int $node): RedirectResponse
    {
         if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
         $this->deletionService->handle($node);
         $this->alert->success(trans("admin/node.notices.node_deleted"))->flash();
         return redirect()->route("admin.nodes");
    }
}'

# ==================================================
# 5. ANTI INTIP NEST (SUPER STRICT)
# ==================================================

NEST_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Nests;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Nests\NestUpdateService;
use Pterodactyl\Services\Nests\NestCreationService;
use Pterodactyl\Services\Nests\NestDeletionService;
use Pterodactyl\Contracts\Repository\NestRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Nest\StoreNestFormRequest;
use Illuminate\Support\Facades\Auth;

class NestController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected NestCreationService $nestCreationService,
        protected NestDeletionService $nestDeletionService,
        protected NestRepositoryInterface $repository,
        protected NestUpdateService $nestUpdateService,
        protected ViewFactory $view
    ) {
    }

    public function index(): View
    {
        if (Auth::user()->id !== 1) {
            abort(403, "🚫 NEST ACCESS DENIED! Protection by XYCoolcraft");
        }
        return $this->view->make("admin.nests.index", [
            "nests" => $this->repository->getWithCounts(),
        ]);
    }

    public function create(): View
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        return $this->view->make("admin.nests.new");
    }

    public function store(StoreNestFormRequest $request): RedirectResponse
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        $nest = $this->nestCreationService->handle($request->normalize());
        $this->alert->success(trans("admin/nests.notices.created", ["name" => htmlspecialchars($nest->name)]))->flash();
        return redirect()->route("admin.nests.view", $nest->id);
    }

    public function view(int $nest): View
    {
        // 🔒 Proteksi ketat untuk View agar tidak bisa ditembus dari halaman lain
        if (Auth::user()->id !== 1) {
            abort(403, "🚫 NEST DETAIL DENIED! Protection by XYCoolcraft");
        }
        return $this->view->make("admin.nests.view", [
            "nest" => $this->repository->getWithEggServers($nest),
        ]);
    }

    public function update(StoreNestFormRequest $request, int $nest): RedirectResponse
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        $this->nestUpdateService->handle($nest, $request->normalize());
        $this->alert->success(trans("admin/nests.notices.updated"))->flash();
        return redirect()->route("admin.nests.view", $nest);
    }

    public function destroy(int $nest): RedirectResponse
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        $this->nestDeletionService->handle($nest);
        $this->alert->success(trans("admin/nests.notices.deleted"))->flash();
        return redirect()->route("admin.nests");
    }
}'

# ==================================================
# 6. ANTI INTIP SETTINGS
# ==================================================

SETTINGS_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin\Settings;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Helpers\SoftwareVersionService;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Settings\BaseSettingsFormRequest;

class IndexController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        private AlertsMessageBag $alert,
        private Kernel $kernel,
        private SettingsRepositoryInterface $settings,
        private SoftwareVersionService $versionService,
        private ViewFactory $view
    ) {
    }

    public function index(): View
    {
        if (Auth::user()->id !== 1) {
            abort(403, "Protect by XYCoolcraft - SETTINGS Akses ditolak❌");
        }
        return $this->view->make("admin.settings.index", [
            "version" => $this->versionService,
            "languages" => $this->getAvailableLanguages(true),
        ]);
    }

    public function update(BaseSettingsFormRequest $request): RedirectResponse
    {
        if (Auth::user()->id !== 1) {
            abort(403, "Protect by XYCoolcraft - SETTINGS Akses ditolak");
        }
        foreach ($request->normalize() as $key => $value) {
            $this->settings->set("settings::" . $key, $value);
        }
        $this->kernel->call("queue:restart");
        $this->alert->success("Panel settings have been updated successfully.")->flash();
        return redirect()->route("admin.settings");
    }
}'

# ==================================================
# 7. ANTI INTIP MOUNTS (NEW & REQUESTED)
# ==================================================

MOUNT_CONTROLLER='<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Pterodactyl\Models\Mount;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Http\Requests\Admin\MountFormRequest;
use Pterodactyl\Services\Mounts\MountCreationService;
use Pterodactyl\Services\Mounts\MountUpdateService;
use Pterodactyl\Services\Mounts\MountDeletionService;
use Pterodactyl\Contracts\Repository\MountRepositoryInterface;
use Illuminate\Support\Facades\Auth;

class MountController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected MountCreationService $creationService,
        protected MountDeletionService $deletionService,
        protected MountRepositoryInterface $repository,
        protected MountUpdateService $updateService,
        protected ViewFactory $view
    ) {
    }

    public function index(): View
    {
        // 🔒 BLOKIR AKSES LIST MOUNT
        if (Auth::user()->id !== 1) {
            abort(403, "🚫 MOUNT ACCESS DENIED! Protection by XYCoolcraft");
        }

        return $this->view->make("admin.mounts.index", [
            "mounts" => $this->repository->getAllWithEggs(),
        ]);
    }

    public function view(Mount $mount): View
    {
        // 🔒 BLOKIR AKSES DETAIL MOUNT
        if (Auth::user()->id !== 1) {
            abort(403, "🚫 MOUNT DETAIL DENIED! Protection by XYCoolcraft");
        }

        return $this->view->make("admin.mounts.view", [
            "mount" => $mount,
            "nests" => $this->repository->getNestsWithEggs(),
        ]);
    }

    public function store(MountFormRequest $request): RedirectResponse
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        $mount = $this->creationService->handle($request->normalize());
        $this->alert->success("Mount was created successfully.")->flash();
        return redirect()->route("admin.mounts.view", $mount->id);
    }

    public function update(MountFormRequest $request, Mount $mount): RedirectResponse
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        $this->updateService->handle($mount, $request->normalize());
        $this->alert->success("Mount was updated successfully.")->flash();
        return redirect()->route("admin.mounts.view", $mount->id);
    }

    public function delete(Mount $mount): RedirectResponse
    {
        if (Auth::user()->id !== 1) abort(403, "XYCoolcraft Protection");
        $this->deletionService->handle($mount);
        $this->alert->success("Mount was deleted successfully.")->flash();
        return redirect()->route("admin.mounts");
    }
}'

# ==================================================
# MAIN INSTALLATION
# ==================================================

echo -e "${BLUE}Starting Protect by XYCoolcraft (STRICT MODE)...${NC}"
echo ""

# Install all protection files
print_status "Installing protection modules..."

# 1. Anti Delete Server
replace_file "/var/www/pterodactyl/app/Services/Servers/ServerDeletionService.php" "$SERVER_DELETION_SERVICE" "Anti Delete Server Protection"

# 2. Anti Delete User   
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php" "$USER_CONTROLLER" "Anti Delete User Protection"

# 3. Anti Intip Location
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php" "$LOCATION_CONTROLLER" "Anti Intip Location Protection"

# 4. Anti Intip Nodes (UPDATED PATH & CONTENT)
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php" "$NODE_CONTROLLER" "Strict Anti Intip Nodes Protection"

# 5. Anti Intip Nest
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php" "$NEST_CONTROLLER" "Strict Anti Intip Nest Protection"

# 6. Anti Intip Settings
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/Settings/IndexController.php" "$SETTINGS_CONTROLLER" "Anti Intip Settings Protection"

# 7. Anti Intip Mounts (NEW)
replace_file "/var/www/pterodactyl/app/Http/Controllers/Admin/MountController.php" "$MOUNT_CONTROLLER" "Strict Anti Intip Mount Protection"

echo ""
print_status "All protection modules installed successfully!"

# Set proper permissions
print_status "Setting file permissions..."
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl/storage
chmod -R 755 /var/www/pterodactyl/bootstrap/cache

# Clear cache
print_status "Clearing application cache (Important for controller changes)..."
cd /var/www/pterodactyl
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}    STRICT PROTECTION INSTALLED SUCCESSFULLY!     ${NC}"
echo -e "${GREEN}           Created by XYCoolcraft                 ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Summary of Changes:${NC}"
echo -e "✓ [UPDATED] Anti Delete Server (Only ID 1)"
echo -e "✓ [UPDATED] Anti Delete User (Only ID 1)" 
echo -e "✓ [UPDATED] Anti Intip Location (All Actions)"
echo -e "✓ [STRICT]  Anti Intip Nodes (Blocks Index AND View/Click from Servers)"
echo -e "✓ [STRICT]  Anti Intip Nest (Blocks Index AND View)"
echo -e "✓ [UPDATED] Anti Intip Settings"
echo -e "✓ [NEW]     Anti Intip Mounts (Full Block)"
echo ""
echo -e "${YELLOW}Backups saved to:${NC} $BACKUP_DIR"
echo ""
echo -e "${BLUE}System is now locked to Admin ID 1 Only!${NC}"
echo ""
