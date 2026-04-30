/// Utility class untuk validasi input form.
class Validators {
  Validators._();

  /// Validasi field yang wajib diisi.
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi format email.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi password (minimal 8 karakter, kombinasi huruf besar, kecil, angka, dan simbol).
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
      return 'Gunakan kombinasi huruf besar, kecil, angka, dan simbol';
    }
    
    return null;
  }

  /// Validasi konfirmasi password.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }

  /// Validasi harga (harus angka positif).
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga wajib diisi';
    }
    final parsed = double.tryParse(value.replaceAll('.', '').replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return 'Harga harus berupa angka positif';
    }
    return null;
  }

  /// Validasi stok (harus angka non-negatif).
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stok wajib diisi';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      return 'Stok harus berupa angka positif';
    }
    return null;
  }

  /// Validasi nomor telepon Indonesia.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^(\+62|62|0)8[1-9]\d{7,11}$').hasMatch(cleaned)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }
}
