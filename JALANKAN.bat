@echo off
title riotfix - perbaikan error side-by-side (Valorant / Riot Client)
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Double-click file ini untuk MEMPERBAIKI error:
rem    "The application has failed to start because its side-by-side
rem     configuration is incorrect."
rem
rem  File .bat ini hanya pembuka. Semua isi perbaikannya ada di riotfix.ps1 -
rem  buka pakai Notepad kalau mau baca dulu apa yang akan dilakukan.
rem  Sangat dianjurkan membacanya.
rem ---------------------------------------------------------------------------

if not exist "%~dp0riotfix.ps1" (
    echo.
    echo   ERROR: file riotfix.ps1 tidak ada di folder ini.
    echo   Pastikan JALANKAN.bat dan riotfix.ps1 ada di FOLDER YANG SAMA.
    echo.
    pause
    exit /b 1
)

echo.
echo   Menyiapkan...
echo.

rem Windows menandai file yang datang dari internet (WhatsApp, Discord, email)
rem sebagai "tidak dipercaya", dan itu membuat PowerShell menolak menjalankannya.
rem Baris ini melepas tanda tersebut.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0' -File | Unblock-File -ErrorAction SilentlyContinue"

rem Menjalankan skrip utama. Skrip itu sendiri yang akan meminta hak Administrator
rem (muncul konfirmasi UAC), lalu membuka jendela baru untuk mengerjakan tugasnya.
rem -ExecutionPolicy Bypass hanya berlaku untuk proses ini - pengaturan keamanan
rem PowerShell di komputermu TIDAK diubah secara permanen.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0riotfix.ps1"

echo.
echo   ---------------------------------------------------------------
echo   Kalau tadi muncul konfirmasi Windows dan kamu klik "Yes",
echo   lanjutkan di JENDELA BARU yang terbuka. Jendela ini boleh ditutup.
echo   ---------------------------------------------------------------
echo.
pause
