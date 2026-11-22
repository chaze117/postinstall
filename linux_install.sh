#!/usr/bin/env bash
#
# install-apps.sh
# Alkalmazástelepítő Ubuntu / Debian rendszerekhez
# Whiptail menüvel, kategóriákkal és telepítési progress barral.
#

# ===========================================================================
# SZÍNEZÉS
# ===========================================================================

export NEWT_COLORS='
root=,brightblue
window=,black
shadow=,blue
border=blue,black
title=blue,black
textbox=blue,black
listbox=blue,black
actlistbox=black,blue
sellistbox=blue,black
actsellistbox=black,blue
entry=blue,black
disentry=gray,black
button=black,blue
actbutton=black,cyan
compactbutton=black,blue
checkbox=blue,black
actcheckbox=black,blue
'

set -uo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
EXT_FILE="$SCRIPT_DIR/apps.conf"
LOG_FILE="/var/log/install-apps_$(date +%Y%m%d_%H%M%S).log"

export DEBIAN_FRONTEND=noninteractive

PSYSONIC_URL="https://github.com/Psysonic/psysonic/releases/download/app-v1.56.0/Psysonic_1.56.0_amd64.deb"
BBPORT_URL="https://github.com/deadinside28/bloodborne_pc/releases/download/0.7/Bloodborne-bbport-0.7-x86_64.AppImage"
BB_ICON="https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/c78bc3fc-9f08-47ca-81ae-d89055c7ec49/ddzt2ua-7de1ee44-e355-4ee3-9ae0-23e5aaf2915b.png/v1/fit/w_512,h_512/bloodborne_icon_by_andonovmarko_ddzt2ua-375w-2x.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9NTEyIiwicGF0aCI6Ii9mL2M3OGJjM2ZjLTlmMDgtNDdjYS04MWFlLWQ4OTA1NWM3ZWM0OS9kZHp0MnVhLTdkZTFlZTQ0LWUzNTUtNGVlMy05YWUwLTIzZTVhYWYyOTE1Yi5wbmciLCJ3aWR0aCI6Ijw9NTEyIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmltYWdlLm9wZXJhdGlvbnMiXX0.QeLTbsGBAinDS2vrBdwItqhgn-RM80Ds2jkFlE53QrM"

# ===========================================================================
# NAPLÓZÁS
# ===========================================================================

log() {
    echo "$(date '+%H:%M:%S') $*" >> "$LOG_FILE"
}

# ===========================================================================
# ROOT JOGOSULTSÁG
# ===========================================================================

if [[ $EUID -ne 0 ]]; then
    echo "Rendszergazdai jogosultság szükséges, újraindítás sudo-val..."
    exec sudo -E bash "$SCRIPT_PATH" "$@"
fi

# ===========================================================================
# KATALÓGUS
# ===========================================================================

CATALOG=()

add_app() {
    local cat="$1"
    local name="$2"
    local mgr="$3"
    local payload="${4:-}"
    local dflt="${5:-0}"
    local icon_url="${6:-}"

    # A hatodik mező opcionális: AppImage ikon URL.
    # A régi, ötoszlopos bejegyzések változatlanul működnek.
    CATALOG+=("${cat}|${name}|${mgr}|${payload}|${dflt}|${icon_url}")
}

# Böngészők
add_app "Böngészők" "Mozilla Firefox" apt firefox 0
add_app "Böngészők" "Chromium" apt chromium-browser 0
add_app "Böngészők" "Google Chrome" deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" 0
add_app "Böngészők" "Brave" flatpak com.brave.Browser 0
add_app "Böngészők" "Opera" flatpak com.opera.Opera 0
add_app "Böngészők" "Opera GX" flatpak com.opera.opera-gx 0
add_app "Böngészők" "Vivaldi" flatpak com.vivaldi.Vivaldi 0

# Eszközök
add_app "Eszközök" "7-Zip (p7zip)" apt p7zip-full 0
add_app "Eszközök" "GParted" apt gparted 0
add_app "Eszközök" "htop" apt htop 0
add_app "Eszközök" "Synaptic" apt synaptic 0
add_app "Eszközök" "Timeshift" apt timeshift 0
add_app "Eszközök" "Flatseal" flatpak com.github.tchx84.Flatseal 0
add_app "Eszközök" "OBS Studio" flatpak com.obsproject.Studio 0
add_app "Eszközök" "Solaar" flatpak io.github.pwr_solaar.solaar 0
add_app "Eszközök" "Remmina" apt remmina 0

# Média
add_app "Média" "VLC" apt vlc 0
add_app "Média" "Spotify" flatpak com.spotify.Client 0
add_app "Média" "HakuNeko" flatpak io.github.hakuneko.HakuNeko 0
add_app "Média" "Jellyfin Desktop" flatpak org.jellyfin.JellyfinDesktop 0
add_app "Média" "Rhythmbox" apt rhythmbox 0
add_app "Média" "Psysonic" deb $PSYSONIC_URL 0


# Szerkesztők
add_app "Szerkesztők" "LibreOffice" flatpak org.libreoffice.LibreOffice 0
add_app "Szerkesztők" "Bambu Studio" flatpak com.bambulab.BambuStudio 0
add_app "Szerkesztők" "GIMP" flatpak org.gimp.GIMP 0
add_app "Szerkesztők" "DaVinci Resolve" davinci "" 0
add_app "Szerkesztők" "Reaper" flatpak fm.reaper.Reaper 0
add_app "Szerkesztők" "HandBrake" flatpak fr.handbrake.ghb 0
add_app "Szerkesztők" "Krita" flatpak org.kde.krita 0
add_app "Szerkesztők" "Font Forge" flatpak org.fontforge.FontForge 0


# Kommunikáció
add_app "Kommunikáció" "Zoom" deb "https://zoom.us/client/latest/zoom_amd64.deb" 0
add_app "Kommunikáció" "Discord" flatpak com.discordapp.Discord 0
add_app "Kommunikáció" "Telegram" flatpak org.telegram.desktop 0
add_app "Kommunikáció" "Viber" flatpak com.viber.Viber 0

# Fejlesztés
add_app "Fejlesztés" "Git" apt git 0
add_app "Fejlesztés" "Visual Studio Code" flatpak com.visualstudio.code 0
add_app "Fejlesztés" "Docker Engine + Compose" apt "docker.io docker-compose-v2" 0
add_app "Fejlesztés" "Node.js (NodeSource LTS)" apt nodejs 0
add_app "Fejlesztés" "Python 3 pip" apt python3-pip 0

# Példa AppImage bejegyzésre (az ikon URL opcionális):
# add_app "Eszközök" "Példa alkalmazás" appimage "https://example.com/app.AppImage" 0 "https://example.com/icon.png"

# Gaming
add_app "Gaming" "Steam" deb "https://cdn.fastly.steamstatic.com/client/installer/steam.deb" 0
add_app "Gaming" "Heroic Games Launcher" flatpak com.heroicgameslauncher.hgl 0
add_app "Gaming" "Hytale Launcher" flatpak com.hypixel.HytaleLauncher 0
add_app "Gaming" "CurseForge" flatpak com.overwolf.curseforge 0
add_app "Gaming" "Prism Launcher" flatpak org.prismlauncher.PrismLauncher 0
add_app "Gaming" "Bloodborne PC Port" appimage $BBPORT_URL 0 $BB_ICON

# ===========================================================================
# KÜLSŐ KATALÓGUS
# ===========================================================================

if [[ -f "$EXT_FILE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        CATALOG+=("$line")
    done < "$EXT_FILE"
fi

# ===========================================================================
# WHIPTAIL PROGRESS GAUGE
# ===========================================================================

GAUGE_DIR=""
GAUGE_PID=""
GAUGE_FD=""

PROGRESS=0
PROGRESS_STEP=0
PROGRESS_TOTAL=0
FAILED_COUNT=0

gauge_start() {
    local title="$1"
    local message="$2"

    command -v whiptail >/dev/null 2>&1 || return 1
    [[ -w /dev/tty ]] || return 1

    GAUGE_DIR="$(mktemp -d)" || return 1

    mkfifo "$GAUGE_DIR/input" || {
        rm -rf "$GAUGE_DIR"
        GAUGE_DIR=""
        return 1
    }

    whiptail \
        --title "$title" \
        --gauge "$message" \
        10 76 0 \
        < "$GAUGE_DIR/input" > /dev/tty 2>&1 &

    GAUGE_PID=$!

    exec {GAUGE_FD}> "$GAUGE_DIR/input"

    return 0
}

gauge_update() {
    local percent="$1"
    local message="$2"

    [[ -n "$GAUGE_FD" ]] || return 0

    printf 'XXX\n%s\n%s\nXXX\n' \
        "$percent" "$message" >&"$GAUGE_FD"
}

gauge_stop() {
    [[ -n "$GAUGE_FD" ]] || return 0

    gauge_update 100 "Telepítés befejezése..."

    exec {GAUGE_FD}>&-
    GAUGE_FD=""

    wait "$GAUGE_PID" 2>/dev/null || true

    GAUGE_PID=""

    rm -rf "$GAUGE_DIR"
    GAUGE_DIR=""
}

progress_step() {
    local message="$1"
    shift

    local rc

    gauge_update "$PROGRESS" "$message"

    "$@" >> "$LOG_FILE" 2>&1
    rc=$?

    PROGRESS_STEP=$((PROGRESS_STEP + 1))
    PROGRESS=$((PROGRESS_STEP * 100 / PROGRESS_TOTAL))

    if [[ $rc -ne 0 ]]; then
        FAILED_COUNT=$((FAILED_COUNT + 1))
        log "HIBA ($rc): $message"
    else
        log "SIKERES: $message"
    fi

    gauge_update "$PROGRESS" "$message"

    return 0
}

# ===========================================================================
# TELEPÍTÉSI SEGÉDFÜGGVÉNYEK
# ===========================================================================

ensure_flatpak() {
    if ! command -v flatpak >/dev/null 2>&1; then
        log "Flatpak telepítése..."
        apt-get install -y flatpak >> "$LOG_FILE" 2>&1 || return 1
    fi

    if ! flatpak remotes --columns=name 2>/dev/null | grep -qx 'flathub'; then
        log "Flathub repó hozzáadása..."

        flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo \
            >> "$LOG_FILE" 2>&1 || return 1
    fi

    return 0
}

install_apt() {
    local pkgs=("$@")

    [[ ${#pkgs[@]} -eq 0 ]] && return 0

    log "APT telepítés: ${pkgs[*]}"

    apt-get install -y "${pkgs[@]}" >> "$LOG_FILE" 2>&1
}

install_deb() {
    local url="$1"
    local name="$2"
    local tmp

    tmp="$(mktemp --suffix=.deb)" || return 1

    log "Letöltés ($name): $url"

    if ! wget -q --content-disposition -O "$tmp" "$url"; then
        log "HIBA: nem sikerült letölteni ($name)"
        rm -f "$tmp"
        return 1
    fi

    log "Telepítés ($name)..."

    if ! apt-get install -y "$tmp" >> "$LOG_FILE" 2>&1; then
        log "HIBA: nem sikerült telepíteni ($name)"
        rm -f "$tmp"
        return 1
    fi

    rm -f "$tmp"
    return 0
}

install_flatpak() {
    local app_id="$1"
    local name="$2"

    ensure_flatpak || return 1

    log "Flatpak telepítés ($name): $app_id"

    flatpak install -y flathub "$app_id" >> "$LOG_FILE" 2>&1
}

# ===========================================================================
# APPIMAGE TELEPÍTÉS
# ===========================================================================

install_appimage() {
    local url="$1"
    local name="$2"
    local icon_url="${3:-}"
    local slug app_dir app_path desktop_path icon_path icon_ext icon_name

    [[ -n "$url" ]] || {
        log "HIBA: nincs megadva AppImage URL ($name)"
        return 1
    }

    slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
    [[ -n "$slug" ]] || slug="appimage-app"

    app_dir="/opt/appimages"
    app_path="$app_dir/$slug.AppImage"
    desktop_path="/usr/share/applications/$slug.desktop"

    mkdir -p "$app_dir" || return 1

    log "AppImage letöltése ($name): $url"
    if ! wget -q -O "$app_path" "$url" >> "$LOG_FILE" 2>&1; then
        log "HIBA: nem sikerült letölteni az AppImage fájlt ($name)"
        rm -f "$app_path"
        return 1
    fi

    chmod 0755 "$app_path" || {
        rm -f "$app_path"
        return 1
    }

    icon_name="application-x-executable"
    if [[ -n "$icon_url" ]]; then
        # A kiterjesztést az URL útvonalából vesszük, a query string nélkül.
        local icon_url_path="${icon_url%%\?*}"
        icon_ext="${icon_url_path##*.}"
        icon_ext="${icon_ext,,}"
        case "$icon_ext" in
            png|svg|jpg|jpeg|webp|xpm) ;;
            *) icon_ext="png" ;;
        esac

        icon_path="$app_dir/$slug-icon.$icon_ext"
        log "Ikon letöltése ($name): $icon_url"
        if wget -q -O "$icon_path" "$icon_url" >> "$LOG_FILE" 2>&1 && [[ -s "$icon_path" ]]; then
            icon_name="$icon_path"
        else
            log "FIGYELEM: az ikon letöltése nem sikerült ($name), alapértelmezett ikon használata."
            rm -f "$icon_path"
        fi
    fi

    cat > "$desktop_path" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$name AppImage
Exec=$app_path
Icon=$icon_name
Terminal=false
Categories=Utility;
EOF

    chmod 0644 "$desktop_path"
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >> "$LOG_FILE" 2>&1 || true

    log "AppImage telepítve: $app_path"
    return 0
}

# ===========================================================================
# SNAP -> FLATPAK CSERE
# ===========================================================================

switch_snap_to_flatpak() {
    log "=== Snap Áruház cseréje Flatpakra ==="

    if command -v snap >/dev/null 2>&1 &&
       snap list 2>/dev/null | grep -q '^snap-store'; then

        log "snap-store eltávolítása..."

        snap remove snap-store >> "$LOG_FILE" 2>&1 || return 1
    fi

    apt-get install -y flatpak gnome-software-plugin-flatpak \
        >> "$LOG_FILE" 2>&1 || return 1

    ensure_flatpak || return 1

    log "Snap Áruház cseréje befejezve."

    return 0
}

# ===========================================================================
# SNAPD TELJES ELTÁVOLÍTÁSA
# ===========================================================================

purge_snapd() {
    log "=== snapd teljes eltávolítása ==="

    local ans

    if command -v whiptail >/dev/null 2>&1 && [[ -w /dev/tty ]]; then
        whiptail --title "FIGYELEM" \
            --yesno "Ez eltávolítja a snapd-t és minden Snap csomagot.\n\nBiztosan folytatod?" \
            12 70 > /dev/tty 2>&1 || {
                log "Snapd eltávolítása megszakítva."
                return 0
            }
    else
        read -rp "Biztosan eltávolítod a snapd-t? (í/N) " ans
        [[ "$ans" =~ ^([íIiYy])$ ]] || return 0
    fi

    if command -v snap >/dev/null 2>&1; then
        while read -r s; do
            [[ -z "$s" ]] && continue
            snap remove --purge "$s" >> "$LOG_FILE" 2>&1
        done < <(snap list 2>/dev/null | awk 'NR>1{print $1}')
    fi

    systemctl disable --now snapd.socket snapd.service \
        >> "$LOG_FILE" 2>&1 || true

    apt-get purge -y snapd >> "$LOG_FILE" 2>&1

    rm -rf /var/cache/snapd
    rm -rf /home/*/snap

    cat > /etc/apt/preferences.d/nosnap.pref <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

    log "snapd eltávolítva."
}

# ===========================================================================
# DAVINCI RESOLVE
# ===========================================================================

DAVINCI_DEPS=(
    libapr1 libaprutil1 libxcb-cursor0 libxcb-xinerama0
    libnss3 libasound2t64 ocl-icd-opencl-dev mesa-opencl-icd
    libglu1-mesa unzip libfuse2 libfuse2t64 libapr1t64 libaprutil1t64 libasound2t64
    libglib2.0-0t64 libxcb-xinput0
)

install_davinci() {
    local run_path="$1"

    if [[ -z "$run_path" ]]; then
        if command -v whiptail >/dev/null 2>&1; then
            run_path=$(whiptail --title "DaVinci Resolve" --inputbox \
                "A DaVinci Resolve .run telepítőjének teljes elérési útja:" \
                10 70 "$HOME/Downloads/" 3>&1 1>&2 2>&3) || return 0
        else
            read -rp "A DaVinci Resolve .run telepítőjének elérési útja: " run_path
        fi
    fi

    if [[ ! -f "$run_path" ]]; then
        log "HIBA: nem található a fájl: $run_path"
        return 1
    fi

    log "=== DaVinci Resolve telepítése ==="

    apt-get update >> "$LOG_FILE" 2>&1 || return 1

    # Ubuntu 24.04 esetén a libasound2t64 használata szükséges lehet.
    if grep -q 'VERSION_ID="24.04"' /etc/os-release 2>/dev/null; then
        DAVINCI_DEPS[5]="libasound2t64"
    fi

    apt-get install -y "${DAVINCI_DEPS[@]}" >> "$LOG_FILE" 2>&1 || return 1

    apt-get install -f -y >> "$LOG_FILE" 2>&1 || return 1

    chmod +x "$run_path" || return 1

    log "DaVinci Resolve telepítő indítása: $run_path"

    SKIP_PACKAGE_CHECK=1 "$run_path"
}

# ===========================================================================
# WHIPTAIL ELLENŐRZÉSE
# ===========================================================================

ensure_whiptail() {
    if command -v whiptail >/dev/null 2>&1; then
        return 0
    fi

    log "Whiptail telepítése..."

    apt-get update >> "$LOG_FILE" 2>&1
    apt-get install -y whiptail >> "$LOG_FILE" 2>&1

    command -v whiptail >/dev/null 2>&1
}

# ===========================================================================
# MENÜADATOK
# ===========================================================================

declare -a APP_CAT=()
declare -a APP_NAME=()
declare -a APP_MGR=()
declare -a APP_PAYLOAD=()
declare -a APP_ICON=()
declare -a APP_SEL=()
declare -a CATS=()

parse_catalog_arrays() {
    APP_CAT=()
    APP_NAME=()
    APP_MGR=()
    APP_PAYLOAD=()
    APP_ICON=()
    APP_SEL=()

    local line cat name mgr payload dflt icon_url

    for line in "${CATALOG[@]}"; do
        IFS='|' read -r cat name mgr payload dflt icon_url <<< "$line"

        APP_CAT+=("$cat")
        APP_NAME+=("$name")
        APP_MGR+=("$mgr")
        APP_PAYLOAD+=("$payload")
        APP_ICON+=("$icon_url")

        APP_SEL+=("$([[ "$dflt" == "1" ]] && echo 1 || echo 0)")
    done
}

get_categories() {
    CATS=()

    local cat seen=","

    for cat in "${APP_CAT[@]}"; do
        if [[ "$seen" != *",$cat,"* ]]; then
            CATS+=("$cat")
            seen+="$cat,"
        fi
    done
}

count_in_cat() {
    local cat="$1"
    local only="$2"
    local cnt=0
    local i

    for ((i = 0; i < ${#APP_CAT[@]}; i++)); do
        [[ "${APP_CAT[$i]}" != "$cat" ]] && continue

        if [[ "$only" == "1" ]]; then
            [[ "${APP_SEL[$i]}" == "1" ]] && cnt=$((cnt + 1))
        else
            cnt=$((cnt + 1))
        fi
    done

    echo "$cnt"
}

# ===========================================================================
# KATEGÓRIA CHECKLIST
# ===========================================================================

show_category_checklist() {
    local cat="$1"

    local args=()
    local idxmap=()
    local j=0
    local i
    local status

    args=(
        --title "$cat"
        --checklist
        "Szóköz: ki/be   Enter: OK   Esc: mégse"
        22 70 14
    )

    for ((i = 0; i < ${#APP_CAT[@]}; i++)); do
        [[ "${APP_CAT[$i]}" != "$cat" ]] && continue

        j=$((j + 1))
        idxmap[$j]=$i

        status="OFF"
        [[ "${APP_SEL[$i]}" == "1" ]] && status="ON"

        args+=("$j" "${APP_NAME[$i]}" "$status")
    done

    local result

    result=$(whiptail "${args[@]}" 3>&1 1>&2 2>&3) || return 0

    for ((i = 0; i < ${#APP_CAT[@]}; i++)); do
        [[ "${APP_CAT[$i]}" == "$cat" ]] && APP_SEL[$i]=0
    done

    local tag gi

    for tag in $result; do
        tag="${tag%\"}"
        tag="${tag#\"}"

        gi="${idxmap[$tag]:-}"

        [[ -n "$gi" ]] && APP_SEL[$gi]=1
    done
}

# ===========================================================================
# FŐ MENÜ
# ===========================================================================

show_menu() {
    if ! ensure_whiptail; then
        show_simple_menu
        return
    fi

    parse_catalog_arrays
    get_categories

    local flatpak_sel=0

    while true; do
        local margs=(
            --title "Alkalmazás telepítő"
            --menu
            "Válassz egy kategóriát, utána belül a programokat. A végén: Telepítés indítása."
            22 72 12
        )

        local cat sel tot fstatus

        for cat in "${CATS[@]}"; do
            sel=$(count_in_cat "$cat" 1)
            tot=$(count_in_cat "$cat" 0)

            margs+=("$cat" "$cat  ($sel/$tot kiválasztva)")
        done

        fstatus="ki"
        [[ "$flatpak_sel" == "1" ]] && fstatus="be"

        margs+=("SYS_FLATPAK" "Rendszer: Snap Áruház cseréje Flatpakra  [$fstatus]")
        margs+=("START" ">>> Telepítés indítása <<<")
        margs+=("QUIT" "Kilépés telepítés nélkül")

        local choice
        choice=$(whiptail "${margs[@]}" 3>&1 1>&2 2>&3)

        local rc=$?

        choice="${choice%\"}"
        choice="${choice#\"}"

        if [[ $rc -ne 0 || "$choice" == "QUIT" ]]; then
            return 0
        fi

        # A kategórianevek közvetlenül szerepelnek a menüben,
        # nincs szükség CAT: előtagra.
        local matched_category=0
        for cat in "${CATS[@]}"; do
            if [[ "$choice" == "$cat" ]]; then
                show_category_checklist "$cat"
                matched_category=1
                break
            fi
        done
        [[ "$matched_category" == "1" ]] && continue

        case "$choice" in
            SYS_FLATPAK)
                flatpak_sel=$((1 - flatpak_sel))
                ;;

            START)
                break
                ;;
        esac
    done

    local i

    for ((i = 0; i < ${#APP_CAT[@]}; i++)); do
        [[ "${APP_SEL[$i]}" == "1" ]] &&
            echo "${APP_CAT[$i]}|${APP_NAME[$i]}|${APP_MGR[$i]}|${APP_PAYLOAD[$i]}|1|${APP_ICON[$i]}"
    done

    [[ "$flatpak_sel" == "1" ]] && echo "SYS_FLATPAK"
}

# ===========================================================================
# EGYSZERŰ TARTALÉK MENÜ
# ===========================================================================

show_simple_menu() {
    local -a lines=("${CATALOG[@]}")
    local -a sel=()

    local i
    local dflt
    local lastcat=""

    for ((i = 0; i < ${#lines[@]}; i++)); do
        IFS='|' read -r _ _ _ _ dflt _ <<< "${lines[$i]}"
        sel[$i]=$([[ "$dflt" == "1" ]] && echo 1 || echo 0)
    done

    local flatpak_sel=0

    while true; do
        clear

        echo "=== Alkalmazás telepítő ==="
        echo "Számmal ki/be kapcsolhatsz (pl. 1 3 5-8)."
        echo "a=mind n=semmi d=alap"
        echo "f=Snap->Flatpak csere ki/be, Enter=telepítés, q=kilépés"
        echo ""

        for ((i = 0; i < ${#lines[@]}; i++)); do
            local cat name

            IFS='|' read -r cat name _ _ _ _ <<< "${lines[$i]}"

            if [[ "$cat" != "$lastcat" ]]; then
                echo "  -- $cat --"
                lastcat="$cat"
            fi

            local mark=" "
            [[ "${sel[$i]}" == "1" ]] && mark="x"

            printf '  %3d. [%s] %s\n' "$((i+1))" "$mark" "$name"
        done

        echo "  -- Rendszer --"

        local fmark=" "
        [[ "$flatpak_sel" == "1" ]] && fmark="x"

        printf '    f. [%s] Snap Áruház lecserélése Flatpakra\n' "$fmark"

        echo ""

        read -rp "Választás: " input
        input="${input,,}"

        case "$input" in
            "")
                for ((i = 0; i < ${#lines[@]}; i++)); do
                    [[ "${sel[$i]}" == "1" ]] && echo "${lines[$i]}"
                done

                [[ "$flatpak_sel" == "1" ]] && echo "SYS_FLATPAK"

                return 0
                ;;

            q)
                return 1
                ;;

            a)
                for ((i = 0; i < ${#lines[@]}; i++)); do
                    sel[$i]=1
                done
                ;;

            n)
                for ((i = 0; i < ${#lines[@]}; i++)); do
                    sel[$i]=0
                done
                ;;

            d)
                for ((i = 0; i < ${#lines[@]}; i++)); do
                    IFS='|' read -r _ _ _ _ dflt _ <<< "${lines[$i]}"
                    sel[$i]=$([[ "$dflt" == "1" ]] && echo 1 || echo 0)
                done
                ;;

            f)
                flatpak_sel=$((1 - flatpak_sel))
                ;;

            *)
                for tok in $input; do
                    if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        for ((n=${BASH_REMATCH[1]}; n<=${BASH_REMATCH[2]}; n++)); do
                            idx=$((n-1))

                            if [[ $idx -ge 0 && $idx -lt ${#lines[@]} ]]; then
                                sel[$idx]=$((1 - sel[$idx]))
                            fi
                        done

                    elif [[ "$tok" =~ ^[0-9]+$ ]]; then
                        idx=$((tok-1))

                        if [[ $idx -ge 0 && $idx -lt ${#lines[@]} ]]; then
                            sel[$idx]=$((1 - sel[$idx]))
                        fi
                    fi
                done
                ;;
        esac
    done
}

# ===========================================================================
# PARANCSSORI ARGUMENTUMOK
# ===========================================================================

MODE="menu"
ARG_APPS=""
DAVINCI_PATH=""
DO_FLATPAK_SWITCH=0
DO_PURGE_SNAPD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            MODE="all"
            shift
            ;;

        --defaults)
            MODE="defaults"
            shift
            ;;

        --apps)
            [[ $# -ge 2 ]] || { echo "Hiányzó alkalmazáslista."; exit 1; }
            MODE="apps"
            ARG_APPS="$2"
            shift 2
            ;;

        --list)
            MODE="list"
            shift
            ;;

        --flatpak-switch)
            DO_FLATPAK_SWITCH=1
            shift
            ;;

        --davinci)
            [[ $# -ge 2 ]] || { echo "Hiányzó .run fájl."; exit 1; }
            DAVINCI_PATH="$2"
            MODE="davinci-only"
            shift 2
            ;;

        --purge-snapd)
            DO_PURGE_SNAPD=1
            shift
            ;;

        -h|--help)
            echo "Használat:"
            echo "  sudo ./install-apps.sh"
            echo "  sudo ./install-apps.sh --defaults"
            echo "  sudo ./install-apps.sh --all"
            echo "  sudo ./install-apps.sh --apps \"Git,VLC\""
            echo "  sudo ./install-apps.sh --list"
            echo "  sudo ./install-apps.sh --flatpak-switch"
            echo "  sudo ./install-apps.sh --davinci /útvonal/fájl.run"
            echo "  sudo ./install-apps.sh --purge-snapd"
            exit 0
            ;;

        *)
            echo "Ismeretlen kapcsoló: $1"
            exit 1
            ;;
    esac
done

# ===========================================================================
# KATALÓGUS LISTÁZÁSA
# ===========================================================================

if [[ "$MODE" == "list" ]]; then
    printf '%-18s %-42s %-10s %s\n' "Kategória" "Név" "Típus" "Default"

    for line in "${CATALOG[@]}"; do
        IFS='|' read -r cat name mgr payload dflt icon_url <<< "$line"
        printf '%-18s %-42s %-10s %s\n' "$cat" "$name" "$mgr" "$dflt"
    done

    exit 0
fi

# ===========================================================================
# CSAK DAVINCI
# ===========================================================================

if [[ "$MODE" == "davinci-only" ]]; then
    install_davinci "$DAVINCI_PATH"
    exit $?
fi

# ===========================================================================
# SNAPD ELTÁVOLÍTÁSA
# ===========================================================================

if [[ "$DO_PURGE_SNAPD" == "1" ]]; then
    purge_snapd
fi

# ===========================================================================
# KIVÁLASZTÁS
# ===========================================================================

declare -a CHOSEN_LINES=()

WANT_FLATPAK_SWITCH=$DO_FLATPAK_SWITCH

case "$MODE" in
    all)
        CHOSEN_LINES=("${CATALOG[@]}")
        ;;

    defaults)
        for line in "${CATALOG[@]}"; do
            IFS='|' read -r _ _ _ _ dflt _ <<< "$line"
            [[ "$dflt" == "1" ]] && CHOSEN_LINES+=("$line")
        done
        ;;

    apps)
        IFS=',' read -ra wanted <<< "$ARG_APPS"

        for w in "${wanted[@]}"; do
            w="$(echo "$w" | sed 's/^ *//;s/ *$//')"
            found=0

            for line in "${CATALOG[@]}"; do
                IFS='|' read -r _ name _ _ _ _ <<< "$line"

                if [[ "${name,,}" == "${w,,}" ]]; then
                    CHOSEN_LINES+=("$line")
                    found=1
                fi
            done

            [[ $found -eq 0 ]] &&
                echo "Figyelem: nincs ilyen program a katalógusban: $w"
        done
        ;;

    menu)
        mapfile -t menu_out < <(show_menu)

        for line in "${menu_out[@]}"; do
            if [[ "$line" == "SYS_FLATPAK" ]]; then
                WANT_FLATPAK_SWITCH=1
                continue
            fi

            [[ -n "$line" ]] && CHOSEN_LINES+=("$line")
        done
        ;;
esac

# ===========================================================================
# ÜRES KIVÁLASZTÁS ELLENŐRZÉSE
# ===========================================================================

if [[ ${#CHOSEN_LINES[@]} -eq 0 && "$WANT_FLATPAK_SWITCH" -eq 0 ]]; then
    exit 0
fi

# ===========================================================================
# TELEPÍTÉSI FELADATOK ELŐKÉSZÍTÉSE
# ===========================================================================

APT_PKGS=()
DEB_JOBS=()
FLATPAK_JOBS=()
APPIMAGE_JOBS=()
DAVINCI_WANTED=0

for line in "${CHOSEN_LINES[@]}"; do
    IFS='|' read -r cat name mgr payload dflt icon_url <<< "$line"

    case "$mgr" in
        apt)
            read -ra pkgs <<< "$payload"
            APT_PKGS+=("${pkgs[@]}")
            ;;

        deb)
            DEB_JOBS+=("${payload}|${name}")
            ;;

        flatpak)
            FLATPAK_JOBS+=("${payload}|${name}")
            ;;

        appimage)
            APPIMAGE_JOBS+=("${payload}|${name}|${icon_url}")
            ;;

        davinci)
            DAVINCI_WANTED=1
            ;;

        *)
            log "Ismeretlen manager ('$mgr') ennél: $name, kihagyva."
            ;;
    esac
done

# ===========================================================================
# PROGRESS LÉPÉSEK SZÁMOLÁSA
# ===========================================================================

PROGRESS_TOTAL=1

if [[ ${#APT_PKGS[@]} -gt 0 ]]; then
    PROGRESS_TOTAL=$((PROGRESS_TOTAL + 1))
fi

PROGRESS_TOTAL=$((PROGRESS_TOTAL + ${#DEB_JOBS[@]}))
PROGRESS_TOTAL=$((PROGRESS_TOTAL + ${#FLATPAK_JOBS[@]}))
PROGRESS_TOTAL=$((PROGRESS_TOTAL + ${#APPIMAGE_JOBS[@]}))

if [[ "$WANT_FLATPAK_SWITCH" -eq 1 ]]; then
    PROGRESS_TOTAL=$((PROGRESS_TOTAL + 1))
fi

PROGRESS=0
PROGRESS_STEP=0
FAILED_COUNT=0

log "=== Telepítés indul ==="
log "Telepítési feladatok száma: $PROGRESS_TOTAL"

# ===========================================================================
# PROGRESS GAUGE INDÍTÁSA
# ===========================================================================

gauge_start "Alkalmazás telepítő" "Telepítés előkészítése..."

# ===========================================================================
# APT CSOMAGLISTA FRISSÍTÉSE
# ===========================================================================

progress_step "APT csomaglista frissítése..." \
    apt-get update

# ===========================================================================
# APT TELEPÍTÉS
# ===========================================================================

if [[ ${#APT_PKGS[@]} -gt 0 ]]; then
    progress_step "APT csomagok telepítése..." \
        install_apt "${APT_PKGS[@]}"
fi

# ===========================================================================
# DEB TELEPÍTÉSEK
# ===========================================================================

for job in "${DEB_JOBS[@]}"; do
    [[ -z "$job" ]] && continue

    url="${job%%|*}"
    name="${job##*|}"

    progress_step "DEB telepítés: $name" \
        install_deb "$url" "$name"
done

# ===========================================================================
# FLATPAK TELEPÍTÉSEK
# ===========================================================================

for job in "${FLATPAK_JOBS[@]}"; do
    [[ -z "$job" ]] && continue

    id="${job%%|*}"
    name="${job##*|}"

    progress_step "Flatpak telepítés: $name" \
        install_flatpak "$id" "$name"
done

# ===========================================================================
# APPIMAGE TELEPÍTÉSEK
# ===========================================================================

for job in "${APPIMAGE_JOBS[@]}"; do
    [[ -z "$job" ]] && continue

    IFS='|' read -r url name icon_url <<< "$job"

    progress_step "AppImage telepítés: $name" \
        install_appimage "$url" "$name" "$icon_url"
done

# ===========================================================================
# SNAP -> FLATPAK
# ===========================================================================

if [[ "$WANT_FLATPAK_SWITCH" -eq 1 ]]; then
    progress_step "Snap Áruház cseréje Flatpakra..." \
        switch_snap_to_flatpak
fi

# ===========================================================================
# PROGRESS GAUGE LEZÁRÁSA
# ===========================================================================

gauge_stop

# ===========================================================================
# DAVINCI RESOLVE
# ===========================================================================

if [[ "$DAVINCI_WANTED" -eq 1 ]]; then
    if install_davinci ""; then
        log "DaVinci Resolve telepítő befejeződött."
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        log "HIBA: DaVinci Resolve telepítése."
    fi
fi

# ===========================================================================
# EREDMÉNYEK
# ===========================================================================

log "=== Telepítés befejezve ==="
log "Sikertelen műveletek: $FAILED_COUNT"
log "Naplófájl: $LOG_FILE"

if [[ "$FAILED_COUNT" -eq 0 ]]; then
    SUMMARY="A telepítés sikeresen befejeződött!

Minden művelet sikeres volt.

Naplófájl:
$LOG_FILE"
else
    SUMMARY="A telepítés befejeződött, de hibák történtek.

Sikertelen műveletek: $FAILED_COUNT

A részleteket a naplófájlban találod:

$LOG_FILE"
fi

if command -v whiptail >/dev/null 2>&1 && [[ -w /dev/tty ]]; then
    whiptail --title "Telepítés befejezve" \
        --msgbox "$SUMMARY" 14 76 \
        > /dev/tty 2>&1
else
    echo "$SUMMARY"
fi

if [[ "$FAILED_COUNT" -gt 0 ]]; then
    exit 1
fi

exit 0
