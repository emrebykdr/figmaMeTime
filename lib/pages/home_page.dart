import 'package:flutter/material.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/onboarding_choose_service.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/app_button.dart';
import 'package:figmaap/widgets/page_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: r.h(16)),
            const AppHeader(),
            SizedBox(height: r.h(24)),
            Expanded(
              child: Column(
                children: [
                  _buildIllustration(r),
                  SizedBox(height: r.h(32)),
                  _buildTitle(r),
                  SizedBox(height: r.h(16)),
                  _buildSubtitle(r),
                  const Spacer(),
                  _buildButtons(context, r),
                  SizedBox(height: r.h(40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(Responsive r) {
    return SizedBox(
      width: double.infinity,
      height: r.h(320),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/h_frame.png', fit: BoxFit.fitWidth),
          ),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/h_image.png',
              height: r.h(280),
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(19)),
      child: Text(
        'Welcome to \nThe Gallery Salon!',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Raleway',
          fontWeight: FontWeight.w700,
          fontSize: r.sp(32),
          height: 1.0,
          letterSpacing: -0.48,
          color: AppColors.almostBlack,
        ),
      ),
    );
  }

  Widget _buildSubtitle(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(45)),
      child: Text(
        'Follow the steps to schedule your\nnext appointment with us.',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Raleway',
          fontWeight: FontWeight.w500,
          fontSize: r.sp(18),
          height: 1.25,
          letterSpacing: 0,
          color: AppColors.tertiary,
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(32)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppTextButton(text: 'Skip', onPressed: () => LoginSheet.show(context, skipToMain: true)),
          AppPrimaryButton(
            text: 'Start',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingChooseService()),
              );
            },
          ),
        ],
      ),
    );
  }
}
