@echo off
setlocal
REM ============================================================
REM  install.bat - jalankan SEKALI untuk instalasi otomatis
REM  Tahap 1: salin paket ke C:\KhanzaAutoInstall
REM           - kalau folder install.bat ini sudah berisi paket,
REM             salin dari sini (tanpa unduh)
REM           - kalau belum, unduh dari GitHub
REM           (butuh Administrator, hanya tahap ini)
REM  Tahap 2: Map Y:, update, finalisasi dari AKUN ANDA SENDIRI
REM           tanpa Run as administrator, supaya credential Samba
REM           tersimpan di akun yang dipakai login.
REM ============================================================

if "%~1"=="/extract" goto extract

net session >nul 2>&1
if %errorlevel% neq 0 goto minta_admin
goto extract

:minta_admin
echo Tahap 1: meminta hak Administrator hanya untuk menyalin paket...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '/extract' -Verb RunAs -Wait"
goto cek_hasil

:extract
if exist "%~dp0Reconnect_Y.bat" goto salin_lokal
cd /d %TEMP%
echo Mengunduh paket dari GitHub...
curl -L -f -o "%TEMP%\khanza.zip" https://github.com/paguhesatrio/autoInstall/archive/refs/heads/main.zip || (echo Download gagal & pause & exit /b 1)
tar -xf "%TEMP%\khanza.zip" -C C:\ || (echo Extract gagal & pause & exit /b 1)
if exist C:\KhanzaAutoInstall rmdir /s /q C:\KhanzaAutoInstall
ren C:\autoInstall-main KhanzaAutoInstall || (echo Ganti nama folder gagal & pause & exit /b 1)
del "%TEMP%\khanza.zip" >nul 2>&1
goto selesai_salin

:salin_lokal
echo Memakai paket dari folder ini: %~dp0
if /i "%~dp0"=="C:\KhanzaAutoInstall\" goto selesai_salin
robocopy "%~dp0." "C:\KhanzaAutoInstall" /E /XD .git >nul
if %errorlevel% geq 8 (echo Salin dari folder ini gagal & pause & exit /b 1)

:selesai_salin
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
