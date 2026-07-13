# riotfix

Memperbaiki error Riot Client / Valorant:

> **The application has failed to start because its side-by-side configuration is incorrect.**

---

## Jalankan (satu perintah)

Buka **PowerShell** (tidak perlu Administrator — skripnya minta izin sendiri), lalu paste:

### 1. Cek dulu — tidak mengubah apa pun

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol='Tls12'; $p="$env:TEMP\riotfix.ps1"; irm https://raw.githubusercontent.com/ediiloupatty/riotfix/main/riotfix.ps1 -OutFile $p; Unblock-File $p; & $p -DiagnoseOnly
```

Ini **hanya membaca** Event Log Windows lalu melapor komponen apa yang bermasalah.
Tidak men-download installer, tidak meng-install, tidak mengubah apa pun.
Hasilnya disimpan di **`riotfix-log.txt` di Desktop**.

### 2. Perbaiki

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol='Tls12'; $p="$env:TEMP\riotfix.ps1"; irm https://raw.githubusercontent.com/ediiloupatty/riotfix/main/riotfix.ps1 -OutFile $p; Unblock-File $p; & $p
```

---

## Sebelum kamu paste perintah itu — baca ini

Kamu baru saja disuruh menempelkan perintah PowerShell dari internet. **Itu persis
cara kerja banyak penipuan.** Jadi wajar kalau kamu curiga, dan kamu memang
sebaiknya curiga.

Karena itu skrip ini **tidak disembunyikan**. Perintah di atas men-download file
`riotfix.ps1` ke komputermu **sebagai file biasa** lalu menjalankannya — bukan
dieksekusi langsung dari internet. Kamu bisa baca isinya kapan saja:

- Di sini: **[riotfix.ps1](riotfix.ps1)** — klik dan baca. Komentarnya bahasa Indonesia.
- Atau setelah di-download, buka `%TEMP%\riotfix.ps1` pakai Notepad.

Kalau kamu tidak paham isinya dan tidak ada yang bisa kamu percaya untuk
menjelaskannya, **jangan jalankan.** Itu saran yang jujur.

---

## Apa yang dilakukan skrip ini

1. **Membaca Event Log Windows** untuk tahu komponen mana persisnya yang bermasalah.
   Tidak menebak.
2. Kalau Event Log tidak memberi jawaban, menjalankan **`sxstrace.exe`** — alat resmi
   Windows yang disebut di kotak error itu sendiri (*"use the command-line sxstrace.exe
   tool for more detail"*). Alat itu merekam apa yang terjadi persis saat Valorant gagal
   dibuka, jadi hasilnya **bukti**, bukan tebakan.
3. Menampilkan temuannya, lalu **minta persetujuanmu** sebelum lanjut.
3. Men-download Visual C++ Redistributable yang sesuai, **langsung dari server resmi
   Microsoft** (`microsoft.com` / `aka.ms`) — bukan dari server pribadi siapa pun.
4. **Memeriksa tanda tangan digital** file itu. Kalau ternyata bukan asli buatan
   Microsoft, skrip berhenti dan menolak menjalankannya.
5. Meng-install-nya. Kalau ternyata sudah terpasang tapi **rusak**, dijalankan mode
   `/repair`.
6. Kamu buka Valorant, lalu skrip mengecek apakah errornya benar-benar hilang.

## Apa yang **tidak** dilakukan

- **Tidak** menyentuh, menghapus, atau mengubah file game.
- **Tidak** menyentuh Riot Vanguard (anti-cheat).
- **Tidak** mengirim data apa pun tentang komputermu ke mana pun.
  File `riotfix-log.txt` cuma ditulis di Desktop-mu — kamu sendiri yang memutuskan
  mau mengirimnya ke siapa, atau tidak sama sekali.
- **Tidak** meng-uninstall apa pun.
- **Tidak** mengubah pengaturan keamanan PowerShell secara permanen
  (`-Scope Process` = hanya berlaku untuk jendela itu, hilang saat ditutup).

## Kalau penyebabnya ternyata bukan Visual C++

Skrip ini **berhenti dan bilang terus terang**, lalu menampilkan pesan asli dari
Windows apa adanya — supaya kamu punya bukti untuk dibawa ke orang yang mengerti.
Ia tidak akan diam-diam memasang sesuatu yang tidak berhubungan lalu pura-pura
sudah beres.

## Perlu install apa dulu?

**Tidak ada.** PowerShell, Event Log, downloader, dan pemeriksa tanda tangan
semuanya sudah bawaan Windows. Cukup Windows 10/11.

---

## Cara lain: download manual

Kalau tidak mau menempel perintah apa pun, download tiga file ini ke satu folder
yang sama, lalu double-click `CEK-SAJA.bat`:

| File | Fungsi |
|---|---|
| `riotfix.ps1` | isi sebenarnya |
| `CEK-SAJA.bat` | melapor saja, tidak mengubah apa pun |
| `JALANKAN.bat` | memperbaiki |

## Lisensi

MIT
