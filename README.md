# Lelang Fashion Mobile

Aplikasi mobile Flutter untuk pengguna lelang fashion. Project ini menggunakan pendekatan clean architecture feature-first, `go_router` untuk navigasi, `http` untuk komunikasi API, `shared_preferences` untuk sesi lokal, dan `image_picker` untuk upload eKYC serta bukti pembayaran.

## Fitur Utama

- Registrasi dan login pengguna.
- Verifikasi nomor WhatsApp dengan OTP.
- Katalog produk lelang.
- Detail produk dan fitur bid.
- Pembatasan bidding untuk akun baru sesuai aturan backend.
- Riwayat bid pengguna.
- Daftar kemenangan lelang.
- Pelunasan dan upload bukti bayar.
- Second-chance offer.
- Chat dengan admin berdasarkan produk lelang memakai polling HTTP ringan.
- Profil, skor kredit, status WhatsApp, dan status eKYC.
- Upload foto KTP dan selfie untuk verifikasi identitas.

## Struktur Project

Struktur utama berada di `lib/src`:

```text
app/                 Konfigurasi app, theme, dan router.
core/                Config, session, utility, dan reusable widgets.
data/api/            HTTP API client.
data/models/         Model data bersama.
features/            Modul feature-first.
```

Setiap feature dipisah menjadi:

- `data/` implementasi repository API.
- `domain/` kontrak repository.
- `presentation/` screen dan widget feature.

## Kebutuhan Lokal

- Flutter SDK sesuai `pubspec.yaml`
- Dart SDK sesuai Flutter yang digunakan
- Android SDK untuk build APK
- Backend Laravel web yang sudah berjalan

Install dependency:

```bash
flutter pub get
```

Jalankan aplikasi:

```bash
flutter run
```

## Konfigurasi API Base URL

Aplikasi development membaca konfigurasi dari file `.env` di root project mobile.

Salin template terlebih dahulu:

```bash
cp .env.example .env
```

```env
API_BASE_URL=http://10.0.2.2:8000/api
```

`API_BASE_URL` boleh berisi domain saja. Jika belum ada `/api`, aplikasi otomatis menambahkan `/api`.

Contoh untuk emulator Android yang mengakses Laravel lokal:

```env
API_BASE_URL=http://10.0.2.2:8000/api
```

Contoh untuk domain ngrok tanpa `/api`:

```env
API_BASE_URL=http://thankful-midge-noble.ngrok-free.app/api
```

Urutan prioritas konfigurasi adalah `.env` `API_BASE_URL`, lalu `--dart-define=API_BASE_URL`, lalu default lokal. Untuk development lokal cukup ubah file `.env`. File `.env` masuk `.gitignore` dan tidak ikut commit.

Aplikasi akan menormalisasi base URL:

- `http://thankful-midge-noble.ngrok-free.app` menjadi `http://thankful-midge-noble.ngrok-free.app/api`
- `http://domain.test/` menjadi `http://domain.test/api`
- `http://domain.test/api` tetap `http://domain.test/api`
- `http://domain.test/api/v1` tetap `http://domain.test/api/v1`

Jika scheme tidak ditulis, aplikasi akan menambahkan:

- `https://` untuk domain publik.
- `http://` untuk `localhost`, `127.x.x.x`, atau IP address.

Default lokal jika tidak ada define:

```text
http://10.0.2.2:8000/api
```

## Build APK

Build release APK:

```bash
flutter build apk --release
```

Build lokal memakai nilai dari file `.env`. Workflow GitHub Actions juga membuat file `.env` sementara dari GitHub Secrets atau Variables sebelum menjalankan build APK.

Output APK berada di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Navigasi Aplikasi

Route utama:

- `/splash`
- `/auth`
- `/lelang`
- `/lelang/:id`
- `/bid-saya`
- `/kemenangan`
- `/pelunasan`
- `/chat`
- `/chat/:id`
- `/profil`

Bottom navigation:

- Lelang
- Bid Saya
- Menang
- Bayar
- Chat
- Profil

## Integrasi Backend

Backend yang digunakan adalah repository Laravel `pelelangan-produk-fashion-web`. Endpoint mobile berada di prefix `/api`, misalnya:

- `POST /api/daftar`
- `POST /api/masuk`
- `GET /api/produk-lelang`
- `POST /api/produk-lelang/{id}/penawaran`
- `GET /api/verifikasi-identitas`
- `POST /api/verifikasi-identitas`
- `GET /api/pelunasan-saya`
- `POST /api/pelunasan/{id}/bukti-bayar`
- `GET /api/penawaran-kedua`
- `GET /api/chat/threads`
- `POST /api/produk-lelang/{id}/chat`
- `GET /api/chat/threads/{id}/messages`
- `POST /api/chat/threads/{id}/messages`

Pastikan backend sudah menjalankan queue worker dan scheduler agar OTP WhatsApp, settlement, dan second-chance offer berjalan sesuai flow. Chat user-admin melakukan refresh berkala lewat endpoint HTTP `/api/chat/*`.

## CI/CD

Workflow GitHub Actions berada di `.github/workflows/mobile.yml`.

Job utama:

- Install dependency Flutter.
- Jalankan `dart analyze`.
- Build release APK.
- Publish APK ke GitHub Release.

Repository variable yang digunakan:

- `API_BASE_URL`
- `API_BASE_URL_DEBUG`

Nama yang sama juga bisa disimpan sebagai GitHub Secrets. Jika Secret dan Variable sama-sama ada, workflow memakai Secret terlebih dahulu.

Nilai `API_BASE_URL` boleh berupa domain saja. Contoh:

```text
http://thankful-midge-noble.ngrok-free.app
```

Saat build, workflow menulis nilai tersebut ke file `.env` sementara dan meneruskannya lewat `--dart-define=API_BASE_URL`.

Trigger workflow:

- Push ke `main` atau `master`.
- Pull request.
- Tag `mobile-v*` atau `v*`.
- Manual dispatch.

## Catatan Development

- Token autentikasi disimpan lokal melalui `shared_preferences`.
- Upload file menggunakan multipart request.
- Jika menggunakan Android emulator dan backend lokal Laravel, gunakan `http://10.0.2.2:8000/api`.
- Jika menggunakan device fisik, gunakan IP lokal komputer atau tunnel seperti ngrok.
