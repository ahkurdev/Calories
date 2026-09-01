import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyAuthMessage(AuthException error) {
  final code = error.code?.toLowerCase();
  final message = error.message.toLowerCase();

  if (code == 'invalid_credentials' ||
      message.contains('invalid login') ||
      message.contains('invalid credentials')) {
    return 'Email atau kata sandi belum tepat.';
  }
  if (code == 'email_not_confirmed' ||
      message.contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Buka tautan konfirmasi di email, lalu coba masuk lagi.';
  }
  if (code == 'user_already_exists' ||
      code == 'email_exists' ||
      message.contains('already registered') ||
      message.contains('already exists')) {
    return 'Email ini sudah terdaftar.';
  }
  if (code == 'weak_password' || message.contains('password')) {
    return 'Kata sandi belum memenuhi persyaratan keamanan.';
  }
  if (code?.startsWith('over_') == true ||
      message.contains('rate') ||
      error.statusCode == '429') {
    return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  }
  if (code == 'otp_expired') {
    return 'Tautan konfirmasi sudah kedaluwarsa. Minta tautan baru lalu coba lagi.';
  }
  if (code == 'signup_disabled') {
    return 'Pendaftaran akun sedang dinonaktifkan.';
  }
  return 'Permintaan akun belum berhasil. Silakan coba lagi.';
}
