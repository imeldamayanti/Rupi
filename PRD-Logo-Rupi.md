# PRD: Logo Rupi — Eye + Money Mark

## 1. Ringkasan
Logo untuk **Rupi**, aplikasi iOS yang mendeteksi nominal uang rupiah lewat kamera dan mengumumkannya lewat suara + getaran, ditujukan untuk pengguna tunanetra/low-vision. Logo jadi app icon utama dan elemen brand di seluruh produk (splash screen, App Store listing, marketing).

## 2. Latar Belakang & Insight
- Target user gak bisa melihat, tapi app-nya "melihat" untuk mereka lewat kamera + AI.
- Konsep visual: **mata** (representasi kemampuan "melihat" milik app/AI) + **uang** (objek yang dideteksi). Kombinasi ini komunikasikan proposisi produk dalam 1 gambar: "app yang melihat uang untukmu."

## 3. Tujuan Desain
- Recognizable di ukuran kecil (App Store icon 1024×1024 discale sampai ~40×40 di homescreen).
- Kerja di 1 warna solid (flat), gak boleh bergantung ke gradient/shadow buat kebaca.
- Netral secara skala—gak butuh teks/huruf buat dimengerti (icon-only, universal).


## 5. Palet Warna
- Background: hijau emerald flat, `#047857` (asosiasi uang + trust; bisa dieksplor varian lain kalau riset brand lebih lanjut nunjukin warna lain lebih pas — misal biru untuk kesan "assistive tech/accessibility").
- Elemen mata & uang: putih solid `#FFFFFF`.
- Cutout (iris, coin mark, corner dots): sama dengan warna background, biar kesan "lubang".
- **Tanpa gradient, shadow, atau outline tambahan** — flat 2 warna aja.

## 6. Spesifikasi Teknis
- Master artwork: vektor, canvas persegi 1:1 (contoh 1024×1024).
- Safe area: konten utama (mata+uang) gak nyentuh 10% tepi terluar canvas — iOS otomatis masking rounded-corner, jangan gambar sudut membulat manual di master file.
- Export size minimal: 1024×1024 (App Store), plus icon set standar iOS (dari Xcode Asset Catalog, auto-generate dari 1024 kalau single-size icon).
- Harus tetap kebaca jelas di ukuran 40×40 (uji cetak kecil / preview homescreen sebelum final).

## 7. Do & Don't
**Do:**
- Pertahanin 2 elemen (mata + uang) selalu proporsional & center.
- Pastiin kontras tinggi antara elemen putih dan background biar kebaca di kondisi cahaya HP redup/terik.

**Don't:**
- Jangan tambahin teks/huruf "Rupi" ke dalam icon (nama app udah muncul di bawah icon otomatis di homescreen).
- Jangan pakai gradient/efek 3D — brand ini flat & accessible-first.
- Jangan bikin mata terlalu detail (bulu mata, dll) — bakal ilang kebacanya di ukuran kecil.

## 8. Deliverables
- File master vektor (Figma/Sketch/Illustrator — bebas, sesuai tool lu).
- Export PNG 1024×1024 buat App Store.
- (Opsional) versi monokrom buat keperluan lain (dark mode alternate icon, dsb).
