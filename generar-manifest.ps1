# ================================================================
#  generar-manifest.ps1  -  CRW Launcher
#  Crea manifest.json a partir de lo que hay en las carpetas
#  mods\, resourcepacks\ y kubejs\ del repo. Ponlo en la carpeta principal
#  del repo (al lado de manifest.json) y ejecutalo ahi.
# ================================================================

$ErrorActionPreference = 'Stop'

# Carpeta del repo = donde esta este script
$repo = $PSScriptRoot
if ([string]::IsNullOrEmpty($repo)) { $repo = (Get-Location).Path }

# OJO: debe ser raw.githubusercontent.com, NUNCA github.com/.../tree/...
$base = 'https://raw.githubusercontent.com/FernanVL1506/crw-launcher/main'

function Leer-Carpeta([string]$carpeta, [string[]]$extensiones) {
    $lista = New-Object System.Collections.ArrayList
    $dir = Join-Path $repo $carpeta
    if (-not (Test-Path -LiteralPath $dir)) { return ,$lista }
    $archivos = Get-ChildItem -LiteralPath $dir -File | Where-Object { $extensiones -contains $_.Extension.ToLower() } | Sort-Object Name
    foreach ($a in $archivos) {
        Write-Host "  $carpeta\$($a.Name)"
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $a.FullName).Hash.ToLower()
        $item = [ordered]@{
            file   = $a.Name
            name   = $a.Name
            sha256 = $hash
            size   = $a.Length
            url    = "$base/$carpeta/$($a.Name)"
        }
        [void]$lista.Add($item)
    }
    return ,$lista
}

# Lee TODOS los archivos de una carpeta (con subcarpetas) y los lista con su
# ruta relativa (ej: kubejs/startup_scripts/casino_items.js). El launcher los
# copia a la instancia del jugador respetando esa ruta.
function Leer-Archivos([string]$carpeta) {
    $lista = New-Object System.Collections.ArrayList
    $dir = Join-Path $repo $carpeta
    if (-not (Test-Path -LiteralPath $dir)) { return ,$lista }
    $archivos = Get-ChildItem -LiteralPath $dir -File -Recurse | Sort-Object FullName
    foreach ($a in $archivos) {
        $rel = $a.FullName.Substring($repo.TrimEnd('\').Length + 1).Replace('\', '/')
        Write-Host "  $rel"
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $a.FullName).Hash.ToLower()
        $segmentos = $rel.Split('/') | ForEach-Object { [System.Uri]::EscapeDataString($_) }
        $item = [ordered]@{
            path   = $rel
            sha256 = $hash
            size   = $a.Length
            url    = "$base/" + ($segmentos -join '/')
        }
        [void]$lista.Add($item)
    }
    return ,$lista
}

Write-Host 'Leyendo mods...' -ForegroundColor Cyan
$mods = Leer-Carpeta 'mods' @('.jar')
Write-Host 'Leyendo resourcepacks...' -ForegroundColor Cyan
$packs = Leer-Carpeta 'resourcepacks' @('.zip')
Write-Host 'Leyendo kubejs...' -ForegroundColor Cyan
$extras = Leer-Archivos 'kubejs'

$manifest = [ordered]@{
    generatedAt   = (Get-Date).ToString('o')
    modCount      = $mods.Count
    mods          = $mods.ToArray()
    resourcepacks = $packs.ToArray()
    files         = $extras.ToArray()
}

$json = ConvertTo-Json -InputObject $manifest -Depth 5
$destino = Join-Path $repo 'manifest.json'
# UTF-8 sin BOM (el launcher lo lee mejor asi)
[System.IO.File]::WriteAllText($destino, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Listo: manifest.json con $($mods.Count) mods, $($packs.Count) resourcepacks y $($extras.Count) archivos extra (kubejs)." -ForegroundColor Green
Write-Host 'Ahora haz commit y push en GitHub Desktop.' -ForegroundColor Green
