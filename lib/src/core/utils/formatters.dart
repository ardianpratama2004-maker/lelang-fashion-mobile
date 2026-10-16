import 'package:intl/intl.dart';

String money(int value) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(value);
}

String dateText(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd MMM yyyy HH:mm').format(value);
}

String statusLabel(String status) {
  return switch (status) {
    'active' => 'Aktif',
    'scheduled' => 'Terjadwal',
    'closed' => 'Selesai',
    'draft' => 'Draft',
    _ => status,
  };
}

String ekycLabel(String status) {
  return switch (status) {
    'belum_diajukan' => 'Belum Diajukan',
    'menunggu_review' => 'Menunggu Review',
    'disetujui' => 'Disetujui',
    'ditolak' => 'Ditolak',
    _ => status,
  };
}

String settlementStatusLabel(String status) {
  return switch (status) {
    'menunggu_pembayaran' => 'Menunggu Pembayaran',
    'lunas' => 'Lunas',
    'kedaluwarsa' => 'Kedaluwarsa',
    'dibatalkan' => 'Dibatalkan',
    'ditawarkan' => 'Ditawarkan',
    'diterima' => 'Diterima',
    'ditolak' => 'Ditolak',
    'dilewati' => 'Dilewati',
    _ => status,
  };
}

String paymentAttemptStatusLabel(String status) {
  return switch (status) {
    'menyiapkan' => 'Menyiapkan checkout',
    'menunggu' => 'Menunggu pembayaran Duitku',
    'berhasil' => 'Pembayaran diterima',
    'gagal' => 'Pembayaran gagal',
    'kedaluwarsa' => 'Tautan pembayaran kedaluwarsa',
    'berhasil_setelah_tutup' => 'Pembayaran perlu rekonsiliasi',
    _ => status,
  };
}
