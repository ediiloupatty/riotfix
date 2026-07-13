#Requires -Version 5.1
<#
================================================================================
 riotfix.ps1
 Memperbaiki error Riot Client / Valorant:
   "The application has failed to start because its side-by-side
    configuration is incorrect."
================================================================================

 SILAKAN BACA DULU SEBELUM DIJALANKAN. Skrip ini sengaja dibuat supaya bisa
 kamu baca sendiri - jangan pernah menjalankan skrip Administrator yang tidak
 kamu mengerti isinya, dari siapa pun, termasuk dari teman.

 APA MASALAHNYA?
   Error "side-by-side configuration is incorrect" artinya RiotClientServices.exe
   membutuhkan komponen runtime Windows (Visual C++ Redistributable buatan
   Microsoft), tapi Windows tidak menemukannya - atau menemukannya dalam keadaan
   RUSAK. Biasanya karena komponen itu terhapus atau gagal ter-install.

 APA YANG DILAKUKAN SKRIP INI?
   1. Membaca Event Log Windows untuk tahu komponen mana PERSISNYA yang bermasalah.
      (Hanya membaca. Tidak mengubah apa pun.)
   2. Menampilkan temuannya, lalu MINTA PERSETUJUAN kamu sebelum lanjut.
   3. Men-download Visual C++ Redistributable yang benar, LANGSUNG DARI SERVER
      RESMI MICROSOFT (microsoft.com / aka.ms). Bukan dari server pribadi siapa pun.
   4. Memeriksa TANDA TANGAN DIGITAL file itu. Kalau ternyata bukan asli buatan
      Microsoft, skrip BERHENTI dan menolak menjalankannya.
   5. Meng-install-nya. Kalau ternyata sudah terpasang tapi rusak, dia menjalankan
      mode REPAIR untuk memperbaikinya.
   6. Memverifikasi: kamu buka Valorant, lalu skrip cek apakah errornya hilang.

 APA YANG *TIDAK* DILAKUKAN SKRIP INI?
   - TIDAK menyentuh, menghapus, atau mengubah file game kamu.
   - TIDAK menyentuh Riot Vanguard (anti-cheat).
   - TIDAK mengirim data apa pun tentang komputermu ke mana pun.
   - TIDAK meng-uninstall apa pun.
   - TIDAK mengubah registry, kecuali lewat installer resmi Microsoft itu sendiri.

 PERLU INSTALL APA DULU? TIDAK ADA.
   Semua yang dipakai skrip ini (PowerShell, Event Log, downloader, pemeriksa
   tanda tangan) sudah bawaan Windows. Tidak perlu install Python, .NET, atau
   apa pun. Cukup file ini.

 CARA MENJALANKAN (paling gampang):
   Double-click "JALANKAN.bat" yang ada di folder yang sama.

 Kalau mau lihat diagnosanya saja, tanpa mengubah apa pun:
   Double-click "CEK-SAJA.bat"
================================================================================
#>

[CmdletBinding()]
param(
    # Hanya diagnosa: laporkan apa yang bermasalah, jangan install apa pun.
    [switch]$DiagnoseOnly,
    # Lewati pertanyaan konfirmasi.
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
# Tanpa ini, Invoke-WebRequest jadi SANGAT lambat (bug lama PowerShell: rendering
# progress bar-nya lebih berat daripada download-nya sendiri).
$ProgressPreference = 'SilentlyContinue'

# -- tampilan ------------------------------------------------------------------
function Say  { param($m) Write-Host "  $m" }
function Ok   { param($m) Write-Host "  $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "  $m" -ForegroundColor Yellow }
function Bad  { param($m) Write-Host "  $m" -ForegroundColor Red }
function Head { param($m) Write-Host "`n$m" -ForegroundColor Cyan }

# -- Visual C++ Redistributable resmi Microsoft --------------------------------
# Kunci  = nama assembly seperti yang tertulis di Event Log (Microsoft.VC<n>.CRT).
# Args   = argumen untuk install senyap.
# Repair = argumen untuk MEMPERBAIKI yang sudah terpasang tapi rusak.
#          (Ini penting: penyebab SxS paling sering justru runtime yang sudah ada
#           tapi korup - kalau cuma di-install ulang, installer bilang "sudah ada"
#           lalu tidak melakukan apa-apa, dan errornya tetap.)
# Semua URL di bawah sudah diverifikasi mengarah ke server resmi Microsoft.
$REDIST = @{
    'VC80'  = @{ Name = 'Visual C++ 2005 SP1'
                 x86  = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE'
                 x64  = 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE'
                 Args = @('/q'); Repair = @('/q') }
    'VC90'  = @{ Name = 'Visual C++ 2008 SP1'
                 x86  = 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe'
                 x64  = 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe'
                 Args = @('/q'); Repair = @('/q') }
    'VC100' = @{ Name = 'Visual C++ 2010 SP1'
                 x86  = 'https://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe'
                 x64  = 'https://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe'
                 Args = @('/q', '/norestart'); Repair = @('/q', '/norestart') }
    'VC110' = @{ Name = 'Visual C++ 2012 Update 4'
                 x86  = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'
                 x64  = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'
                 Args = @('/install', '/quiet', '/norestart'); Repair = @('/repair', '/quiet', '/norestart') }
    'VC120' = @{ Name = 'Visual C++ 2013'
                 x86  = 'https://aka.ms/highdpimfc2013x86'
                 x64  = 'https://aka.ms/highdpimfc2013x64'
                 Args = @('/install', '/quiet', '/norestart'); Repair = @('/repair', '/quiet', '/norestart') }
    'VC140' = @{ Name = 'Visual C++ 2015-2022'
                 x86  = 'https://aka.ms/vs/17/release/vc_redist.x86.exe'
                 x64  = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
                 Args = @('/install', '/quiet', '/norestart'); Repair = @('/repair', '/quiet', '/norestart') }
}
# VC141/142/143 dilayani paket 2015-2022 yang sama (binary-compatible).
foreach ($v in 'VC141', 'VC142', 'VC143') { $REDIST[$v] = $REDIST['VC140'] }

# Dipakai kalau Event Log ternyata kosong (log-nya sudah ter-rotate/terhapus).
# Riot Client dibangun dengan MSVC modern, jadi ini tebakan paling masuk akal.
$FALLBACK = @('VC140')

$Is64 = [Environment]::Is64BitOperatingSystem


# -- admin ---------------------------------------------------------------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}


# -- membaca Event Log ---------------------------------------------------------
# Windows mencatat setiap kegagalan side-by-side di Event Log, sumber 'SideBySide'.
# Pesannya menyebut assembly yang dicari tapi gagal dimuat, contoh:
#   Dependent Assembly Microsoft.VC90.CRT,processorArchitecture="x86",...
# Di situlah jawabannya - jadi kita BACA, bukan menebak.
function Get-SxsEvents {
    param([datetime]$Since = (Get-Date).AddDays(-30))
    try {
        Get-WinEvent -FilterHashtable @{
            LogName      = 'Application'
            ProviderName = 'SideBySide'
            StartTime    = $Since
        } -MaxEvents 200 -ErrorAction Stop
    } catch {
        @()   # tidak ada entri sama sekali - itu bukan error
    }
}

function Read-Findings {
    param($Events)
    $found   = @{}   # komponen yang DIKENALI skrip ini (Visual C++)
    $others  = @{}   # komponen lain - TIDAK bisa diperbaiki skrip ini
    $raw     = @{}   # pesan mentah dari Windows, apa adanya
    $exePath = $null

    foreach ($e in $Events) {
        $msg = $e.Message
        if (-not $msg) { continue }
        $raw[$msg] = $true

        if (-not $exePath -and $msg -match '([A-Za-z]:\\[^"]*?RiotClientServices\.exe)') {
            $exePath = $Matches[1]
        }

        # Ambil SEMUA assembly yang disebut, apa pun namanya - bukan cuma yang
        # kita kenal. Kalau kita cuma mencari Microsoft.VC*, komponen bermasalah
        # jenis lain akan lolos tanpa terdeteksi, dan skrip akan salah menebak
        # bahwa "tidak ada catatan" lalu memasang Visual C++ yang sebenarnya
        # baik-baik saja. Lebih baik jujur: "ada, tapi bukan urusan skrip ini".
        #
        # Nama assembly dan processorArchitecture TIDAK diterjemahkan Windows,
        # jadi pola ini tetap jalan di Windows berbahasa apa pun.
        $pattern = '([\w\.\-]+),\s*processorArchitecture="([^"]+)"'
        foreach ($m in [regex]::Matches($msg, $pattern)) {
            $name = $m.Groups[1].Value
            $arch = 'x86'
            if ($m.Groups[2].Value -match 'amd64|x64') { $arch = 'x64' }
            $riot = ($msg -match 'Riot|VALORANT')

            if ($name -match '^Microsoft\.(VC\d+)\.(?:CRT|MFC|ATL|OpenMP)$') {
                $ver = $Matches[1]
                $found["$ver/$arch"] = @{ Ver = $ver; Arch = $arch; Riot = $riot }
            } else {
                $others["$name/$arch"] = @{ Name = $name; Arch = $arch; Riot = $riot }
            }
        }
    }
    [pscustomobject]@{
        Missing = @($found.Values)    # bisa diperbaiki
        Others  = @($others.Values)   # TIDAK bisa diperbaiki skrip ini
        Raw     = @($raw.Keys)
        ExePath = $exePath
    }
}


# Menampilkan pesan asli dari Windows, apa adanya. Ini "keterangan mentah" -
# kalau skrip ini tidak mengerti masalahnya, minimal kamu punya bukti yang bisa
# dikirim ke orang yang mengerti, bukan sekadar "gagal".
function Show-Raw {
    param($Findings, [int]$Max = 3)
    $msgs = @($Findings.Raw)
    if ($msgs.Count -eq 0) { return }
    Head "Keterangan mentah dari Windows (salin bagian ini kalau perlu bantuan)"
    foreach ($m in ($msgs | Select-Object -First $Max)) {
        Say "-----------------------------------------------------------------"
        foreach ($line in ($m -split "`r?`n" | Where-Object { $_.Trim() })) { Say $line.Trim() }
    }
    Say "-----------------------------------------------------------------"
    if ($msgs.Count -gt $Max) { Say "(...dan $($msgs.Count - $Max) pesan serupa lainnya)" }
}


# -- download (dengan cadangan kalau cara pertama gagal) -----------------------
function Get-File {
    param([string]$Url, [string]$Out)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing
    } catch {
        # Sebagian jaringan/proxy memblokir Invoke-WebRequest. Coba cara lama.
        Warn "cara download utama gagal, mencoba cara cadangan..."
        (New-Object Net.WebClient).DownloadFile($Url, $Out)
    }
    if (-not (Test-Path $Out) -or (Get-Item $Out).Length -lt 100000) {
        throw "file hasil download tidak wajar (terlalu kecil) - kemungkinan diblokir jaringan."
    }
}


# -- verifikasi tanda tangan digital -------------------------------------------
# File yang baru di-download TIDAK langsung dijalankan. Diperiksa dulu: tanda
# tangannya harus valid DAN penandatangannya harus Microsoft Corporation.
# Kalau tidak, skrip berhenti dan file itu tidak pernah dieksekusi.
function Assert-MicrosoftSigned {
    param([string]$File)
    $sig = Get-AuthenticodeSignature -FilePath $File
    if ($sig.Status -ne 'Valid') {
        throw "tanda tangan digital TIDAK VALID (status: $($sig.Status)). File tidak dijalankan."
    }
    if ($sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        throw "file ini BUKAN buatan Microsoft ($($sig.SignerCertificate.Subject)). File tidak dijalankan."
    }
    Ok "tanda tangan digital OK - asli dari Microsoft."
}


# -- arti exit code installer --------------------------------------------------
function Get-ExitMeaning {
    param([int]$Code)
    switch ($Code) {
        0     { @{ Ok = $true;  Msg = 'terpasang.' } }
        1638  { @{ Ok = $false; Msg = 'sudah terpasang (versi lain).'; Repair = $true } }
        1641  { @{ Ok = $true;  Msg = 'terpasang (Windows akan restart).' } }
        3010  { @{ Ok = $true;  Msg = 'terpasang (perlu restart nanti).' } }
        1602  { @{ Ok = $false; Msg = 'dibatalkan.' } }
        1603  { @{ Ok = $false; Msg = 'gagal fatal - biasanya file sistem rusak; coba restart lalu ulangi.' } }
        5100  { @{ Ok = $false; Msg = 'versi Windows tidak didukung installer ini.' } }
        default { @{ Ok = $false; Msg = "gagal (exit code: $Code)." } }
    }
}


# -- alur utama ----------------------------------------------------------------
function Invoke-RiotFix {

    # Naikkan ke Administrator kalau belum. (Membaca Event Log dan meng-install
    # runtime Windows memang butuh hak admin - tidak ada cara lain.)
    #
    # -NoExit dipakai supaya jendela Administrator TIDAK PERNAH menutup sendiri,
    # bahkan kalau terjadi error fatal. Kalau jendela hilang begitu saja, kamu
    # tidak akan tahu apa yang salah dan tidak ada yang bisa dilaporkan.
    if (-not (Test-Admin)) {
        Warn "Skrip ini perlu hak Administrator."
        Say  "Akan muncul konfirmasi UAC dari Windows - klik 'Yes'."
        Say  "Setelah itu, LANJUTKAN DI JENDELA BARU yang terbuka."
        $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit',
               '-File', "`"$PSCommandPath`"")
        if ($DiagnoseOnly) { $a += '-DiagnoseOnly' }
        if ($Yes)          { $a += '-Yes' }
        try {
            Start-Process powershell.exe -Verb RunAs -ArgumentList $a | Out-Null
            Ok "Jendela Administrator dibuka. Lanjutkan di sana."
        } catch {
            Bad "Konfirmasi UAC ditolak, jadi skrip tidak bisa lanjut."
            Say "Jalankan lagi, dan klik 'Yes' saat Windows bertanya."
        }
        return
    }

    Head "riotfix - perbaikan error 'side-by-side configuration is incorrect'"
    Say  "Berjalan sebagai Administrator. Semua langkah ditampilkan di layar."
    Say  "Windows: $(if ($Is64) { '64-bit' } else { '32-bit' })"

    # -- 1. diagnosa (hanya membaca) -------------------------------------------
    Head "[1/4] Membaca Event Log Windows (tidak mengubah apa pun)"
    $events = @(Get-SxsEvents)
    Say "Ditemukan $($events.Count) catatan error 'SideBySide' dalam 30 hari terakhir."

    $diag    = Read-Findings -Events $events
    $missing = @($diag.Missing)
    $others  = @($diag.Others)
    $guessed = $false

    if ($diag.ExePath) { Say "Riot Client terdeteksi di: $($diag.ExePath)" }

    foreach ($m in $missing) {
        $tag = ''
        if ($m.Riot) { $tag = ' (terkait Riot Client)' }
        Bad "BERMASALAH : Microsoft.$($m.Ver).CRT [$($m.Arch)]$tag  -> BISA diperbaiki skrip ini"
    }

    # Komponen bermasalah yang BUKAN Visual C++. Skrip ini tidak bisa memperbaikinya,
    # dan itu harus dikatakan terus terang - bukan disembunyikan lalu diam-diam
    # memasang Visual C++ yang sebenarnya tidak bermasalah.
    foreach ($o in $others) {
        $tag = ''
        if ($o.Riot) { $tag = ' (terkait Riot Client)' }
        Warn "BERMASALAH : $($o.Name) [$($o.Arch)]$tag  -> BUKAN Visual C++"
    }

    if ($missing.Count -eq 0 -and $others.Count -eq 0) {
        if ($events.Count -gt 0) {
            # Ada catatan error, tapi tidak satu pun yang bisa dibaca polanya.
            # JANGAN menebak - tunjukkan pesan aslinya dan berhenti.
            Warn "Ada $($events.Count) catatan error, tapi skrip ini tidak mengenali isinya."
            Say  "Skrip TIDAK akan menebak-nebak. Berikut pesan asli dari Windows:"
            Show-Raw -Findings $diag
            Head "Berhenti di sini - tidak ada yang diubah."
            Say  "Kirim file log ini ke temanmu; di situ ada keterangan lengkapnya."
            return
        }
        Warn "Tidak ada catatan error 'SideBySide' sama sekali dalam 30 hari terakhir."
        Say  "Kemungkinan catatannya sudah terhapus. Kita coba perbaikan paling umum."
        $guessed = $true
        $missing = foreach ($v in $FALLBACK) { @{ Ver = $v; Arch = 'x86'; Riot = $false } }
        foreach ($m in $missing) { Say "DUGAAN : Microsoft.$($m.Ver).CRT" }
    }

    # Untuk tiap versi yang bermasalah, pasang x86 DAN x64 sekaligus.
    # Alasannya: Riot Client memuat komponen 32-bit maupun 64-bit, tapi Event Log
    # sering hanya sempat mencatat salah satunya. Memasang keduanya menutup celah
    # itu, dan memasang yang sebenarnya tidak kurang pun tidak berbahaya.
    $plan = @{}
    foreach ($m in $missing) {
        $r = $REDIST[$m.Ver]
        if (-not $r) { Warn "Belum mengenal komponen $($m.Ver) - dilewati."; continue }
        $arches = @('x86')
        if ($Is64) { $arches += 'x64' }   # installer x64 tidak bisa jalan di Windows 32-bit
        foreach ($a in $arches) {
            $plan["$($r.Name)/$a"] = @{
                Name = $r.Name; Arch = $a; Url = $r[$a]; Args = $r.Args; Repair = $r.Repair
            }
        }
    }
    $plan = @($plan.Values)

    # -- 2. rencana ------------------------------------------------------------
    Head "[2/4] Rencana perbaikan"
    if ($plan.Count -eq 0) {
        Bad  "PENYEBABNYA BUKAN VISUAL C++ - skrip ini TIDAK BISA memperbaikinya."
        Say  "Yang bermasalah adalah komponen lain (lihat daftar di atas)."
        Show-Raw -Findings $diag
        Head "Berhenti di sini - TIDAK ADA yang diubah di komputermu."
        Say  "Kirim file log ini ke temanmu. Di situ ada keterangan lengkap dari"
        Say  "Windows, jadi dia bisa tahu langkah berikutnya."
        return
    }
    foreach ($p in $plan) {
        Say "- $($p.Name) [$($p.Arch)]"
        Say "    dari: $($p.Url)"
    }
    if ($others.Count -gt 0) {
        Write-Host ""
        Warn "PERINGATAN: selain Visual C++, ada komponen lain yang juga bermasalah"
        Warn "(lihat daftar di atas). Skrip ini hanya memperbaiki bagian Visual C++,"
        Warn "jadi ADA KEMUNGKINAN errornya belum hilang sepenuhnya setelah ini."
    }
    if ($guessed) {
        Warn "Catatan: ini DUGAAN, bukan deteksi pasti - Event Log tidak memberi bukti."
        Warn "Tetap aman dipasang, tapi kalau errornya tidak hilang, berarti tebakan"
        Warn "ini meleset dan penyebabnya bukan Visual C++."
    }

    if ($DiagnoseOnly) {
        # Mode cek-saja: selalu tampilkan bukti mentahnya, karena justru itu yang
        # perlu dibaca orang yang akan menolong.
        Show-Raw -Findings $diag
        Head "Mode CEK-SAJA: berhenti di sini. TIDAK ADA yang diubah di komputermu."
        Say  "Kirim file log (lihat di bawah) ke temanmu."
        return
    }

    if (-not $Yes) {
        Write-Host ""
        $ans = Read-Host "  Lanjutkan install? (ketik: ya)"
        if ($ans.Trim().ToLower() -notin @('ya', 'y', 'yes')) {
            Warn "Dibatalkan. Tidak ada yang diubah di komputermu."
            return
        }
    }

    # -- 3. download + verifikasi + install ------------------------------------
    Head "[3/4] Download & install"
    $tmp = Join-Path $env:TEMP "riotfix-$(Get-Date -Format yyyyMMdd-HHmmss)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $failed = @()

    foreach ($p in $plan) {
        Write-Host ""
        Say "-> $($p.Name) [$($p.Arch)]"
        $file = Join-Path $tmp "$($p.Name -replace '[^\w]', '_')-$($p.Arch).exe"
        try {
            Say "downloading..."
            Get-File -Url $p.Url -Out $file
            Assert-MicrosoftSigned -File $file

            Say "installing (senyap, mohon tunggu - jangan tutup jendela ini)..."
            $code = (Start-Process -FilePath $file -ArgumentList $p.Args -Wait -PassThru).ExitCode
            $res  = Get-ExitMeaning -Code $code

            # Sudah terpasang? Berarti kemungkinan besar RUSAK - itulah sebabnya
            # error SxS muncul. Jalankan mode repair.
            if ($res.Repair -and $p.Repair) {
                Say "sudah terpasang - menjalankan REPAIR untuk memperbaiki yang rusak..."
                $code = (Start-Process -FilePath $file -ArgumentList $p.Repair -Wait -PassThru).ExitCode
                $res  = Get-ExitMeaning -Code $code
                if (-not $res.Ok -and $code -eq 1638) {
                    # Repair pun bilang "sudah ada": anggap memang sudah sehat.
                    $res = @{ Ok = $true; Msg = 'sudah terpasang dan sehat.' }
                }
            }

            if ($res.Ok) { Ok $res.Msg }
            else {
                Bad "installer $($res.Msg)"
                $failed += "$($p.Name) [$($p.Arch)]"
            }
        } catch {
            Bad "gagal: $($_.Exception.Message)"
            $failed += "$($p.Name) [$($p.Arch)]"
        }
    }

    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

    # -- 4. verifikasi ---------------------------------------------------------
    # Kamu yang membuka Valorant, bukan skrip ini. Sebabnya: skrip ini jalan
    # sebagai Administrator - kalau IA yang membuka, game-nya ikut jalan sebagai
    # Administrator, dan itu bukan kondisi normal kamu main. Kamu buka sendiri =
    # tes yang jujur.
    Head "[4/4] Verifikasi"
    $before = Get-Date
    Say "Sekarang coba buka Valorant / Riot Client SEPERTI BIASA (dari desktop atau"
    Say "Start Menu). Tidak perlu sampai masuk game - cukup lihat apakah kotak error"
    Say "'side-by-side configuration' itu muncul lagi atau tidak."
    Write-Host ""
    Read-Host "  Sudah dicoba? Tekan Enter untuk memeriksa hasilnya" | Out-Null

    $new = @(Get-SxsEvents -Since $before)
    if ($new.Count -eq 0) {
        Ok "Tidak ada error SideBySide baru tercatat. PERBAIKAN BERHASIL."
    } else {
        Bad "Windows masih mencatat $($new.Count) error SideBySide baru:"
        foreach ($m in @((Read-Findings -Events $new).Missing)) {
            Bad "  masih bermasalah: Microsoft.$($m.Ver).CRT [$($m.Arch)]"
        }
        Warn "Screenshot layar ini dan kirim ke temanmu."
    }

    Head "Selesai."
    if ($failed.Count -gt 0) {
        Bad "Yang gagal dipasang: $($failed -join ', ')"
        Say "Coba restart komputer, lalu jalankan skrip ini sekali lagi."
    }
    Say "Kalau setelah RESTART errornya masih ada, kemungkinan penyebabnya bukan"
    Say "Visual C++. Langkah berikutnya: install ulang Riot Client."
}


# -- jalankan, dan PASTIKAN jendela tidak menutup diam-diam --------------------
# Semua yang tampil di layar juga ditulis ke file log, supaya kalau ada yang
# aneh kamu tinggal mengirim file itu - tidak perlu sibuk screenshot.
#
# Log-nya ditaruh di DESKTOP, bukan di sebelah skrip. Sebabnya: skrip ini sering
# dijalankan dari folder sementara (%TEMP%) yang tidak akan pernah kamu temukan.
# Desktop = tempat yang pasti kelihatan.
#
# PENTING: hanya proses Administrator yang menulis log. Skrip ini dijalankan DUA
# KALI - sekali sebagai user biasa (yang cuma memanggil UAC lalu selesai), dan
# sekali sebagai Administrator (yang benar-benar bekerja). Kalau keduanya menulis
# ke file yang sama, proses pertama mengunci file itu, transcript di proses
# Administrator GAGAL dan diam-diam pindah ke %TEMP% - sehingga log yang berisi
# diagnosa sebenarnya tidak akan pernah ditemukan.
$LogFile = $null
if (Test-Admin) {
    foreach ($dir in @([Environment]::GetFolderPath('Desktop'), $env:TEMP)) {
        if (-not $dir) { continue }
        try {
            $try = Join-Path $dir 'riotfix-log.txt'
            Start-Transcript -Path $try -Force | Out-Null
            $LogFile = $try
            break
        } catch { }
    }
}

try {
    Invoke-RiotFix
} catch {
    Write-Host ""
    Bad "TERJADI ERROR TAK TERDUGA - skrip berhenti."
    Bad $_.Exception.Message
    Say "Baris: $($_.InvocationInfo.ScriptLineNumber)"
    Write-Host ""
    Say "Tidak ada yang rusak di komputermu karena ini."
} finally {
    if ($LogFile) {
        try { Stop-Transcript | Out-Null } catch { }
        Write-Host ""
        Ok  "Catatan lengkap tersimpan di:"
        Ok  "    $LogFile"
        Say "KIRIM FILE ITU ke temanmu - di situ ada keterangan lengkapnya."
        # Bukakan foldernya dan sorot file-nya, supaya tidak perlu dicari-cari.
        try { Start-Process explorer.exe "/select,`"$LogFile`"" } catch { }
    }
    Write-Host ""
    Read-Host "  Tekan Enter untuk menutup jendela ini" | Out-Null
    # Menutup jendela secara paksa. Perlu karena jendela Administrator dibuka
    # dengan -NoExit (supaya tidak pernah hilang diam-diam saat error), dan
    # tanpa baris ini jendelanya akan tetap menganggur setelah kamu tekan Enter.
    [Environment]::Exit(0)
}
