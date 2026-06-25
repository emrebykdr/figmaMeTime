import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/text_field.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<Map<String, String>> _countries = [
    {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Turkey', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
  ];

  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = _countries[0]['code']!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: r.w(30)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: r.h(16)),
              _buildTopBar(context, r),
              SizedBox(height: r.h(74)),
              _buildTitle(r),
              SizedBox(height: r.h(10)),
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
              ),
              SizedBox(height: r.h(16)),
              PasswordTextField(controller: _passwordController),
              SizedBox(height: r.h(16)),
              SignUpPhoneField(
                controller: _phoneController,
                countryCode: _selectedCode,
                onCountryCodeTap: (_) => _showCountryPicker(r),
              ),
              SizedBox(height: r.h(40)),
              _buildRegisterButton(r),
              SizedBox(height: r.h(24)),
              _buildAlreadyHaveAccount(r),
              SizedBox(height: r.h(12)),
              _buildLoginButton(r),
              SizedBox(height: r.h(30)),
            ],
          ),
        ),
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

  Widget _buildTitle(Responsive r) {
    return Text(
      'Sign up',
      style: TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w700,
        fontSize: r.sp(32),
        height: 1.3,
        letterSpacing: -0.32,
        color: AppColors.almostBlack,
      ),
    );
  }

  Widget _buildRegisterButton(Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(293),
        height: r.h(54),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(10)),
            ),
          ),
          child: Text(
            'Register',
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

  Widget _buildAlreadyHaveAccount(Responsive r) {
    return Center(
      child: Text(
        'Already have an account',
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(18),
          height: 1.36,
          letterSpacing: -0.48,
          color: AppColors.tertiary,
        ),
      ),
    );
  }

  Widget _buildLoginButton(Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(271),
        height: r.h(61),
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.tertiary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(10)),
            ),
          ),
          child: Text(
            'Log In',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(Responsive r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.r(16))),
      ),
      builder: (_) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _countries.length,
          itemBuilder: (context, index) {
            final country = _countries[index];
            return ListTile(
              leading: Text(country['flag']!, style: TextStyle(fontSize: r.sp(24))),
              title: Text(
                '${country['name']} (${country['code']})',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(16),
                  color: AppColors.almostBlack,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedCode = country['code']!;
                  _phoneController.clear();
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
