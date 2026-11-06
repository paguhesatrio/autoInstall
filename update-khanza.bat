@echo off
REM ============================================================
REM  update-khanza.bat
REM  Klik dua kali file ini untuk menjalankan sinkronisasi.
REM  Otomatis minta hak Administrator (perlu untuk mklink).
REM  File update-khanza.ps1 HARUS ada di folder yang sama.
REM ============================================================

REM --- Cek hak admin; kalau belum -> minta elevasi lalu keluar ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM --- Sudah admin: jalankan script PowerShell di folder yang sama ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-khanza.ps1"

echo.
echo Tekan tombol apa saja untuk menutup jendela ini...
pause >nul