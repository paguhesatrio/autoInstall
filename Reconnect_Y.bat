@echo off
REM ============================================
REM  Auto-reconnect drive Y: saat login
REM  Dipanggil diam-diam oleh Reconnect_Y.vbs di folder Startup
REM ============================================

set SERVER=172.16.17.222
set SHARE=\\%SERVER%\ClientKhanza

REM Tunggu server bisa dijangkau, maksimal +-60 detik
set /a n=0
:tunggu
ping -n 1 -w 1000 %SERVER% | find "TTL=" >nul
if %errorlevel%==0 goto cek
set /a n+=1
if %n% geq 30 goto selesai
timeout /t 2 /nobreak >nul
goto tunggu

:cek
REM Kalau Y: sudah bisa dibuka, tidak perlu apa-apa
if exist "Y:\*" goto selesai

REM Y: silang / putus -> hapus lalu sambung ulang (password dari Credential Manager)
net use Y: /delete /y >nul 2>&1
net use Y: %SHARE% /persistent:yes >nul 2>&1

:selesai
exit