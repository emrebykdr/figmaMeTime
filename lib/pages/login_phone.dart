import 'package:flutter/material.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';

class LoginPhone extends StatefulWidget {
  const LoginPhone({super.key});

  @override
  State<LoginPhone> createState() => _LoginPhoneState();
}

class _LoginPhoneState extends State<LoginPhone> {
  final _phoneController = TextEditingController();

  final List<Map<String, String>> _countries = [
    {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Turkey', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
  ];

  late Map<String, String> _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries[0];
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
              SizedBox(height: r.h(55)),
              _buildTitle(r),
              SizedBox(height: r.h(10)),
              _buildSubtitle(r),
              SizedBox(height: r.h(35)),
              _buildDivider(),
              _buildCountrySelector(r),
              _buildDivider(),
              _buildPhoneInput(r),
              _buildDivider(),
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
              child: Icon(
                Icons.arrow_back,
                size: r.w(24),
                color: AppColors.almostBlack,
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
      'Please confirm your country code and\nenter your phone number.',
      style: TextStyle(fontFamily: 'Raleway',
        fontWeight: FontWeight.w500,
        fontSize: r.sp(16),
        height: 1.25,
        color: AppColors.tertiary,
      ),
    );
  }

  Widget _buildCountrySelector(Responsive r) {
    return GestureDetector(
      onTap: () => _showCountryPicker(r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: r.h(16)),
        child: Row(
          children: [
            Text(
              _selectedCountry['flag']!,
              style: TextStyle(fontSize: r.sp(24)),
            ),
            SizedBox(width: r.w(12)),
            Text(
              _selectedCountry['name']!,
              style: TextStyle(fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(16),
                color: AppColors.almostBlack,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down,
              size: r.w(20),
              color: AppColors.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.h(4)),
      child: Row(
        children: [
          Text(
            _selectedCountry['code']!,
            style: TextStyle(fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(width: r.w(12)),
          Container(
            width: 1,
            height: r.h(24),
            color: AppColors.tertiary.withValues(alpha: 0.3),
          ),
          SizedBox(width: r.w(12)),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(16),
                color: AppColors.almostBlack,
              ),
              decoration: InputDecoration(
                hintText: '00 0 0000 0000',
                hintStyle: TextStyle(fontFamily: 'Raleway',
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(16),
                  color: AppColors.tertiary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.tertiary.withValues(alpha: 0.2),
      height: 1,
    );
  }

  Widget _buildContinueButton(Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(271),
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
              leading: Text(
                country['flag']!,
                style: TextStyle(fontSize: r.sp(24)),
              ),
              title: Text(
                '${country['name']} (${country['code']})',
                style: TextStyle(fontFamily: 'Raleway',
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(16),
                  color: AppColors.almostBlack,
                ),
              ),
              onTap: () {
                setState(() {
                  _selectedCountry = country;
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
