abstract final class InputValidators {
  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input)) {
      return 'Masukkan alamat email yang valid.';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < 8) return 'Gunakan minimal 8 karakter.';
    return null;
  }

  static String? requiredText(String? value, String label) =>
      (value?.trim().isEmpty ?? true) ? '$label wajib diisi.' : null;

  static double? parseDecimal(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
}
