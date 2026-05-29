#Requires -Version 5.1
<#
.SYNOPSIS
    Installe une extension PHP depuis pecl.php.net (Herd, NTS x64).

.DESCRIPTION
    - Detecte la derniere version de l'extension sur pecl.php.net
    - Telecharge le zip NTS x64 correspondant
    - Copie les DLL de support (CORE_*, FILTER_*, IM_*, lib*, etc.) dans le dossier PHP
    - Place php_<ext>.dll et php_<ext>.pdb dans le dossier ext
    - Ajoute extension=<ext> dans php.ini si absent

.PARAMETER Extension
    Nom de l'extension a installer (ex: imagick, redis, xdebug, mongodb, etc.)

.PARAMETER PhpVersion
    Version PHP cible (ex: 8.4, 8.5). Par defaut: version courante depuis .phpversion

.PARAMETER ExtVersion
    Version de l'extension a installer. Par defaut: detectee automatiquement depuis pecl.

.PARAMETER VsVersion
    Version du compilateur Visual Studio (ex: vs16, vs17). Par defaut: vs17

.PARAMETER ThreadSafe
    Si specifie, utilise la version Thread Safe (ts) au lieu de Non Thread Safe (nts).

.EXAMPLE
    .\install-php-ext.ps1 -Extension imagick
    .\install-php-ext.ps1 -Extension redis -PhpVersion 8.4
    .\install-php-ext.ps1 -Extension mongodb -PhpVersion 8.5 -ExtVersion 1.19.0
    .\install-php-ext.ps1 -Extension imagick -PhpVersion 8.5 -ThreadSafe
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Extension,

    [string]$PhpVersion,
    [string]$ExtVersion,
    [string]$VsVersion = 'vs17',
    [switch]$ThreadSafe
)

$ErrorActionPreference = 'Stop'

$HerdHome = "$env:USERPROFILE\.config\herd\bin"
$ts = if ($ThreadSafe) { 'ts' } else { 'nts' }

# --- Resolve PHP version ---
if (-not $PhpVersion) {
    $phpVersionFile = "$env:USERPROFILE\.bin\.phpversion"
    if (Test-Path $phpVersionFile) {
        $PhpVersion = (Get-Content $phpVersionFile -Raw).Trim()
    } else {
        Write-Error "Impossible de determiner la version PHP. Utilise -PhpVersion."
        exit 1
    }
}

$phpFolder = "php$($PhpVersion -replace '\.','')"
$phpDir = Join-Path $HerdHome $phpFolder

if (-not (Test-Path (Join-Path $phpDir 'php.exe'))) {
    Write-Error "PHP $PhpVersion introuvable dans $phpDir"
    exit 1
}

Write-Host "PHP $PhpVersion trouve dans: $phpDir" -ForegroundColor Cyan

# --- Resolve extension version (scrape latest from pecl) ---
if (-not $ExtVersion) {
    Write-Host "Detection de la derniere version de '$Extension' sur pecl.php.net..." -ForegroundColor Yellow
    try {
        $peclPage = Invoke-WebRequest -Uri "https://pecl.php.net/package/$Extension" -UseBasicParsing
        if ($peclPage.Content -match "/package/$Extension/(\d+\.\d+\.\d+)") {
            $ExtVersion = $Matches[1]
        } else {
            Write-Error "Impossible de detecter la version de '$Extension'. Utilise -ExtVersion."
            exit 1
        }
    } catch {
        Write-Error "Erreur lors de la detection de la version: $_`nVerifie que '$Extension' existe sur https://pecl.php.net/package/$Extension"
        exit 1
    }
}

Write-Host "Extension: $Extension $ExtVersion" -ForegroundColor Cyan

# --- Build download URL ---
$phpMajorMinor = $PhpVersion -replace '^(\d+\.\d+).*', '$1'
$zipName = "php_$Extension-$ExtVersion-$phpMajorMinor-$ts-$VsVersion-x64.zip"
$downloadUrl = "https://downloads.php.net/~windows/pecl/releases/$Extension/$ExtVersion/$zipName"

Write-Host "Telechargement: $downloadUrl" -ForegroundColor Yellow

# --- Download ---
$tempDir = Join-Path $env:TEMP "php-ext-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$zipPath = Join-Path $tempDir $zipName

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Error "Echec du telechargement.`nURL: $downloadUrl`nErreur: $_`n`nVerifie que la combinaison extension/version/php est disponible sur:`nhttps://pecl.php.net/package/$Extension/$ExtVersion/windows"
    exit 1
}

Write-Host "Telechargement OK." -ForegroundColor Green

# --- Extract ---
$extractDir = Join-Path $tempDir 'extracted'
Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

# --- Identify files to copy ---
$allFiles = Get-ChildItem -Path $extractDir -File
$extDir = Join-Path $phpDir 'ext'

if (-not (Test-Path $extDir)) {
    New-Item -ItemType Directory -Path $extDir -Force | Out-Null
}

# Extension DLL and PDB go to ext/
$extDlls = $allFiles | Where-Object { $_.Name -match "^php_$Extension\.(dll|pdb)$" }

# Support files that go next to php.exe depend on the extension.
# Each extension may ship different support DLLs with specific prefixes.
$supportPatterns = @{
    'imagick' = '^(CORE_|FILTER_|IM_)'
}

if ($supportPatterns.ContainsKey($Extension)) {
    # Use known patterns for this extension
    $pattern = $supportPatterns[$Extension]
    $supportFiles = $allFiles | Where-Object {
        $_.Name -match $pattern
    }
} else {
    # Generic fallback: all DLL/PDB/EXE that are not the extension itself
    $supportFiles = $allFiles | Where-Object {
        $_.Name -notmatch "^php_$Extension\.(dll|pdb)$" -and
        $_.Extension -in @('.dll', '.pdb', '.exe')
    }
}

# --- Copy support files to PHP dir ---
if ($supportFiles.Count -gt 0) {
    Write-Host "Copie de $($supportFiles.Count) fichiers de support vers $phpDir..." -ForegroundColor Yellow
    foreach ($file in $supportFiles) {
        Copy-Item -Path $file.FullName -Destination $phpDir -Force
    }
}

# --- Copy extension DLL/PDB to ext/ ---
foreach ($file in $extDlls) {
    Copy-Item -Path $file.FullName -Destination $extDir -Force
    Write-Host "  -> ext\$($file.Name)" -ForegroundColor Green
}

if ($extDlls.Count -eq 0) {
    Write-Warning "Aucun fichier php_$Extension.dll trouve dans l'archive. Contenu:"
    $allFiles | ForEach-Object { Write-Host "    $($_.Name)" }
}

# --- Add extension to php.ini ---
$phpIni = Join-Path $phpDir 'php.ini'
if (Test-Path $phpIni) {
    $iniContent = Get-Content $phpIni -Raw
    # Handle both extension=name and zend_extension=name (for xdebug, opcache, etc.)
    $isZendExt = $Extension -in @('xdebug', 'opcache', 'ionCube')
    $directive = if ($isZendExt) { "zend_extension" } else { "extension" }

    if ($iniContent -notmatch "(?m)^\s*$directive\s*=\s*$Extension") {
        Write-Host "Ajout de '$directive=$Extension' dans php.ini..." -ForegroundColor Yellow
        Add-Content -Path $phpIni -Value "`n$directive=$Extension"
        Write-Host "php.ini mis a jour." -ForegroundColor Green
    } else {
        Write-Host "$directive=$Extension deja present dans php.ini." -ForegroundColor Green
    }
} else {
    Write-Warning "php.ini introuvable dans $phpDir. Ajoute manuellement: extension=$Extension"
}

# --- Cleanup ---
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# --- Verify ---
Write-Host "`nVerification..." -ForegroundColor Cyan
$phpExe = Join-Path $phpDir 'php.exe'
$result = & $phpExe -d "extension_dir=$extDir" -m 2>&1
if ($result -match $Extension) {
    Write-Host "$Extension $ExtVersion installe avec succes pour PHP $PhpVersion!" -ForegroundColor Green
} else {
    Write-Warning "$Extension ne semble pas charge. Verifie avec:`n  $phpExe -d `"extension_dir=$extDir`" -m"
}
