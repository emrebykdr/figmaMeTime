import 'package:flutter/material.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/onboarding_choose_type_nail.dart';
import 'package:figmaap/pages/onboarding_choose_type_eyebrown.dart';
import 'package:figmaap/pages/onboarding_choose_type_massage.dart';
import 'package:figmaap/pages/onboarding_choose_type_hair.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/state_dots.dart';
import 'package:figmaap/widgets/login_sheet.dart';

class OnboardingChooseService extends StatelessWidget {
  const OnboardingChooseService({super.key});

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
            SizedBox(height: r.h(52)),
            const StateDots(activeIndex: 0),
            SizedBox(height: r.h(48)),
            _buildTitle(r),
            SizedBox(height: r.h(40)),
            _buildServiceGrid(r),
            const Spacer(),
            _buildSkipButton(context, r),
            SizedBox(height: r.h(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(52)),
      child: Text(
        'Please, choose a service:',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(24),
          height: 1.36,
          letterSpacing: -0.48,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildServiceGrid(Responsive r) {
    final services = [
      {'image': 'assets/choose_nail.jpg', 'label': 'Nail'},
      {'image': 'assets/choose_eyebrown.jpg', 'label': 'Eyebrowns'},
      {'image': 'assets/choose_massage.jpg', 'label': 'Massage'},
      {'image': 'assets/choose_hair.jpg', 'label': 'Hair'},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(40)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: r.w(24),
          mainAxisSpacing: r.h(16),
          childAspectRatio: 0.78,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(
            context,
            r,
            services[index]['image']!,
            services[index]['label']!,
          );
        },
      ),
    );
  }

  Widget _getTargetPage(String label) {
    switch (label) {
      case 'Nail':
        return const OnboardingChooseTypeNail();
      case 'Eyebrowns':
        return const OnboardingChooseTypeEyebrown();
      case 'Massage':
        return const OnboardingChooseTypeMassage();
      case 'Hair':
        return const OnboardingChooseTypeHair();
      default:
        return const OnboardingChooseTypeNail();
    }
  }

  Widget _buildServiceCard(
    BuildContext context,
    Responsive r,
    String imagePath,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _getTargetPage(label)),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(r.r(10)),
              child: Image.asset(
                imagePath,
                width: r.w(125),
                height: r.w(125),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: r.h(8)),
          Text(
            label,
            style: TextStyle(fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              height: 1.0,
              letterSpacing: 0.14,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context, Responsive r) {
    return SizedBox(
      width: r.w(271),
      height: r.h(54),
      child: TextButton(
        onPressed: () => LoginSheet.show(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(r.w(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.r(10)),
          ),
        ),
        child: Text(
          'Skip',
          style: TextStyle(fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: r.sp(16),
            height: 1.0,
            letterSpacing: -0.48,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
