import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class PhoneFormat {
  final String code;
  final String hint;
  final String mask;
  final int maxLength;

  const PhoneFormat({
    required this.code,
    required this.hint,
    required this.mask,
    required this.maxLength,
  });

  static PhoneFormat fromCountryCode(String code) {
    switch (code) {
      case '+90':
        return const PhoneFormat(
          code: '+90',
          hint: '5XX XXX XX XX',
          mask: 'XXX XXX XX XX',
          maxLength: 10,
        );
      case '+1':
        return const PhoneFormat(
          code: '+1',
          hint: '(XXX) XXX-XXXX',
          mask: '(XXX) XXX-XXXX',
          maxLength: 10,
        );
      case '+44':
        return const PhoneFormat(
          code: '+44',
          hint: 'XXXX XXX XXXX',
          mask: 'XXXX XXX XXXX',
          maxLength: 11,
        );
      case '+49':
        return const PhoneFormat(
          code: '+49',
          hint: 'XXX XXXXXXXX',
          mask: 'XXX XXXXXXXX',
          maxLength: 11,
        );
      case '+33':
        return const PhoneFormat(
          code: '+33',
          hint: 'X XX XX XX XX',
          mask: 'X XX XX XX XX',
          maxLength: 9,
        );
      case '+55':
      default:
        return const PhoneFormat(
          code: '+55',
          hint: 'XX X XXXX XXXX',
          mask: 'XX X XXXX XXXX',
          maxLength: 11,
        );
    }
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  final String mask;

  _PhoneInputFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int digitIndex = 0;

    for (int i = 0; i < mask.length && digitIndex < digits.length; i++) {
      if (mask[i] == 'X') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(mask[i]);
        if (mask[i] != 'X' && digitIndex < digits.length) {
          // keep going
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String>? onChanged;

  const PhoneTextField({
    super.key,
    required this.controller,
    required this.countryCode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final format = PhoneFormat.fromCountryCode(countryCode);

    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(format.maxLength),
        _PhoneInputFormatter(format.mask),
      ],
      style: TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w500,
        fontSize: r.sp(16),
        color: AppColors.almostBlack,
      ),
      decoration: InputDecoration(
        hintText: format.hint,
        hintStyle: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w500,
          fontSize: r.sp(16),
          color: AppColors.tertiary.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}
