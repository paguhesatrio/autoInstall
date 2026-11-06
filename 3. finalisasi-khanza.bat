@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  finalisasi-khanza.bat
REM  Jalankan SETELAH map-clientkhanza.bat dan "2. update.bat".
REM  1) Shortcut "SIMRS Khanza" di Desktop (icon rspmk.ico)
REM  2) Shortcut "Update Khanza" di Desktop (icon update-khanza.ico)
REM  3) Pilih database.xml dari setting\kumpulan xml\<pilihan>
REM     lalu buat symlink -> setting\database.xml
REM  Butuh Administrator (untuk mklink) -> otomatis minta elevasi.
REM  CATATAN: file "2. update.bat" HARUS ada di folder yang sama
REM           dengan file ini.
REM ============================================================

REM --- Minta hak Administrator kalau belum ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM --- Tentukan lokasi instalasi: D dulu, kalau tidak ada baru C ---
REM     (harus sama persis dengan logika di "2. update.bat")
if exist "D:\ClientKhanza\" (
    set "BASE=D:\ClientKhanza"
) else (
    set "BASE=C:\ClientKhanza"
)

set "SETTING=%BASE%\setting"
set "KUMPULAN=%SETTING%\kumpulan xml"
set "ICON_APP=%BASE%\rspmk.ico"
set "ICON_UPD=%BASE%\update-khanza.ico"
set "TARGET_APP=%BASE%\Aplikasi.bat"
set "UPDATEDIR=%~dp0"
set "UPDATEBAT=%UPDATEDIR%2. update.bat"
set "SERVER=\\172.16.17.222\ClientKhanza"

if not exist "%BASE%\" (
    echo ERROR: folder "%BASE%" tidak ditemukan.
    echo Jalankan "2. update.bat" lebih dulu.
    goto :selesai
)
echo Lokasi instalasi terdeteksi: %BASE%
if exist "%~dp0icon\update-khanza-new.ico" copy /y "%~dp0icon\update-khanza-new.ico" "%BASE%\update-khanza.ico" >nul
echo.

REM --- Pastikan koneksi ke server aktif (kredensial dari Credential Manager) ---
net use "%SERVER%" /persistent:yes >nul 2>&1

echo ============================================================
echo  1. Membuat shortcut "SIMRS Khanza" di Desktop
echo ============================================================
powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $l=$ws.CreateShortcut((Join-Path $env:PUBLIC 'Desktop\SIMRS Khanza.lnk')); $l.TargetPath='%TARGET_APP%'; $l.WorkingDirectory='%BASE%'; $l.IconLocation='%ICON_APP%'; $l.Save()"
if exist "%PUBLIC%\Desktop\SIMRS Khanza.lnk" (
    echo    OK: shortcut "SIMRS Khanza" dibuat.
) else (
    echo    GAGAL membuat shortcut "SIMRS Khanza".
)

echo.
echo ============================================================
echo  2. Membuat shortcut "Update Khanza" di Desktop
echo ============================================================
if not exist "%UPDATEBAT%" (
    echo    ERROR: file "%UPDATEBAT%" tidak ditemukan.
    echo    Shortcut "Update Khanza" TIDAK dibuat.
    echo    Pastikan file "2. update.bat" ada di folder yang sama
    echo    dengan finalisasi-khanza.bat, lalu jalankan ulang.
    goto :langkah3
)
powershell -NoProfile -Command "$ws=New-Object -ComObject WScript.Shell; $l=$ws.CreateShortcut((Join-Path $env:PUBLIC 'Desktop\Update Khanza.lnk')); $l.TargetPath='%UPDATEBAT%'; $l.WorkingDirectory='%UPDATEDIR%'; $l.IconLocation='%ICON_UPD%'; $l.Save()"
if exist "%PUBLIC%\Desktop\Update Khanza.lnk" (
    echo    OK: shortcut "Update Khanza" dibuat.
) else (
    echo    GAGAL membuat shortcut "Update Khanza".
)

:langkah3
echo.
echo ============================================================
echo  3. Pilih konfigurasi database.xml untuk PC ini
echo ============================================================
if not exist "%KUMPULAN%" (
    echo ERROR: folder "%KUMPULAN%" tidak ditemukan.
    echo Pastikan update sudah dijalankan lebih dulu.
    goto :selesai
)

set /a n=0
for /d %%D in ("%KUMPULAN%\*") do (
    set /a n+=1
    set "opt[!n!]=%%~nxD"
    echo   !n!. %%~nxD
)

if %n%==0 (
    echo Tidak ada folder di dalam "%KUMPULAN%".
    goto :selesai
)

echo.
set /p "pilih=Masukkan nomor folder yang dipakai PC ini: "

set "chosen=!opt[%pilih%]!"
if "!chosen!"=="" (
    echo Pilihan tidak valid.
    goto :selesai
)

set "SRCXML=%KUMPULAN%\!chosen!\database.xml"
if not exist "%SRCXML%" (
    echo ERROR: database.xml tidak ada di dalam folder "!chosen!".
    goto :selesai
)

if exist "%SETTING%\database.xml" del /f /q "%SETTING%\database.xml" >nul 2>&1
mklink "%SETTING%\database.xml" "%SRCXML%"

if exist "%SETTING%\database.xml" (
    echo.
    echo OK: setting\database.xml  -^>  kumpulan xml\!chosen!\database.xml
) else (
    echo GAGAL membuat symlink database.xml
)

:selesai
echo.
echo Selesai.
pause