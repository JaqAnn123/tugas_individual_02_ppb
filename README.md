# Nottia

Aplikasi jurnal, catatan, dan to-do list bertema **night & moon**, dibangun dengan Flutter.
Frame desain mengacu ke ukuran Figma **393 × 852**.

Status saat ini: **splash screen** + halaman login sementara (placeholder) agar alur splash
bisa langsung dicoba.

## Jalankan

```bash
flutter pub get
flutter run
```

Splash tampil selama ±3,8 detik, lalu cross-fade ke halaman login sementara.
Ketuk di mana saja untuk mempercepat. Di halaman login ada tombol
**Putar ulang splash**.

## Preview splash tanpa auto-advance

```bash
flutter run -d chrome -t tool/splash_preview.dart
```

Hasil tangkapan layar 393 × 852 ada di:

```
docs/preview/splash_393x852.png
```

## Detail splash

- Background: linear gradient `#040414` (atas) → `#11155B` (bawah).
- Wordmark: `nottia`, font **Caudex Regular**, 44 px di frame 393 (diskalakan proporsional
  di layar lain), warna cream `#F8F3E3`, dengan glow lembut.
- Logo: di tengah, tepat di atas wordmark.
- 4 bintang kecil: tersebar di kiri-atas, kanan-atas, kiri-tengah, kanan-tengah;
  berkedip dengan fase berbeda.
- Bulan setengah: menempel di tepi bawah, terpotong keluar layar.
- Animasi masuk: logo scale + fade, wordmark naik + fade, bulan naik, bintang muncul
  dan berkelip. Setelah itu logo mengambang pelan.

## Peta asset (untuk diganti dengan export final)

Semua asset gambar ada di `assets/images/`. Cukup ganti file dengan **nama yang sama**,
lalu jalankan ulang aplikasi.

| File | Ukuran placeholder | Dipakai di | Catatan |
| --- | --- | --- | --- |
| `assets/images/logo_nottia.png` | 512 × 512, PNG transparan | Splash, tepat di atas wordmark (ditampilkan ±173 px) | Ganti dengan logo final. Boleh 1024 × 1024; rasio 1:1. |
| `assets/images/moon_half.png` | 1200 × 1200, PNG transparan | Splash, tengah-bawah (ditampilkan ±480 px, `bottom: -192`) | Bulan setengah; bagian bawah terpotong frame. |
| `assets/images/stars/star_01.png` | 128 × 128, PNG transparan | Bintang kiri-atas, tampil 13 px | Posisi ± (51, 149) di frame 393 × 852. |
| `assets/images/stars/star_02.png` | 128 × 128, PNG transparan | Bintang kanan-atas, tampil 16 px | Posisi ± (344, 98). |
| `assets/images/stars/star_03.png` | 128 × 128, PNG transparan | Bintang kiri-tengah, tampil 9 px | Posisi ± (84, 294). |
| `assets/images/stars/star_04.png` | 128 × 128, PNG transparan | Bintang kanan-tengah, tampil 10 px | Posisi ± (330, 230). |

Font:

| File | Famili | Catatan |
| --- | --- | --- |
| `assets/fonts/Caudex-Regular.ttf` | `Caudex` | Wordmark 44 px. Lisensi OFL ada di `assets/fonts/OFL.txt`. |

> Semua file di atas masih **placeholder** dan boleh ditimpa. Nama file serta folder
> jangan diubah supaya kode splash langsung memakai asset baru.

### Regenerate placeholder / screenshot

Placeholder dibuat lewat script (butuh Windows + .NET `System.Drawing`):

```powershell
powershell -File tool/generate_placeholders.ps1
```

Untuk menangkap ulang preview 393 × 852, jalankan server dari hasil build preview:

```powershell
flutter build web --release -t tool/splash_preview.dart -o build/preview
Copy-Item tool/preview_splash.html build/preview/preview.html
python -m http.server 8123 --bind 127.0.0.1   # dari folder build/preview
powershell -File tool/capture_splash.ps1
```

## Struktur singkat

```
lib/
  app.dart                         # MaterialApp + gate splash → login
  main.dart                        # system UI & entrypoint
  core/theme/app_colors.dart       # token warna night & moon
  core/theme/app_theme.dart        # tema gelap + tipografi Caudex
  features/splash/splash_screen.dart
  features/auth/login_screen.dart  # sementara, akan diganti login asli
assets/
  fonts/                           # Caudex + lisensi
  images/                          # logo, bulan, bintang
tool/
  generate_placeholders.ps1        # generator asset placeholder
  splash_preview.dart              # entrypoint preview tanpa auto-advance
  preview_splash.html              # frame ponsel 393 × 852
  capture_splash.ps1               # screenshot preview
docs/preview/                      # hasil screenshot
test/widget_test.dart              # smoke test splash 393 × 852
```
