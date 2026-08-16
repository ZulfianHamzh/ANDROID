import 'package:flutter/services.dart';

/// Formats digits with Indonesian-style thousand separators (dots) as the
/// user types, e.g. `150000` becomes `150.000`. Non-digit characters are
/// stripped. Keeps a leading dot while the user is typing a partial number.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits (keep only digits, drop separators).
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final formatted = _groupDigits(digits);

    // Map the caret from the raw (digits) text into the formatted text.
    int caret = newValue.selection.baseOffset;
    if (caret < 0) caret = 0;
    final digitsBeforeCaret = newValue.text
        .substring(0, caret.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final formattedDigitsBeforeCaret = _groupDigits(
      digits.substring(0, digitsBeforeCaret.clamp(0, digits.length)),
    );
    caret = formattedDigitsBeforeCaret.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret.clamp(0, formatted.length)),
    );
  }

  String _groupDigits(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
