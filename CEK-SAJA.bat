@echo off
title riotfix - CEK SAJA (tidak mengubah apa pun)
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem  Double-click file ini untuk MELIHAT apa yang rusak, TANPA memperbaiki
rem  apa pun. Tidak ada yang di-download, tidak ada yang di-install, tidak ada
rem  yang diubah di komputermu. Hanya membaca Event Log Windows lalu melapor.
rem
rem  Jalankan ini DULU, lalu kirim hasilnya ke temanmu.
rem  Kalau sudah yakin, baru jalankan JALANKAN.bat untuk memperbaiki.
rem ---------------------------------------------------------------------------

if not exist "%~dp0riotfix.ps1" (
    echo.
    echo   ERROR: file riotfix.ps1 tidak ada di folder ini.
    echo   Pastikan CEK-SAJA.bat dan riotfix.ps1 ada di FOLDER YANG SAMA.
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
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0riotfix.ps1" -DiagnoseOnly

echo.
echo   ---------------------------------------------------------------
echo   Kalau tadi muncul konfirmasi Windows dan kamu klik "Yes",
echo   lanjutkan di JENDELA BARU yang terbuka. Jendela ini boleh ditutup.
echo   ---------------------------------------------------------------
echo.
pause
