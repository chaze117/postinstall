<#
.SYNOPSIS
    Alkalmazások csendes (beavatkozás nélküli) telepítése Windows alatt, választható menüvel.

.DESCRIPTION
    - Alapból winget-et használ (Windows 10 1809+ / Windows 11).
    - Ha egy program nincs a winget-ben, közvetlen letöltési URL-lel is felvehető.
    - Új program felvétele: add hozzá egy Add-App sort a KATALÓGUS részhez,
      vagy írd be egy apps.json fájlba a script mellett (lásd lent).

.PARAMETER Apps
    Telepítendő programok neve vagy winget azonosítója, vesszővel elválasztva (wildcard is jó).
    Megadásakor nincs menü.

.PARAMETER All
    Minden katalógusban szereplő program telepítése, menü nélkül.

.PARAMETER Defaults
    Csak az alapértelmezetten bejelöltek telepítése, menü nélkül.

.PARAMETER List
    A katalógus kilistázása, majd kilépés.

.EXAMPLE
    .\Install-Apps.ps1
.EXAMPLE
    .\Install-Apps.ps1 -Apps "Git","7-Zip","VLC*"
.EXAMPLE
    .\Install-Apps.ps1 -Defaults

.NOTES
    apps.json példa (a script mellé):
    [
      { "Name": "Valami", "Id": "Publisher.Valami", "Category": "Egyéb", "Default": false },
      { "Name": "Másik",  "Url": "https://pelda.hu/setup.exe", "InstallerArgs": "/S", "Category": "Egyéb" }
    ]
#>

[CmdletBinding()]
param(
    [string[]]$Apps,
    [switch]$All,
    [switch]$Defaults,
    [switch]$List
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------------
# Rendszergazdai jog kérése
# ---------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $List) {
    Write-Host 'Rendszergazdai jogosultság szükséges, újraindítás emelt módban...' -ForegroundColor Yellow
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Apps)     { $argList += '-Apps';  $argList += ($Apps | ForEach-Object { "`"$_`"" }) -join ',' }
    if ($All)      { $argList += '-All' }
    if ($Defaults) { $argList += '-Defaults' }
    Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $argList -Verb RunAs
    exit
}

# ===========================================================================
#  KATALÓGUS  –  ITT BŐVÍTHETED A LISTÁT
# ===========================================================================
# winget-es program:
#   Add-App -Name 'Megjelenített név' -Id 'winget.Azonosító' -Category 'Kategória' [-Default]
#
# Közvetlen letöltés (ha nincs winget csomag):
#   Add-App -Name 'Név' -Url 'https://.../setup.exe' -InstallerArgs '/S' -Category 'Kategória'
#   (.msi esetén az msiexec /i ... /qn automatikusan megy, az InstallerArgs kiegészítő)
#
# Azonosítót így találsz:  winget search <név>
# ---------------------------------------------------------------------------
$script:Catalog = New-Object System.Collections.Generic.List[object]

function Add-App {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Id,
        [string]$Url,
        [string]$InstallerArgs = '/S',
        [string]$Category = 'Egyéb',
        [switch]$Default
    )
    if (-not $Id -and -not $Url) { throw "Az '$Name' bejegyzéshez Id vagy Url kell." }
    $script:Catalog.Add([pscustomobject]@{
        Name          = $Name
        Id            = $Id
        Url           = $Url
        InstallerArgs = $InstallerArgs
        Category      = $Category
        Default       = [bool]$Default
    })
}

# --- Böngészők -------------------------------------------------------------
Add-App -Name 'Google Chrome'      -Id 'Google.Chrome'              -Category 'Böngészők' -Default
Add-App -Name 'Mozilla Firefox'    -Id 'Mozilla.Firefox'            -Category 'Böngészők'
Add-App -Name 'Brave'              -Id 'Brave.Brave'                -Category 'Böngészők'
Add-App -Name 'Opera'              -Id 'Opera.Opera'                -Category 'Böngészők'
Add-App -Name 'Opera GX'           -Id 'Opera.OperaGX'              -Category 'Böngészők'


# --- Eszközök --------------------------------------------------------------
Add-App -Name '7-Zip'              -Id '7zip.7zip'                  -Category 'Eszközök' -Default
Add-App -Name 'PowerToys'          -Id 'Microsoft.PowerToys'        -Category 'Eszközök'
Add-App -Name 'Everything'         -Id 'voidtools.Everything'       -Category 'Eszközök'
Add-App -Name 'Sysinternals Suite' -Id 'Microsoft.Sysinternals.ProcessExplorer' -Category 'Eszközök'
Add-App -Name 'Thunderbird' -Id 'Mozilla.Thunderbird.hu' -Category 'Eszközök'
Add-App -Name 'Google Drive' -Id 'Google.GoogleDrive' -Category 'Eszközök'
Add-App -Name 'Speedtest' -Id 'Ookla.Speedtest.Desktop' -Category 'Eszközök'
Add-App -Name 'Total Commander' -Id 'Ghisler.TotalCommander' -Category 'Eszközök'
Add-App -Name 'Win Capture Audio (OBS)' -Id 'bozbez.WinCaptureAudio.beta' -Category 'Eszközök'
Add-App -Name 'WinRar' -Id 'RARLab.WinRAR' -Category 'Eszközök'
Add-App -Name 'Bulk Rename Utility' -Id 'TGRMNSoftware.BulkRenameUtility' -Category 'Eszközök'

# --- Média -----------------------------------------------------------------
Add-App -Name 'VLC'                -Id 'VideoLAN.VLC'               -Category 'Média' -Default
Add-App -Name 'Spotify'            -Id 'Spotify.Spotify'            -Category 'Média'
Add-App -Name 'OBS Studio'         -Id 'OBSProject.OBSStudio'       -Category 'Média'
Add-App -Name 'MPC-HC'         -Id 'clsid2.mpc-hc'       -Category 'Média'
Add-App -Name 'Winamp'         -Id 'Winamp.Winamp'       -Category 'Média'
Add-App -Name 'Dopamine 3'         -Id 'Digimezzo.Dopamine.3'       -Category 'Média'
Add-App -Name 'Jellyfin Media Player'         -Id 'Jellyfin.JellyfinMediaPlayer'       -Category 'Média'

# --- Szerkesztő -----------------------------------------------------------------
Add-App -Name 'GIMP'               -Id 'GIMP.GIMP.3'                -Category 'Szerkesztő'
Add-App -Name 'Krita'              -Id 'KDE.Krita'                  -Category 'Szerkesztő'
Add-App -Name 'Inkscape'              -Id 'Inkscape.Inkscape'                  -Category 'Szerkesztő'
Add-App -Name 'Notepad++'          -Id 'Notepad++.Notepad++'        -Category 'Szerkesztő' -Default
Add-App -Name 'Bambu Studio'          -Id 'Bambulab.Bambustudio'        -Category 'Szerkesztő'
Add-App -Name 'Visual Studio Code' -Id 'Microsoft.VisualStudioCode' -Category 'Szerkesztő'
Add-App -Name 'JetBrains Rider' -Id 'Jetbrains.Rider' -Category 'Szerkesztő'
Add-App -Name 'JetBrains IntelliJ IDEA' -Id 'JetBrains.IntelliJIDEA' -Category 'Szerkesztő'
Add-App -Name 'Reaper' -Id 'Cockos.REAPER' -Category 'Szerkesztő'
Add-App -Name 'Blender' -Id 'BlenderFoundation.Blender' -Category 'Szerkesztő'




# --- Irodai / kommunikáció -------------------------------------------------
Add-App -Name 'Adobe Acrobat Reader' -Id 'Adobe.Acrobat.Reader.64-bit' -Category 'Iroda' -Default
Add-App -Name 'LibreOffice'        -Id 'TheDocumentFoundation.LibreOffice' -Category 'Iroda'
Add-App -Name 'Zoom'               -Id 'Zoom.Zoom'                  -Category 'Kommunikáció'
Add-App -Name 'Discord'            -Id 'Discord.Discord'            -Category 'Kommunikáció'
Add-App -Name 'Telegram'           -Id 'Telegram.TelegramDesktop'   -Category 'Kommunikáció'
Add-App -Name 'Viber'           -Id 'Rakuten.Viber'   -Category 'Kommunikáció'

# --- Fejlesztés ------------------------------------------------------------
Add-App -Name 'Git'                -Id 'Git.Git'                    -Category 'Fejlesztés'
Add-App -Name 'Windows Terminal'   -Id 'Microsoft.WindowsTerminal'  -Category 'Fejlesztés'
Add-App -Name 'Python 3'           -Id 'Python.Python.3.12'         -Category 'Fejlesztés'
Add-App -Name 'Node.js LTS'        -Id 'OpenJS.NodeJS.LTS'          -Category 'Fejlesztés'
Add-App -Name 'Docker Desktop'     -Id 'Docker.DockerDesktop'       -Category 'Fejlesztés'


# --- Gaming ------------------------------------------------------------
Add-App -Name 'Steam'             -Id 'Valve.Steam'              -Category 'Gaming'
Add-App -Name 'Epic Games Launcher' -Id 'EpicGames.EpicGamesLauncher' -Category 'Gaming'
Add-App -Name 'Ubisoft Connect' -Id 'Ubisoft.Connect' -Category 'Gaming'
Add-App -Name 'CurseForge' -Id 'Overwolf.CurseForge' -Category 'Gaming'
Add-App -Name 'Amazon Games' -Id 'Amazon.Games' -Category 'Gaming'
Add-App -Name 'EA App' -Id 'ElectronicArts.EADesktop' -Category 'Gaming'
Add-App -Name 'Battle.net' -Id 'Blizzard.BattleNet' -Category 'Gaming'

# --- Hardver ------------------------------------------------------------
Add-App -Name 'Razer Synapse 3'     -Id 'RazerInc.RazerInstaller.Synapse3'    -Category 'Hardver'
Add-App -Name 'Razer Synapse 4'     -Id 'RazerInc.RazerInstaller.Synapse4'    -Category 'Hardver'
Add-App -Name "G Hub" -Url 'https://download01.logi.com/web/ftp/pub/techsupport/gaming/lghub_installer.exe' -InstallerArgs '/S' -Category 'Hardver'
Add-App -Name 'GeForce Now'     -Id 'Nvidia.GeForceNow'    -Category 'Hardver'

# --- Craft Suite ------------------------------------------------------------
Add-App -Name 'PhotoCraft (Photoshop)'     -Id 'ArtCraft.PhotoCraft'    -Category 'Craft Suite'
Add-App -Name 'VectorCraft (Illustrator)'     -Id 'ArtCraft.VectorCraft'    -Category 'Craft Suite'
Add-App -Name 'PdfCraft (Acrobat)'     -Id 'ArtCraft.PdfCraft'    -Category 'Craft Suite'
Add-App -Name 'EffectCraft (After Effects)'     -Id 'ArtCraft.EffectCraft'    -Category 'Craft Suite'
Add-App -Name 'FilmCraft (Premiere)'     -Id 'ArtCraft.FilmCraft'    -Category 'Craft Suite'
Add-App -Name 'LightCraft (Lightroom)'     -Id 'ArtCraft.LightCraft'    -Category 'Craft Suite'
Add-App -Name 'SoundCraft (Audition)'     -Id 'ArtCraft.SoundCraft'    -Category 'Craft Suite'
Add-App -Name 'DesignCraft (InDesign)'     -Id 'ArtCraft.DesignCraft'    -Category 'Craft Suite'
Add-App -Name 'CadCraft (AutoCAD)'     -Id 'ArtCraft.CadCraft'    -Category 'Craft Suite'
Add-App -Name 'WordCraft (Word)'     -Id 'ArtCraft.WordCraft'    -Category 'Craft Suite'
Add-App -Name 'GridCraft (Excel)'     -Id 'ArtCraft.GridCraft'    -Category 'Craft Suite'
Add-App -Name 'DeckCraft (PowerPoint)'     -Id 'ArtCraft.DeckCraft'    -Category 'Craft Suite'
Add-App -Name 'MaterialCraft'     -Id 'ArtCraft.MaterialCraft'    -Category 'Craft Suite'
Add-App -Name 'TextureCraft'     -Id 'ArtCraft.TextureCraft'    -Category 'Craft Suite'
Add-App -Name 'AniCraft'     -Url 'https://github.com/storytold/anicraft/releases/download/v0.2.1/anicraft-0.2.1-windows-x64.msi' -InstallerArgs '/qn'  -Category 'Craft Suite'
Add-App -Name 'FigCraft'     -Url 'https://github.com/storytold/figcraft/releases/download/v0.18.1/figcraft-0.18.1-windows-x64.msi' -InstallerArgs '/qn'  -Category 'Craft Suite'

# --- Runtimes ------------------------------------------------------------
Add-App -Name 'Visual C++ Redistributable AIO'     -Id 'abbodi1406.vcredist'    -Category 'Runtimes'
Add-App -Name 'DirectX End-User Runtime'     -Id 'Microsoft.DirectX'    -Category 'Runtimes'
Add-App -Name 'Microsoft .NET Windows Desktop Runtime 8.0'     -Id 'Microsoft.DotNet.Runtime.8'    -Category 'Runtimes'
Add-App -Name 'Microsoft .NET Runtime 10.0'     -Id 'Microsoft.DotNet.Runtime.10'    -Category 'Runtimes'
Add-App -Name 'Microsoft .NET Desktop Runtime 10.0' -Id 'Microsoft.DotNet.DesktopRuntime.10' -Category 'Runtimes'
Add-App -Name 'Java 8'     -Id 'Oracle.JavaRuntimeEnvironment'    -Category 'Runtimes'

# --- Példa közvetlen letöltésre (kikommentezve) ----------------------------
# Add-App -Name 'Saját program' -Url 'https://pelda.hu/setup.exe' -InstallerArgs '/S' -Category 'Egyéb'

# ===========================================================================
#  Külső apps.json betöltése (opcionális)
# ===========================================================================
$extFile = Join-Path (Split-Path -Parent $PSCommandPath) 'apps.json'
if (Test-Path $extFile) {
    try {
        foreach ($e in (Get-Content $extFile -Raw -Encoding UTF8 | ConvertFrom-Json)) {
            $p = @{ Name = $e.Name }
            if ($e.Id)            { $p.Id = $e.Id }
            if ($e.Url)           { $p.Url = $e.Url }
            if ($e.InstallerArgs) { $p.InstallerArgs = $e.InstallerArgs }
            if ($e.Category)      { $p.Category = $e.Category }
            if ($e.Default)       { $p.Default = $true }
            Add-App @p
        }
    } catch {
        Write-Warning "Az apps.json nem olvasható: $($_.Exception.Message)"
    }
}

# ===========================================================================
#  Telepítő logika
# ===========================================================================
# winget kilépési kódok, amiket nem hibaként kezelünk
$WingetOk = @{
    0           = 'Telepítve'
    3010        = 'Telepítve (újraindítás szükséges)'
    -1978335135 = 'Már telepítve'          # 0x8A150061
    -1978335189 = 'Már telepítve, nincs frissítés'  # 0x8A15002B
}

function Test-Winget {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Install-WingetApp([pscustomobject]$App) {
    $wingetArgs = @(
        'install', '--id', $App.Id, '--exact', '--source', 'winget',
        '--silent', '--disable-interactivity',
        '--accept-package-agreements', '--accept-source-agreements'
    )
    & winget @wingetArgs | Out-Host
    return $LASTEXITCODE
}

function Install-DirectApp([pscustomobject]$App) {
    $ext  = [IO.Path]::GetExtension(([uri]$App.Url).AbsolutePath)
    if (-not $ext) { $ext = '.exe' }
    $file = Join-Path $env:TEMP ("inst_{0}{1}" -f ([guid]::NewGuid().ToString('N')), $ext)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Write-Host "  Letöltés: $($App.Url)"
        Invoke-WebRequest -Uri $App.Url -OutFile $file -UseBasicParsing

        if ($ext -ieq '.msi') {
            $proc = Start-Process msiexec.exe -ArgumentList "/i `"$file`" /qn /norestart $($App.InstallerArgs)" -Wait -PassThru
        } else {
            $proc = Start-Process $file -ArgumentList $App.InstallerArgs -Wait -PassThru
        }
        return $proc.ExitCode
    } finally {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
    }
}

function Install-App([pscustomobject]$App) {
    if ($App.Id) { return Install-WingetApp $App } else { return Install-DirectApp $App }
}

# ===========================================================================
#  Menü
# ===========================================================================
function Show-SimpleMenu {
    $sel = @{}
    for ($i = 0; $i -lt $script:Catalog.Count; $i++) { $sel[$i] = $script:Catalog[$i].Default }

    while ($true) {
        Clear-Host
        Write-Host '=== Alkalmazás telepítő ===' -ForegroundColor Cyan
        Write-Host 'Számokkal ki/be kapcsolhatsz (pl. 1,3,5-8). a = mind, n = semmi, d = alapértelmezett,'
        Write-Host 'Enter = telepítés indítása, q = kilépés.' -ForegroundColor DarkGray
        Write-Host ''

        $lastCat = $null
        for ($i = 0; $i -lt $script:Catalog.Count; $i++) {
            $app = $script:Catalog[$i]
            if ($app.Category -ne $lastCat) {
                Write-Host "  -- $($app.Category) --" -ForegroundColor Yellow
                $lastCat = $app.Category
            }
            $mark  = if ($sel[$i]) { '[x]' } else { '[ ]' }
            $color = if ($sel[$i]) { 'Green' } else { 'Gray' }
            Write-Host ('  {0,3}. {1} {2}' -f ($i + 1), $mark, $app.Name) -ForegroundColor $color
        }

        $count = ($sel.Values | Where-Object { $_ }).Count
        Write-Host ''
        $in = (Read-Host "Kijelölve: $count db. Választás").Trim().ToLower()

        switch -Regex ($in) {
            '^$' { if ($count -eq 0) { continue } else { return @(0..($script:Catalog.Count - 1) | Where-Object { $sel[$_] } | ForEach-Object { $script:Catalog[$_] }) } }
            '^q$' { return @() }
            '^a$' { for ($i = 0; $i -lt $script:Catalog.Count; $i++) { $sel[$i] = $true }; continue }
            '^n$' { for ($i = 0; $i -lt $script:Catalog.Count; $i++) { $sel[$i] = $false }; continue }
            '^d$' { for ($i = 0; $i -lt $script:Catalog.Count; $i++) { $sel[$i] = $script:Catalog[$i].Default }; continue }
            default {
                foreach ($tok in ($in -split '[,\s]+' | Where-Object { $_ })) {
                    if ($tok -match '^(\d+)-(\d+)$') { $range = [int]$Matches[1]..[int]$Matches[2] }
                    elseif ($tok -match '^\d+$')     { $range = @([int]$tok) }
                    else { continue }
                    foreach ($n in $range) {
                        $idx = $n - 1
                        if ($idx -ge 0 -and $idx -lt $script:Catalog.Count) { $sel[$idx] = -not $sel[$idx] }
                    }
                }
            }
        }
    }
}

# ===========================================================================
#  Főprogram
# ===========================================================================
# ---------------------------------------------------------------------------
#  whiptail / dialog stílusú TUI menü (nyilak, szóköz, Enter, Esc)
# ---------------------------------------------------------------------------
function Show-TuiMenu {
    $bx = @{
        TL = [string][char]0x250C; TR = [string][char]0x2510
        BL = [string][char]0x2514; BR = [string][char]0x2518
        H  = [string][char]0x2500; V  = [string][char]0x2502
        LT = [string][char]0x251C; RT = [string][char]0x2524
    }

    # Sorok: kategóriafejlécek + programok (kategóriánként csoportosítva)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($g in ($script:Catalog | Group-Object Category)) {
        $rows.Add(@{ Type = 'H'; Text = $g.Name })
        foreach ($app in $g.Group) {
            $rows.Add(@{ Type = 'I'; App = $app; Sel = [bool]$app.Default })
        }
    }

    # Méretek
    $winW = [Console]::WindowWidth
    $winH = [Console]::WindowHeight
    $dw   = [Math]::Min(80, $winW - 6)                       # dialógus szélesség
    $lh   = [Math]::Max(3, [Math]::Min($rows.Count, $winH - 11))  # látható listasorok
    $dh   = $lh + 7                                          # dialógus magasság
    $iw   = $dw - 4                                          # lista belső szélesség
    $x0   = [int][Math]::Floor(($winW - $dw) / 2)
    $y0   = [int][Math]::Floor(($winH - $dh - 1) / 2)

    function Put([int]$x, [int]$y, [string]$t, $fg, $bg) {
        [Console]::SetCursorPosition($x, $y)
        [Console]::ForegroundColor = $fg
        [Console]::BackgroundColor = $bg
        [Console]::Write($t)
    }

    function Fit([string]$t, [int]$w) {
        if ($w -le 0) { return '' }
        if ($t.Length -gt $w) { return $t.Substring(0, $w - 1) + [string][char]0x2026 }
        return $t.PadRight($w)
    }

    function Next-Item([int]$from, [int]$dir) {
        $j = $from + $dir
        while ($j -ge 0 -and $j -lt $rows.Count) {
            if ($rows[$j].Type -eq 'I') { return $j }
            $j += $dir
        }
        return $from
    }

    function Draw-Frame {
        [Console]::BackgroundColor = 'Blue'
        [Console]::Clear()
        # árnyék
        for ($r = 1; $r -le $dh; $r++) { Put ($x0 + 2) ($y0 + $r) (' ' * $dw) 'Black' 'Black' }
        # ablak háttér
        for ($r = 0; $r -lt $dh; $r++) { Put $x0 ($y0 + $r) (' ' * $dw) 'Black' 'Gray' }
        # keret
        $hl = [string]$bx.H * ($dw - 2)
        Put $x0 $y0 ($bx.TL + $hl + $bx.TR) 'White' 'Gray'
        for ($r = 1; $r -lt ($dh - 1); $r++) {
            Put $x0 ($y0 + $r) $bx.V 'White' 'Gray'
            Put ($x0 + $dw - 1) ($y0 + $r) $bx.V 'White' 'Gray'
        }
        Put $x0 ($y0 + $dh - 1) ($bx.BL + $hl + $bx.BR) 'White' 'Gray'
        # cím
        $title = ' Alkalmazás telepítő '
        Put ($x0 + [int][Math]::Floor(($dw - $title.Length) / 2)) $y0 $title 'DarkBlue' 'Gray'
        # súgó
        $ud = "$([char]0x2191)$([char]0x2193)"
        Put ($x0 + 3) ($y0 + 2) (Fit "Szóköz: ki/be  ${ud}: mozgás  A: mind  N: semmi  D: alap  Esc: mégse" ($dw - 6)) 'Black' 'Gray'
    }

    function Draw-List {
        for ($r = 0; $r -lt $lh; $r++) {
            $idx = $top + $r
            $y   = $y0 + 4 + $r
            if ($idx -ge $rows.Count) { Put ($x0 + 2) $y (' ' * $iw) 'Black' 'Gray'; continue }
            $row = $rows[$idx]

            if ($row.Type -eq 'H') {
                $t    = " $($row.Text) "
                $left = [int][Math]::Floor(($iw - $t.Length) / 2)
                $line = ([string]$bx.H * [Math]::Max(0, $left)) + $t
                $line = $line + ([string]$bx.H * [Math]::Max(0, $iw - $line.Length))
                Put ($x0 + 2) $y (Fit $line $iw) 'DarkRed' 'Gray'
            }
            else {
                $mark  = if ($row.Sel) { '[x]' } else { '[ ]' }
                $right = if ($row.App.Id) { [string]$row.App.Id } else { 'letöltés' }
                $rw    = [Math]::Min($right.Length, [int][Math]::Floor($iw / 2) - 2)
                $rt    = if ($right.Length -gt $rw) { $right.Substring(0, $rw) } else { $right }
                $rt    = $rt.PadLeft($rw)
                $text  = (Fit " $mark $($row.App.Name)" ($iw - $rw - 2)) + ' ' + $rt + ' '
                if ($idx -eq $cursor) { Put ($x0 + 2) $y $text 'White' 'Blue' }
                else                  { Put ($x0 + 2) $y $text 'Black' 'Gray' }
            }
        }
    }

    function Draw-Footer {
        # elválasztó + számláló
        $sepY  = $y0 + 4 + $lh
        $count = @($rows | Where-Object { $_.Type -eq 'I' -and $_.Sel }).Count
        Put $x0 $sepY ($bx.LT + ([string]$bx.H * ($dw - 2)) + $bx.RT) 'White' 'Gray'
        Put ($x0 + 3) $sepY " Kijelölve: $count " 'Black' 'Gray'

        # gombok
        $by = $y0 + 5 + $lh
        Put ($x0 + 1) $by (' ' * ($dw - 2)) 'Black' 'Gray'
        $okT = '<  Telepítés  >'
        $caT = '<  Mégse  >'
        $okX = $x0 + [int][Math]::Floor($dw / 4) - [int][Math]::Floor($okT.Length / 2)
        $caX = $x0 + [int][Math]::Floor(3 * $dw / 4) - [int][Math]::Floor($caT.Length / 2)
        if ($btn -eq 0) { Put $okX $by $okT 'White' 'Blue'; Put $caX $by $caT 'Black' 'Gray' }
        else            { Put $okX $by $okT 'Black' 'Gray'; Put $caX $by $caT 'White' 'Blue' }
    }

    $cursor = Next-Item -1 1
    $top    = 0
    $btn    = 0          # 0 = Telepítés, 1 = Mégse
    $done   = $false
    $result = @()
    $oldCursorVisible = $true
    try { $oldCursorVisible = [Console]::CursorVisible } catch { }

    try {
        [Console]::CursorVisible = $false
        Draw-Frame

        while (-not $done) {
            # görgetés igazítása
            if ($cursor -lt $top) {
                $top = $cursor
                if ($top -gt 0 -and $rows[$top - 1].Type -eq 'H') { $top-- }
            }
            if ($cursor -ge ($top + $lh)) { $top = $cursor - $lh + 1 }

            Draw-List
            Draw-Footer

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'    { $cursor = Next-Item $cursor -1 }
                'DownArrow'  { $cursor = Next-Item $cursor 1 }
                'PageUp'     { for ($k = 0; $k -lt $lh; $k++) { $cursor = Next-Item $cursor -1 } }
                'PageDown'   { for ($k = 0; $k -lt $lh; $k++) { $cursor = Next-Item $cursor 1 } }
                'Home'       { $cursor = Next-Item -1 1 }
                'End'        { $cursor = Next-Item $rows.Count -1 }
                'Spacebar'   { $rows[$cursor].Sel = -not $rows[$cursor].Sel }
                'A'          { foreach ($r in $rows) { if ($r.Type -eq 'I') { $r.Sel = $true } } }
                'N'          { foreach ($r in $rows) { if ($r.Type -eq 'I') { $r.Sel = $false } } }
                'D'          { foreach ($r in $rows) { if ($r.Type -eq 'I') { $r.Sel = [bool]$r.App.Default } } }
                'LeftArrow'  { $btn = 0 }
                'RightArrow' { $btn = 1 }
                'Tab'        { $btn = 1 - $btn }
                'Escape'     { $done = $true; $result = @() }
                'Enter' {
                    if ($btn -eq 1) { $done = $true; $result = @() }
                    else {
                        $picked = @($rows | Where-Object { $_.Type -eq 'I' -and $_.Sel } | ForEach-Object { $_.App })
                        if ($picked.Count -gt 0) { $done = $true; $result = $picked }
                    }
                }
            }
        }
    }
    finally {
        [Console]::ResetColor()
        try { [Console]::CursorVisible = $oldCursorVisible } catch { }
        Clear-Host
    }
    return $result
}

# TUI, ha a konzol támogatja, különben egyszerű számozott menü
function Show-Menu {
    $canTui = ($Host.Name -eq 'ConsoleHost') -and
              (-not [Console]::IsOutputRedirected) -and
              (-not [Console]::IsInputRedirected) -and
              ([Console]::WindowWidth -ge 60) -and
              ([Console]::WindowHeight -ge 16)
    if ($canTui) {
        try { return Show-TuiMenu }
        catch { Write-Warning "A grafikus menü nem indítható ($($_.Exception.Message)), egyszerű menüre váltok." }
    }
    return Show-SimpleMenu
}

if ($List) {
    $script:Catalog | Format-Table Category, Name, Id, Url, Default -AutoSize
    exit
}

# Kiválasztás
if ($Apps) {
    $selected = @($script:Catalog | Where-Object {
        $app = $_
        $Apps | Where-Object { $app.Name -like $_ -or ($app.Id -and $app.Id -like $_) }
    })
    $unknown = $Apps | Where-Object {
        $pat = $_
        -not ($script:Catalog | Where-Object { $_.Name -like $pat -or ($_.Id -and $_.Id -like $pat) })
    }
    foreach ($u in $unknown) { Write-Warning "Nincs ilyen program a katalógusban: $u" }
}
elseif ($All)      { $selected = @($script:Catalog) }
elseif ($Defaults) { $selected = @($script:Catalog | Where-Object Default) }
else               { $selected = @(Show-Menu) }

if ($selected.Count -eq 0) { Write-Host 'Nincs telepítendő program.'; exit }

# winget ellenőrzés (csak ha kell)
if (($selected | Where-Object Id) -and -not (Test-Winget)) {
    Write-Host 'A winget nem található.' -ForegroundColor Red
    Write-Host 'Telepítsd a Microsoft Store-ból az "App Installer" csomagot, majd futtasd újra a scriptet.'
    exit 1
}

# Naplózás
$logFile = Join-Path $env:TEMP ("Install-Apps_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
Start-Transcript -Path $logFile | Out-Null

$results = New-Object System.Collections.Generic.List[object]
$i = 0
foreach ($app in $selected) {
    $i++
    Write-Host ''
    Write-Host ("[{0}/{1}] {2}" -f $i, $selected.Count, $app.Name) -ForegroundColor Cyan
    try {
        $code = Install-App $app
        $status = if ($WingetOk.ContainsKey([int]$code)) { $WingetOk[[int]$code] }
                  elseif ($code -eq 0)                    { 'Telepítve' }
                  else                                    { "HIBA (kód: $code)" }
        $ok = $WingetOk.ContainsKey([int]$code)
    } catch {
        $status = "HIBA: $($_.Exception.Message)"
        $ok = $false
    }
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host "  -> $status" -ForegroundColor $color
    $results.Add([pscustomobject]@{ Program = $app.Name; Eredmény = $status; Sikeres = $ok })
}

Write-Host ''
Write-Host '=== Összegzés ===' -ForegroundColor Cyan
$results | Format-Table Program, Eredmény -AutoSize
$failed = @($results | Where-Object { -not $_.Sikeres }).Count
Write-Host ("Kész: {0} sikeres, {1} sikertelen. Napló: {2}" -f ($results.Count - $failed), $failed, $logFile)
Stop-Transcript | Out-Null
if ($failed -gt 0) { exit 1 }
