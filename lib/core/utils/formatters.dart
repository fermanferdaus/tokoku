import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Utility class untuk formatting angka, mata uang, dan tanggal.
class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');

  /// Format angka ke mata uang Rupiah (Rp 50.000).
  static String currency(num amount) => _currencyFormat.format(amount);

  /// Format DateTime ke tanggal (01 Jan 2026).
  static String date(DateTime dateTime) => _dateFormat.format(dateTime);

  /// Format DateTime ke tanggal + waktu (01 Jan 2026, 14:30).
  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  /// Format DateTime ke waktu saja (14:30).
  static String time(DateTime dateTime) => _timeFormat.format(dateTime);

  /// Format angka dengan separator ribuan (50.000).
  static String number(num value) {
    return NumberFormat('#,###', 'id_ID').format(value);
  }
}

/// Formatter untuk input text field yang otomatis menambahkan pemisah ribuan.
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya ambil angka
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final value = int.parse(cleanText);
    final formatter = NumberFormat('#,###', 'id_ID');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
