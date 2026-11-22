#!/usr/bin/env python3
import argparse
import curses
import datetime
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from typing import Callable, Dict, List


@dataclass
class MenuItem:
    key: str
    title: str
    detail: str
    handler: Callable[[bool], str]
    selected: bool = False


def detect_distro() -> str:
    with open("/etc/os-release", "r", encoding="utf-8") as file:
        for line in file:
            if line.startswith("ID="):
                return line.strip().split("=")[1].strip('"')
        return "unknown"


def run_cmd(cmd: List[str], dry_run: bool,cwd: str | None = None) -> str:
    cmd_str = " ".join(cmd)
    if dry_run:
        return f"[DRY-RUN] {cmd_str}"
    res = subprocess.run(cmd, text=True, capture_output=True,cwd=cwd)
    if res.returncode != 0:
        err = res.stderr.strip() or res.stdout.strip() or f"exit {res.returncode}"
        raise RuntimeError(f"{cmd_str} -> {err}")
    return f"[OK] {cmd_str}"


def pkg_install(pkgs: List[str], type: str | None, dry_run: bool) -> str:
    distro = detect_distro()
    match type:
        case "pkg":
            match distro:
                case "arch":
                    return run_cmd(["sudo", "pacman", "-S", "--needed", "--noconfirm", *pkgs], dry_run)
                case "debian" | "ubuntu":
                    run_cmd(["sudo", "apt-get", "update"], dry_run)
                    return run_cmd(["sudo", "apt-get", "install", "-y", *pkgs], dry_run)
            raise RuntimeError("Ismeretlen disztribúció")
        case "flatpak":
            return run_cmd(["flatpak", "install", "flathub", "-y", *pkgs], dry_run)
        case "yay":
            if not shutil.which("yay"):
                run_cmd(["sudo", "pacman", "-S", "--needed", "--noconfirm", "git", "base-devel"], dry_run)
                with tempfile.TemporaryDirectory() as tmpdir:
                    yay_dir = os.path.join(tmpdir, "yay")
                    run_cmd(["git", "clone", "https://aur.archlinux.org/yay.git", yay_dir], dry_run)
                    run_cmd(["makepkg", "-si", "--noconfirm"], dry_run, cwd=yay_dir)
            return run_cmd(["yay", "-S", "--noconfirm", *pkgs], dry_run)


def make_handler(label: str, pkgs: List[str] | None = None, type: str | None = None) -> Callable[[bool], str]:
    def _fn(dry_run: bool) -> str:
        if pkgs:
            return pkg_install(pkgs, type, dry_run)
        return f"[DRY-RUN] {label}" if dry_run else f"[OK] {label}"
    return _fn

def enableGDM(dry_run: bool) -> Callable[[bool], str]:
    def _fn(dry_run: bool) -> str:
        return run_cmd(["sudo", "systemctl", "enable", "gdm", "--now"], dry_run)
    return _fn

def gnome_android(dry_run: bool) -> Callable[[bool], str]:
    def _fn(dry_run: bool) -> str:
        pkg_install(["gnome","gdm","extension-manager","gnome-shell-extension-appindicator","python-pip" ], "pkg", dry_run)
        run_cmd(["pip", "install", "gnome-extensions-cli", "--break-system-packages"], dry_run)
        return run_cmd(["gnome-extensions-cli","install", "enable", "dash-to-dock@micxgx.gmail.com"], dry_run)
    return _fn


class SplitPostInstallTUI:
    def __init__(self, categories: Dict[str, List[MenuItem]], dry_run: bool = False, log_path: str = "/tmp/postinstall.log"):
        self.category_names = list(categories.keys())
        self.categories = categories
        self.dry_run = dry_run
        self.log_path = log_path

        self.cat_idx = 0
        self.item_idx = 0
        self.focus_pane = "left"  # "left" | "right"
        self.logs: List[str] = []

    def log(self, msg: str) -> None:
        ts = datetime.datetime.now().strftime("%H:%M:%S")
        line = f"[{ts}] {msg}"
        self.logs.append(line)
        try:
            with open(self.log_path, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except OSError:
            pass

    def current_items(self) -> List[MenuItem]:
        cat = self.category_names[self.cat_idx]
        return self.categories[cat]

    def all_selected_items(self) -> List[tuple[str, MenuItem]]:
        out = []
        for cat, items in self.categories.items():
            for item in items:
                if item.selected:
                    out.append((cat, item))
        return out

    def run_selected(self, stdscr: "curses._CursesWindow") -> None:
        selected = self.all_selected_items()
        if not selected:
            self.log("Nincs kijelölve egyetlen elem sem.")
            return

        self.log(f"Futtatás indul ({len(selected)} kijelölt elem, dry_run={self.dry_run})...")
        self.draw(stdscr)

        for cat, item in selected:
            self.log(f"[{cat}] {item.title}...")
            self.draw(stdscr)
            try:
                res = item.handler(self.dry_run)
                self.log(res)
            except Exception as exc:
                self.log(f"[HIBA] {item.title}: {exc}")
            self.draw(stdscr)

        self.log("Kész.")

    def draw(self, stdscr: "curses._CursesWindow") -> None:
        stdscr.erase()
        h, w = stdscr.getmaxyx()

        if h < 14 or w < 64:
            stdscr.addnstr(0, 0, "Terminál túl kicsi (min. 64x14)", max(1, w - 1))
            stdscr.refresh()
            return

        distro = detect_distro()
        mode = "DRY-RUN" if self.dry_run else "LIVE"
        stdscr.addnstr(0, 1, f" Post-Install TUI [{distro.upper()} | {mode}] ", w - 2, curses.A_BOLD)
        stdscr.hline(1, 1, curses.ACS_HLINE, w - 2)

        log_h = 5
        main_top = 2
        main_bottom = h - log_h - 1
        main_h = max(1, main_bottom - main_top)

        # Bal keskeny sáv (kb. 24-28 oszlop)
        left_w = min(28, max(20, w // 4))
        right_x = left_w + 2
        right_w = max(10, w - right_x - 1)

        # Bal panel fejléc és kategóriák
        left_hdr_attr = curses.A_BOLD | (curses.A_UNDERLINE if self.focus_pane == "left" else 0)
        stdscr.addnstr(main_top, 1, "Kategóriák", left_w - 1, left_hdr_attr)

        for i, cat in enumerate(self.category_names):
            y = main_top + 1 + i
            if y >= main_bottom:
                break
            is_active_cat = (i == self.cat_idx)
            sel_count = sum(1 for x in self.categories[cat] if x.selected)
            badge = f" ({sel_count})" if sel_count else ""
            label = f" {cat}{badge}"

            attr = curses.A_NORMAL
            if is_active_cat and self.focus_pane == "left":
                attr = curses.A_REVERSE | curses.A_BOLD
            elif is_active_cat:
                attr = curses.A_BOLD

            stdscr.addnstr(y, 1, label.ljust(left_w - 1), left_w - 1, attr)

        # Függőleges elválasztó
        for y in range(main_top, main_bottom):
            stdscr.vline(main_top, left_w, curses.ACS_VLINE, main_h)

        # Jobb panel: az aktuális kategória elemei
        active_cat = self.category_names[self.cat_idx]
        items = self.categories[active_cat]
        right_hdr_attr = curses.A_BOLD | (curses.A_UNDERLINE if self.focus_pane == "right" else 0)
        stdscr.addnstr(main_top, right_x, f"{active_cat} - elemek", right_w, right_hdr_attr)

        list_top = main_top + 1
        list_h = max(1, main_bottom - list_top - 2)  # hely az alsó leírássornak

        if self.item_idx >= len(items):
            self.item_idx = max(0, len(items) - 1)

        for idx, item in enumerate(items[:list_h]):
            y = list_top + idx
            mark = "[x]" if item.selected else "[ ]"
            line = f"{mark} {item.title}"
            attr = curses.A_NORMAL
            if self.focus_pane == "right" and idx == self.item_idx:
                attr = curses.A_REVERSE | curses.A_BOLD
            stdscr.addnstr(y, right_x, line, right_w, attr)

        # Kiválasztott elem részletei a jobb panel alján
        if items:
            cur_item = items[self.item_idx]
            stdscr.addnstr(main_bottom - 1, right_x, f"Info: {cur_item.detail}", right_w, curses.A_DIM)

        # Alsó log sáv
        sep_y = h - log_h - 1
        stdscr.hline(sep_y, 1, curses.ACS_HLINE, w - 2)
        stdscr.addnstr(sep_y, 2, f" Log ({self.log_path}) ", w - 4, curses.A_BOLD)

        for i, line in enumerate(self.logs[-(log_h - 1):]):
            y = sep_y + 1 + i
            if y < h - 1:
                stdscr.addnstr(y, 2, line, w - 4)

        footer = " [↑/↓] Mozgás  [←/→/Tab] Panel  [Space] Jelöl  [r] Futtat  [q] Kilép "
        stdscr.addnstr(h - 1, 1, footer, w - 2, curses.A_DIM)
        stdscr.refresh()

    def run(self, stdscr: "curses._CursesWindow") -> None:
        curses.curs_set(0)
        stdscr.keypad(True)
        self.log(f"Rendszer: {detect_distro()}")

        while True:
            self.draw(stdscr)
            key = stdscr.getch()

            if key in (ord("q"), ord("Q")):
                break
            elif key in (9, curses.KEY_RIGHT):  # Tab vagy Jobb nyíl
                if self.focus_pane == "left" and self.current_items():
                    self.focus_pane = "right"
                    self.item_idx = min(self.item_idx, len(self.current_items()) - 1)
            elif key == curses.KEY_LEFT:
                self.focus_pane = "left"
            elif key == curses.KEY_UP:
                if self.focus_pane == "left":
                    self.cat_idx = (self.cat_idx - 1) % len(self.category_names)
                    self.item_idx = 0
                else:
                    items = self.current_items()
                    if items:
                        self.item_idx = (self.item_idx - 1) % len(items)
            elif key == curses.KEY_DOWN:
                if self.focus_pane == "left":
                    self.cat_idx = (self.cat_idx + 1) % len(self.category_names)
                    self.item_idx = 0
                else:
                    items = self.current_items()
                    if items:
                        self.item_idx = (self.item_idx + 1) % len(items)
            elif key == ord(" "):
                items = self.current_items()
                if items:
                    target = items[self.item_idx]
                    target.selected = not target.selected
            elif key in (ord("r"), ord("R")):
                self.run_selected(stdscr)

def menuByDistro(distro, NonArchMenu: MenuItem, ArchMenu: MenuItem | None = None) -> MenuItem:
    if distro in ("arch", "manjaro"):
        return ArchMenu
    return NonArchMenu

def build_categories() -> Dict[str, List[MenuItem]]:
    raw: Dict[str, List[MenuItem | None]] = {
        "Desktop env": [
            MenuItem("gnome-android", "GNOME Android Like", "Minimális GNOME csomagok sallang nélkül", make_handler("GNOME Core", ["gnome","gdm","extension-manager","gnome-shell-extension-appindicator" ], "pkg")),
            MenuItem("gnome-windows", "GNOME Windows Like", "GNOME csomagok Windows stílusú elrendezéssel", make_handler("GNOME Core", ["gnome","gdm","extension-manager","gnome-shell-extension-appindicator", "gnome-shell-extension-dash-to-panel"], "pkg")),
            MenuItem("gnome-custom", "Gnome Egyedi", "GNOME csomagok egyedi elrendezéssel", make_handler("GNOME Core", ["gnome","gdm","extension-manager","gnome-shell-extension-appindicator", "gnome-shell-extension-arc-menu"], "pkg")),
            MenuItem("a11y", "Kisegítő / skálázás", "Nagyobb betű/UI és kontraszt", make_handler("A11y & Scaling")),
        ],
        "Böngészők": [
            MenuItem("firefox", "Mozilla Firefox", "Webböngésző", make_handler("Firefox", ["firefox"], "pkg")),
            MenuItem("chromium", "Chromium", "Nyílt forráskódú Chrome", make_handler("Chromium", ["chromium"], "pkg")),
            MenuItem("chrome", "Google Chrome", "Google Chrome", make_handler("Chrome", ["com.google.Chrome"], "flatpak")),
            MenuItem("brave", "Brave", "Adatvédelmi böngésző", make_handler("Brave", ["com.brave.Browser"], "flatpak")),
            MenuItem("opera", "Opera", "Opera böngésző", make_handler("Opera", ["com.opera.Opera"], "flatpak")),
            MenuItem("opera-gx", "Opera GX", "Opera GX böngésző", make_handler("Opera GX", ["com.opera.opera-gx"], "flatpak")),
            MenuItem("vivaldi", "Vivaldi", "Vivaldi böngésző", make_handler("Vivaldi", ["com.vivaldi.Vivaldi"], "flatpak")),
        ],
        "Eszközök": [
            MenuItem("ptyxis", "Ptyxis terminál", "Modern GNOME terminál", make_handler("Ptyxis", ["ptyxis"], "pkg")),
            MenuItem("7-Zip", "7-Zip archiváló", "Fájlok tömörítése és kicsomagolása", make_handler("7-Zip", ["7zip"], "pkg")),
            MenuItem("GParted", "GParted partíciókezelő", "Partíciók létrehozása és kezelése", make_handler("GParted", ["gparted"], "pkg")),
            MenuItem("BleachBit", "BleachBit tisztító", "Rendszer és alkalmazások tisztítása", make_handler("BleachBit", ["bleachbit"], "pkg")),
            MenuItem("Timeshift", "Timeshift biztonsági mentés", "Rendszer visszaállítás és mentés", make_handler("Timeshift", ["timeshift"], "pkg")),
            MenuItem("HTop", "HTop folyamatos monitorozás", "Rendszer erőforrások követése", make_handler("HTop", ["htop"], "pkg")),
            MenuItem("BTop", "BTop folyamatos monitorozás", "Rendszer erőforrások követése", make_handler("BTop", ["btop"], "pkg")),
            menuByDistro(detect_distro(), MenuItem("Synaptic", "Synaptic csomagkezelő", "Csomagok telepítése és eltávolítása", make_handler("Synaptic", ["synaptic"], "pkg"))),
            MenuItem("Flatseal", "Flatseal Flatpak engedélyek", "Flatpak alkalmazások engedélyeinek kezelése", make_handler("Flatseal", ["com.github.tchx84.Flatseal"], "flatpak")),
            MenuItem("OBS Studio", "OBS Studio streaming és felvétel", "Videó streaming és felvétel", make_handler("OBS Studio", ["com.obsproject.Studio"], "flatpak")),
            MenuItem("Solaar", "Solaar Logitech eszközök kezelése", "Logitech eszközök beállítása és kezelése", make_handler("Solaar", ["solaar"], "pkg")),
            MenuItem("Remmina", "Remmina távoli asztal", "Távoli asztali kapcsolatok kezelése", make_handler("Remmina", ["remmina"], "pkg")),
        ],
        "Média": [
            MenuItem("VLC", "VLC médialejátszó", "Médiafájlok lejátszása", make_handler("VLC", ["vlc"], "pkg")),
            MenuItem("Spotify", "Spotify zenelejátszó", "Zene streaming és lejátszás", make_handler("Spotify", ["com.spotify.Client"], "flatpak")),
            MenuItem("Hakuneko", "Hakuneko manga letöltő", "Manga és webtoon letöltése", make_handler("Hakuneko", ["io.github.hakuneko.HakuNeko"], "flatpak")),
            MenuItem("Jellyfin Desktop", "Jellyfin Desktop kliens", "Jellyfin média szerver kliens", make_handler("Jellyfin Desktop", ["org.jellyfin.JellyfinDesktop"], "flatpak")),
            MenuItem("Rhythmbox", "Rhythmbox zenelejátszó", "Zenelejátszó és podcast kezelő", make_handler("Rhythmbox", ["rhythmbox"], "pkg")),
            menuByDistro(detect_distro(),MenuItem("Psysonic", "Psysonic zenelejátszó", "Zenelejátszó és podcast kezelő", make_handler("Psysonic", ["psysonic"], "pkg"))            ),
        ],
        "Szerkesztők": [
            menuByDistro(detect_distro(),
                MenuItem("Libre Office", "Libre Office", "Szövegszerkesztő, táblázatkezelő, prezentációkészítő", make_handler("LibreOffice", ["libreoffice-l10n-hu"], "pkg")),
                MenuItem("Libre Office", "Libre Office", "Szövegszerkesztő, táblázatkezelő, prezentációkészítő", make_handler("LibreOffice", ["libreoffice-hu"], "pkg"))),
            MenuItem("Bambu Studio", "Bambu Studio", "3D nyomtatás és modellezés", make_handler("Bambu Studio", ["com.bambulab.BambuStudio"], "flatpak")),
            MenuItem("GIMP", "GIMP", "Képszerkesztő és grafikai tervező", make_handler("GIMP", ["gimp"], "pkg")),
            menuByDistro(detect_distro(),
                MenuItem("Reaper", "Reaper", "Digitális audió munkaállomás", make_handler("Reaper", ["fm.reaper.Reaper"], "flatpak")),
                MenuItem("Reaper", "Reaper", "Digitális audió munkaállomás", make_handler("Reaper", ["reaper", "reapack"], "pkg"))),
            MenuItem("Handbrake", "Handbrake", "Videó konvertáló és tömörítő", make_handler("Handbrake", ["com.github.joncampbell123.HandBrake"], "flatpak")),
            menuByDistro(detect_distro(),
                MenuItem("Krita", "Krita", "Digitális festő és rajzoló", make_handler("Krita", ["org.kde.krita"], "flatpak")),
                MenuItem("Krita", "Krita", "Digitális festő és rajzoló", make_handler("Krita", ["krita"], "pkg")),
            ),
            MenuItem("FontForge", "FontForge", "Betűtípus tervező és szerkesztő", make_handler("FontForge", ["fontforge"], "pkg")),
            MenuItem("Inkscape", "Inkscape", "Vektoros grafikai szerkesztő", make_handler("Inkscape", ["inkscape"], "pkg")),
            MenuItem("Blender", "Blender", "3D modellező és animációs szoftver", make_handler("Blender", ["blender"], "pkg")),
        ],
        "Dotfiles": [
            MenuItem("fish-cfg", "Fish + prompt config", "Saját shell beállítások másolása", make_handler("Fish config")),
            MenuItem("dconf-dump", "GNOME dconf profil", "Mentett asztali beállítások", make_handler("GNOME dconf")),
        ],
        "System": [
            MenuItem("Start GDM", "Start GDM", "Indítsa el a GDM-et a bejelentkezéshez", enableGDM(False)),
        ]
    }

    return {cat: [item for item in items if item is not None] for cat, items in raw.items()}

def main() -> None:
    parser = argparse.ArgumentParser(description="Kétpaneles curses post-install TUI")
    parser.add_argument("--dry-run", action="store_true", help="Csak szimulálja a lépéseket")
    parser.add_argument("--log", default="/tmp/postinstall.log", help="Naplófájl")
    args = parser.parse_args()

    tui = SplitPostInstallTUI(categories=build_categories(), dry_run=args.dry_run, log_path=args.log)
    curses.wrapper(tui.run)


if __name__ == "__main__":
    main()
