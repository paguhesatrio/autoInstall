# =====================================================================
#  update-khanza.ps1
#  Sinkronkan D:\ClientKhanza dengan share Samba read-only (via symlink)
#  - File/folder di server  -> dibuat symlink di target (ikut update)
#  - Folder setting & cache -> jadi folder LOKAL (bisa ditulis)
#  - database.xml           -> TIDAK disentuh (config lokal per-PC)
#  - File yang dihapus di server -> symlink-nya ikut dihapus
# =====================================================================

# ---------- PENGATURAN (ubah sesuai kebutuhan) ----------
$source       = "\\172.16.17.222\ClientKhanza"    # share Samba di server
$target       = "D:\ClientKhanza"           # folder lokal tujuan
$localFolders = @("setting", "cache")       # folder yang jadi lokal (writable)
$skipFiles    = @("database.xml")           # file lokal per-PC, jangan disentuh
# --------------------------------------------------------

# --- Hubungkan ke share memakai kredensial tersimpan (Credential Manager, dari langkah 1) ---

# Putuskan koneksi lama ke share ini (abaikan kalau memang belum ada),
# lalu buat koneksi baru memakai kredensial tersimpan.
net use $source /delete /y     2>$null | Out-Null
net use $source /persistent:yes 2>$null | Out-Null

# Pastikan folder tujuan ada
if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target | Out-Null
    Write-Host "Folder tujuan dibuat: $target"
}

# Pastikan source bisa diakses
if (-not (Test-Path $source)) {
    Write-Host ""
    Write-Host "ERROR: Tidak bisa mengakses $source" -ForegroundColor Red
    Write-Host "Pastikan share aktif, IP benar, dan user/password Samba cocok." -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "=== 1. Membuat / memperbarui symlink dari server ===" -ForegroundColor Cyan

Get-ChildItem $source -Force | ForEach-Object {
    $name = $_.Name
    $link = Join-Path $target $name

    if ($_.PSIsContainer -and ($localFolders -contains $name)) {
        # --- Folder lokal (setting/cache): folder asli + symlink per-isi ---
        if (-not (Test-Path $link)) {
            New-Item -ItemType Directory -Path $link | Out-Null
            Write-Host "  [folder lokal] $name"
        }
        Get-ChildItem $_.FullName -Force | ForEach-Object {
            $subName = $_.Name
            $subLink = Join-Path $link $subName
            if (($skipFiles -notcontains $subName) -and (-not (Test-Path $subLink))) {
                if ($_.PSIsContainer) {
                    cmd /c mklink /D "`"$subLink`"" "`"$($_.FullName)`"" | Out-Null
                } else {
                    cmd /c mklink "`"$subLink`"" "`"$($_.FullName)`"" | Out-Null
                }
                Write-Host "    + $name\$subName"
            }
        }
    }
    elseif (-not (Test-Path $link)) {
        # --- Item lain: symlink biasa ---
        if ($_.PSIsContainer) {
            cmd /c mklink /D "`"$link`"" "`"$($_.FullName)`"" | Out-Null
        } else {
            cmd /c mklink "`"$link`"" "`"$($_.FullName)`"" | Out-Null
        }
        Write-Host "  + $name"
    }
}

Write-Host ""
Write-Host "=== 2. Membersihkan sinkronisasi yang sumbernya hilang di server ===" -ForegroundColor Cyan

Get-ChildItem $target -Force | ForEach-Object {
    $name = $_.Name

    if ($localFolders -contains $name) {
        # Folder lokal (setting/cache): periksa isinya satu per satu
        $srcFolder = Join-Path $source $name
        Get-ChildItem $_.FullName -Force | ForEach-Object {
            $subName = $_.Name
            if ($skipFiles -contains $subName) { return }   # lindungi database.xml lokal
            if ($_.LinkType) {                              # hanya symlink/junction
                if (-not (Test-Path (Join-Path $srcFolder $subName))) {
                    $_.Delete()
                    Write-Host "  - $name\$subName (dihapus, sumber tidak ada)"
                }
            }
        }
    }
    else {
        # Item level atas: hapus kalau symlink & sumbernya hilang
        if ($_.LinkType) {
            if (-not (Test-Path (Join-Path $source $name))) {
                $_.Delete()
                Write-Host "  - $name (dihapus, sumber tidak ada)"
            }
        }
    }
}

Write-Host ""
Write-Host "Selesai." -ForegroundColor Green
Write-Host ""