@echo off
REM ============================================================
REM  2. update.bat  (versi COPY - TANPA admin)
REM  Menyalin semua file asli dari server ke D:\ClientKhanza
REM  (kalau tidak ada drive D -> C:\ClientKhanza).
REM  Kredensial diambil dari Credential Manager (dibuat oleh
REM  "1. Map_ClientKhanza.bat"), jadi tidak ada password di file ini.
REM ============================================================

set "SERVER=\\172.16.17.222\ClientKhanza"

REM --- Cek drive D: kalau ada pakai D, kalau tidak pakai C ---
set "TUJUAN=C:\ClientKhanza"
if exist "D:\" set "TUJUAN=D:\ClientKhanza"

echo Folder tujuan: %TUJUAN%
echo.

echo Menghubungkan ke server...
net use "%SERVER%" /persistent:yes >nul 2>&1
if not exist "%SERVER%\" (
    echo GAGAL terhubung ke %SERVER%.
    echo Jalankan "1. Map_ClientKhanza.bat" dulu, lalu coba lagi.
    pause
    exit /b 1
)

echo Menyalin semua file aplikasi (file asli, bukan symlink)...
robocopy "%SERVER%" "%TUJUAN%" /E /COPY:DAT /DCOPY:DAT /R:1 /W:1
if %errorlevel% geq 8 (
    echo.
    echo GAGAL menyalin file. Kode robocopy: %errorlevel%
    pause
    exit /b 1
)

echo.
echo Selesai. Aplikasi ada di %TUJUAN%
pause
