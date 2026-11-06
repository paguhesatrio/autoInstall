@echo off
setlocal
REM ============================================================
REM  install.bat - jalankan SEKALI untuk instalasi otomatis
REM  Tahap 1: unduh & salin paket ke C:\KhanzaAutoInstall
REM           (butuh Administrator, hanya tahap ini)
REM  Tahap 2: Map Y:, update, finalisasi dijalankan dari AKUN
REM           ANDA SENDIRI tanpa Run as administrator, supaya
REM           credential Samba tersimpan di akun yang dipakai login.
REM ============================================================

if "%~1"=="/extract" goto extract

net session >nul 2>&1
if %errorlevel% neq 0 goto minta_admin
goto extract

:minta_admin
echo Tahap 1: meminta hak Administrator hanya untuk mengunduh dan menyalin paket...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '/extract' -Verb RunAs -Wait"
goto cek_hasil

:extract
cd /d %TEMP%
echo Mengunduh paket dari GitHub...
curl -L -o "%TEMP%\khanza.zip" https://github.com/paguhesatrio/autoInstall/archive/refs/heads/main.zip || (echo Download gagal & pause & exit /b 1)
tar -xf "%TEMP%\khanza.zip" -C C:\ || (echo Extract gagal & pause & exit /b 1)
if exist C:\KhanzaAutoInstall rmdir /s /q C:\KhanzaAutoInstall
ren C:\KhanzaAutoInstall-main KhanzaAutoInstall || (echo Ganti nama folder gagal & pause & exit /b 1)
del "%TEMP%\khanza.zip" >nul 2>&1
if "%~1"=="/extract" exit /b 0
goto tahap2

:cek_hasil
if exist "C:\KhanzaAutoInstall\1. Map_ClientKhanza.bat" goto tahap2
echo Tahap 1 gagal: paket tidak ditemukan di C:\KhanzaAutoInstall.
pause
exit /b 1

:tahap2
cd /d C:\KhanzaAutoInstall || (echo Folder C:\KhanzaAutoInstall tidak ditemukan & pause & exit /b 1)
echo.
echo Tahap 2: setup dari akun Anda sendiri (tanpa Run as administrator)...
call "1. Map_ClientKhanza.bat"
call "2. update.bat"
call "3. finalisasi-khanza.bat"
call "update-khanza.bat"

echo.
echo ============================================================
echo  Instalasi selesai.
echo ============================================================
pause
exit /b 0
