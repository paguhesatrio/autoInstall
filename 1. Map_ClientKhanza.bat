@echo off
setlocal
REM ============================================
REM  SETUP drive Y: ke share ClientKhanza
REM  Server : 172.16.17.222
REM  Share  : ClientKhanza
REM  User   : client
REM
REM  Bagian utama (credential, Y:, auto-reconnect saat login)
REM  bisa dijalankan dari akun harian, dengan atau tanpa admin.
REM  Bagian admin (registry + task unlock/sleep) hanya jalan
REM  jika dijalankan "Run as administrator" dari akun harian.
REM ============================================

set SERVER=172.16.17.222
set SHARE=\\%SERVER%\ClientKhanza
set SBUSER=client
set APPDIR=%LOCALAPPDATA%\ClientKhanza
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

echo Masukkan password Samba untuk user "%SBUSER%"
set /p SBPASS=Password: 

REM --- 1. Simpan kredensial di Credential Manager akun yang sedang login ---
cmdkey /delete:%SERVER% >nul 2>&1
cmdkey /add:%SERVER% /user:%SBUSER% /pass:"%SBPASS%" >nul
set SBPASS=

REM --- 2. Map ulang Y: tanpa /user (password diambil dari Credential Manager) ---
net use Y: /delete /y >nul 2>&1
net use \\%SERVER% /delete /y >nul 2>&1
net use Y: %SHARE% /persistent:yes
if errorlevel 1 (
    echo.
    echo GAGAL menghubungkan drive Y:.
    echo Periksa: jaringan / IP server / username / password.
    goto akhir
)
echo Drive Y: berhasil terhubung ke ClientKhanza.

REM --- 3. Pasang auto-reconnect saat login (folder Startup) ---
if not exist "%APPDIR%" mkdir "%APPDIR%"
if not exist "%~dp0Reconnect_Y.bat" goto tanpa_reconnect_file
copy /y "%~dp0Reconnect_Y.bat" "%APPDIR%\Reconnect_Y.bat" >nul
echo CreateObject("WScript.Shell").Run """%APPDIR%\Reconnect_Y.bat""", 0, False> "%STARTUP%\Reconnect_Y.vbs"
echo Auto-reconnect saat login terpasang.
goto bagian_admin

:tanpa_reconnect_file
echo PERINGATAN: Reconnect_Y.bat tidak ditemukan di folder ini.
goto akhir

:bagian_admin
REM --- 4. Bagian admin (opsional) ---
net session >nul 2>&1
if errorlevel 1 goto tanpa_admin
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLinkedConnections /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Winlogon" /v SyncForegroundPolicy /t REG_DWORD /d 1 /f >nul
schtasks /create /tn "ClientKhanza-Y-Unlock" /tr "\"%APPDIR%\Reconnect_Y.bat\"" /sc onevent /ec Security /mo "*[System[(EventID=4801)]]" /f >nul
schtasks /create /tn "ClientKhanza-Y-Resume" /tr "\"%APPDIR%\Reconnect_Y.bat\"" /sc onevent /ec System /mo "*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]" /f >nul
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable >nul 2>&1
echo Admin terpasang: registry dan auto-reconnect saat unlock/sleep.
goto akhir

:tanpa_admin
echo Info: tidak jalan sebagai administrator.
echo Credential dan auto-reconnect saat login sudah terpasang.
echo Untuk auto-reconnect saat unlock/sleep, jalankan ulang sebagai administrator dari akun ini.
goto akhir

:akhir
echo.
echo Selesai. Restart atau login ulang untuk menguji.
pause
