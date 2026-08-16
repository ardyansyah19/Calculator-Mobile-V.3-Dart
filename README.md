# Kalkulator App (Flutter)

Aplikasi kalkulator mobile dengan tampilan bertema gelap, display bergaris oranye,
panel riwayat perhitungan, dan keypad ilmiah bertab — terinspirasi dari layout
pada gambar yang kamu kirim.

## Fitur
- Operasi dasar: `+ − × ÷`
- Pangkat `xʸ` / `xⁿ`, akar kuadrat `√`, nilai mutlak `|x|`
- Faktorial `n!`, persen `%`
- Fungsi trigonometri: `sin, cos, tan` (derajat)
- Logaritma: `log` (basis 10), `ln` (basis e)
- Konstanta `π` dan `e`, tanda kurung `( )`
- Riwayat perhitungan (scroll)
- Tab keypad: `1` dasar, `2` fungsi ilmiah, `3` konstanta, `a-z` huruf manual
- Tombol keyboard (ikon paling kanan) untuk mengetik langsung via keyboard sistem

## Cara Menjalankan di VS Code

1. **Install Flutter SDK** (jika belum ada): https://docs.flutter.dev/get-started/install
2. Install extension **Flutter** dan **Dart** di VS Code.
3. Extract folder `calculator_app` ini, lalu buka foldernya di VS Code
   (`File > Open Folder...`).
4. Buka terminal di VS Code, jalankan:
   ```
   flutter pub get
   ```
5. Sambungkan emulator Android/iOS atau device fisik (aktifkan USB debugging),
   lalu jalankan:
   ```
   flutter run
   ```
   Atau tekan `F5` di VS Code.

## Struktur Proyek
```
calculator_app/
├── pubspec.yaml          # dependencies & konfigurasi proyek
├── analysis_options.yaml # aturan lint standar Flutter
└── lib/
    ├── main.dart            # UI kalkulator (display, riwayat, keypad)
    └── calculator_logic.dart # parser & evaluator ekspresi matematika
```

## Mengembangkan Lebih Lanjut
- `calculator_logic.dart` berisi parser rekursif (recursive descent) yang mudah
  ditambah fungsi baru — cukup tambahkan `case` baru di method `_primary()`.
- Untuk menambah tombol baru di UI, tambahkan pemanggilan `_key(...)` di
  `_buildMainKeypad()` / `_buildFunctionKeypad()` pada `main.dart`.
- Warna tema (oranye, biru, abu gelap) didefinisikan sebagai konstanta statis
  di awal class `_CalculatorHomeState` — ubah di situ untuk reskin cepat.

## Catatan
Proyek ini hanya berisi `pubspec.yaml` + `lib/`. Folder platform
(`android/`, `ios/`, dll.) belum di-generate — Flutter akan membuatnya
otomatis saat kamu menjalankan `flutter create .` di dalam folder ini
sebelum `flutter pub get` (khususnya jika folder platform belum ada).
