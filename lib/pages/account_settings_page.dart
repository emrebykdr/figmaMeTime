import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/text_field.dart';
import 'package:figmaap/services/user_service.dart';
import 'package:figmaap/services/email_service.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusText;

  // Email doğrulama: bir kez doğrulanmış email başka bir hesapla tekrar
  // kayıt olurken kullanılamaz (bkz. UserService.isEmailVerifiedElsewhere,
  // sign_up.dart'taki kontrol).
  bool _isEmailVerified = false;
  String? _verifiedEmail;
  bool _isSendingVerification = false;
  bool _isConfirmingCode = false;
  bool _showCodeField = false;
  String? _verificationStatusText;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = UserService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final user = await UserService().getUserById(userId);
    if (!mounted) return;
    setState(() {
      _nameController.text = user?['fullName'] as String? ?? '';
      _emailController.text = user?['email'] as String? ?? '';
      _phoneController.text = user?['phone'] as String? ?? '';
      _isEmailVerified = user?['emailVerified'] == true;
      _verifiedEmail = user?['email'] as String?;
      _isLoading = false;
    });
  }

  bool get _emailMatchesVerified =>
      _isEmailVerified && _emailController.text.trim() == _verifiedEmail;

  Future<void> _onVerifyEmailTap() async {
    final email = _emailController.text.trim();
    final userId = UserService.currentUserId;
    if (email.isEmpty || userId == null) return;

    setState(() {
      _isSendingVerification = true;
      _verificationStatusText = null;
    });

    final code = await UserService().issueEmailVerificationCode(userId);
    final sent = await EmailService().sendLoginCode(
      toEmail: email,
      toName: _nameController.text.trim(),
      code: code,
    );
    if (!mounted) return;

    setState(() {
      _isSendingVerification = false;
      _showCodeField = true;
      _verificationStatusText = sent
          ? 'Verification code sent to $email.'
          : "Couldn't send the code. Please try again.";
    });
  }

  Future<void> _onConfirmVerificationTap() async {
    final userId = UserService.currentUserId;
    final code = _verificationCodeController.text.trim();
    if (userId == null || code.length != 5) return;

    setState(() {
      _isConfirmingCode = true;
    });

    final verified = await UserService().confirmEmailVerification(
      userId,
      code,
    );
    if (!mounted) return;

    setState(() {
      _isConfirmingCode = false;
      if (verified) {
        _isEmailVerified = true;
        _verifiedEmail = _emailController.text.trim();
        _showCodeField = false;
        _verificationCodeController.clear();
        _verificationStatusText = 'Email verified.';
      } else {
        _verificationStatusText = 'Invalid or expired code.';
      }
    });
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      setState(() {
        _statusText = 'All fields are required.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusText = null;
    });

    // Doğrulanmış email farklı bir değere değiştirildiyse, eski doğrulama
    // yeni email için geçerli sayılmamalı.
    final emailChanged = _isEmailVerified && email != _verifiedEmail;
    await UserService().updateProfile(
      fullName: name,
      email: email,
      phone: phone,
      resetEmailVerification: emailChanged,
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _statusText = 'Saved.';
      if (emailChanged) {
        _isEmailVerified = false;
        _verifiedEmail = null;
        _showCodeField = false;
        _verificationStatusText = null;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
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
              SizedBox(height: r.h(40)),
              Text(
                'Account Settings',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: r.sp(24),
                  height: 1.36,
                  letterSpacing: -0.48,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: r.h(24)),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                        ),
                        SizedBox(height: r.h(16)),
                        AppTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                        ),
                        _buildEmailVerificationSection(r),
                        SizedBox(height: r.h(16)),
                        AppTextField(
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        if (_statusText != null) ...[
                          SizedBox(height: r.h(12)),
                          Text(
                            _statusText!,
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w500,
                              fontSize: r.sp(13),
                              color: AppColors.tertiary,
                            ),
                          ),
                        ],
                        SizedBox(height: r.h(32)),
                        _buildSaveButton(r),
                        SizedBox(height: r.h(24)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailVerificationSection(Responsive r) {
    if (_emailMatchesVerified) {
      return Padding(
        padding: EdgeInsets.only(top: r.h(6)),
        child: Row(
          children: [
            Icon(Icons.verified, size: r.w(16), color: Colors.green),
            SizedBox(width: r.w(4)),
            Text(
              'Verified',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
                fontSize: r.sp(12),
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: r.h(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _isSendingVerification ? null : _onVerifyEmailTap,
            child: Text(
              _isSendingVerification ? 'Sending code...' : 'Verify this email',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
                fontSize: r.sp(12),
                color: AppColors.primary,
              ),
            ),
          ),
          if (_showCodeField) ...[
            SizedBox(height: r.h(8)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _verificationCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    style: TextStyle(fontFamily: 'Raleway', fontSize: r.sp(14)),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      hintText: 'Enter code',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: r.w(10),
                        vertical: r.h(10),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(r.r(8)),
                        borderSide: const BorderSide(color: Color(0xFFCDCDCD)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.w(8)),
                TextButton(
                  onPressed: _isConfirmingCode ? null : _onConfirmVerificationTap,
                  child: Text(
                    _isConfirmingCode ? '...' : 'Confirm',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(13),
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_verificationStatusText != null) ...[
            SizedBox(height: r.h(4)),
            Text(
              _verificationStatusText!,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(11),
                color: AppColors.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Responsive r) {
    return Stack(
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
    );
  }

  Widget _buildSaveButton(Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(293),
        height: r.h(54),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(10)),
            ),
          ),
          child: Text(
            _isSaving ? 'Saving...' : 'Save',
            style: TextStyle(
              fontFamily: 'Raleway',
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
