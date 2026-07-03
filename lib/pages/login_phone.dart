import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/text_field.dart';
import 'package:figmaap/pages/login_phone_code.dart';
import 'package:figmaap/services/user_service.dart';
import 'package:figmaap/services/email_service.dart';

class LoginPhone extends StatefulWidget {
  final Map<String, dynamic>? professional;
  final bool noPreference;
  final String selectedService;
  final String selectedPrice;
  final bool skipToMain;

  const LoginPhone({
    super.key,
    this.professional,
    this.noPreference = false,
    this.selectedService = 'Basic Manicure',
    this.selectedPrice = '\$30',
    this.skipToMain = false,
  });

  @override
  State<LoginPhone> createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  final _emailController = TextEditingController();
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _isEmailValid = false;
  bool _isChecking = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    setState(() {
      _isEmailValid = _emailRegex.hasMatch(_emailController.text.trim());
      _errorText = null;
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final email = _emailController.text.trim();
    setState(() {
      _isChecking = true;
    });

    final userData = await UserService().getUserByEmail(email);
    if (!mounted) return;

    if (userData == null) {
      setState(() {
        _isChecking = false;
        _errorText = 'No account found with this email';
      });
      return;
    }

    if (userData['accountBlocked'] == true) {
      setState(() {
        _isChecking = false;
        _errorText = 'This account has been blocked. Please contact the salon.';
      });
      return;
    }

    final phone = userData['phone'] as String?;
    final userId = userData['id'] as String?;
    final fullName = userData['fullName'] as String?;

    // Admin panelinden manuel "Kod Oluştur"a basılmasını beklemeden, kod
    // burada hemen üretilip Firestore'a yazılıyor ve EmailJS ile (Gmail
    // OAuth popup gerektirmeden) doğrudan mobil uygulamadan gönderiliyor.
    // login_phone_code.dart bu kodu watchUserByPhone ile zaten canlı dinliyor.
    if (userId != null) {
      final code = await UserService().issueLoginCode(userId);
      await EmailService().sendLoginCode(
        toEmail: email,
        toName: fullName ?? '',
        code: code,
      );
    }
    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPhoneCode(
          phoneNumber: phone ?? '',
          professional: widget.professional,
          noPreference: widget.noPreference,
          selectedService: widget.selectedService,
          selectedPrice: widget.selectedPrice,
          skipToMain: widget.skipToMain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(30)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: r.h(16)),
              _buildTopBar(context, r),
              SizedBox(height: r.h(74)),
              _buildTitle(r),
              SizedBox(height: r.h(10)),
              _buildSubtitle(r),
              SizedBox(height: r.h(35)),
              AppTextField(
                label: 'Email',
                hint: 'Enter your registered email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              if (_errorText != null) ...[
                SizedBox(height: r.h(8)),
                Text(
                  _errorText!,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                    fontSize: r.sp(13),
                    color: AppColors.cancel,
                  ),
                ),
              ],
              const Spacer(),
              _buildContinueButton(r),
              SizedBox(height: r.h(40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(0)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SvgPicture.asset(
                'assets/icons/arrow_back.svg',
                width: r.w(24),
                height: r.w(24),
              ),
            ),
          ),
          const AppHeader(),
        ],
      ),
    );
  }

  Widget _buildTitle(Responsive r) {
    return Text(
      'Log in',
      style: TextStyle(fontFamily: 'Raleway',
        fontWeight: FontWeight.w700,
        fontSize: r.sp(32),
        height: 1.3,
        letterSpacing: -0.32,
        color: AppColors.almostBlack,
      ),
    );
  }

  Widget _buildSubtitle(Responsive r) {
    return Text(
      'Please enter the email address linked to\nyour account. '
      "We'll send your login code there.",
      style: TextStyle(fontFamily: 'Raleway',
        fontWeight: FontWeight.w500,
        fontSize: r.sp(16),
        height: 1.25,
        color: AppColors.tertiary,
      ),
    );
  }

  Widget _buildContinueButton(Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(293),
        height: r.h(54),
        child: ElevatedButton(
          onPressed: _isEmailValid && !_isChecking ? _onContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(10)),
            ),
          ),
          child: Text(
            'Continue',
            style: TextStyle(fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
