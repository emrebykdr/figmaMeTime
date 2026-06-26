import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

// ─── Genel App TextField (Full Name, Email, Password) ───

class AppTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(16),
            height: 1.0,
            color: AppColors.almostBlack,
          ),
        ),
        SizedBox(height: r.h(7)),
        SizedBox(
          height: r.h(54),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(16),
                color: AppColors.tertiary.withValues(alpha: 0.5),
              ),
              suffixIcon: suffixIcon,
              contentPadding: EdgeInsets.symmetric(
                horizontal: r.w(8),
                vertical: r.h(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r.r(10)),
                borderSide: const BorderSide(color: Color(0xFFCDCDCD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r.r(10)),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Password TextField (göz ikonu ile) ───

class PasswordTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PasswordTextField({
    super.key,
    this.label = 'Password',
    this.hint = 'Enter your password',
    required this.controller,
    this.onChanged,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      obscureText: _obscured,
      onChanged: widget.onChanged,
      suffixIcon: IconButton(
        icon: SvgPicture.asset(
          _obscured ? 'assets/icons/visibility_off.svg' : 'assets/icons/visibility_on.svg',
          width: 22,
          height: 22,
        ),
        onPressed: () {
          setState(() {
            _obscured = !_obscured;
          });
        },
      ),
    );
  }
}

// ─── Phone Number TextField (state durumlu, ülke kodlu) ───

enum PhoneFieldState { inactive, active, error }

class SignUpPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String>? onCountryCodeTap;
  final ValueChanged<String>? onChanged;

  const SignUpPhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    this.onCountryCodeTap,
    this.onChanged,
  });

  @override
  State<SignUpPhoneField> createState() => _SignUpPhoneFieldState();
}

class _SignUpPhoneFieldState extends State<SignUpPhoneField> {
  final FocusNode _focusNode = FocusNode();
  PhoneFieldState _state = PhoneFieldState.inactive;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _state = _focusNode.hasFocus ? PhoneFieldState.active : PhoneFieldState.inactive;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (_state) {
      case PhoneFieldState.active:
        return const Color(0xFF2CBCA1);
      case PhoneFieldState.error:
        return Colors.red;
      case PhoneFieldState.inactive:
        return const Color(0xFFCDCDCD);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final format = PhoneFormat.fromCountryCode(widget.countryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(16),
            height: 1.0,
            color: AppColors.almostBlack,
          ),
        ),
        SizedBox(height: r.h(7)),
        SizedBox(
          height: r.h(54),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => widget.onCountryCodeTap?.call(widget.countryCode),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(14)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r.r(10)),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.countryCode,
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w500,
                          fontSize: r.sp(16),
                          color: AppColors.almostBlack,
                        ),
                      ),
                      SizedBox(width: r.w(4)),
                      SvgPicture.asset('assets/icons/arrow_down.svg', width: r.w(16), height: r.w(16)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: r.w(8)),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.phone,
                  onChanged: widget.onChanged,
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: r.w(8),
                      vertical: r.h(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.r(10)),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(r.r(10)),
                      borderSide: BorderSide(color: _borderColor, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Phone Format & Formatter (login_phone sayfası için de kullanılıyor) ───

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
        return const PhoneFormat(code: '+90', hint: '5XX XXX XX XX', mask: 'XXX XXX XX XX', maxLength: 10);
      case '+1':
        return const PhoneFormat(code: '+1', hint: '(XXX) XXX-XXXX', mask: '(XXX) XXX-XXXX', maxLength: 10);
      case '+44':
        return const PhoneFormat(code: '+44', hint: 'XXXX XXX XXXX', mask: 'XXXX XXX XXXX', maxLength: 11);
      case '+49':
        return const PhoneFormat(code: '+49', hint: 'XXX XXXXXXXX', mask: 'XXX XXXXXXXX', maxLength: 11);
      case '+33':
        return const PhoneFormat(code: '+33', hint: 'X XX XX XX XX', mask: 'X XX XX XX XX', maxLength: 9);
      case '+55':
      default:
        return const PhoneFormat(code: '+55', hint: 'XX X XXXX XXXX', mask: 'XX X XXXX XXXX', maxLength: 11);
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
