# ================================================================
#  generar-manifest.ps1  -  CRW Launcher
#  Crea manifest.json a partir de lo que hay en las carpetas
#  mods\ y resourcepacks\ del repo. Ponlo en la carpeta principal
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

Write-Host 'Leyendo mods...' -ForegroundColor Cyan
$mods = Leer-Carpeta 'mods' @('.jar')
Write-Host 'Leyendo resourcepacks...' -ForegroundColor Cyan
$packs = Leer-Carpeta 'resourcepacks' @('.zip')

$manifest = [ordered]@{
    generatedAt   = (Get-Date).ToString('o')
    modCount      = $mods.Count
    mods          = $mods.ToArray()
    resourcepacks = $packs.ToArray()
}

$json = ConvertTo-Json -InputObject $manifest -Depth 5
$destino = Join-Path $repo 'manifest.json'
# UTF-8 sin BOM (el launcher lo lee mejor asi)
[System.IO.File]::WriteAllText($destino, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Listo: manifest.json con $($mods.Count) mods y $($packs.Count) resourcepacks." -ForegroundColor Green
Write-Host 'Ahora haz commit y push en GitHub Desktop.' -ForegroundColor Green
