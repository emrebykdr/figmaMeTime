import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/state_dots.dart';
import 'package:figmaap/widgets/service_card.dart';
import 'package:figmaap/pages/onboarding_choose_proffesionel.dart';

class OnboardingChooseTypeNail extends StatelessWidget {
  const OnboardingChooseTypeNail({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    final services = [
      {'image': 'assets/c_1.jpg', 'title': 'Basic Manicure', 'price': '\$30'},
      {'image': 'assets/c_2.jpg', 'title': 'Basic Pedicure', 'price': '\$35'},
      {'image': 'assets/c_3.jpg', 'title': 'Gel Manicure', 'price': '\$50'},
      {'image': 'assets/c_4.jpg', 'title': 'Gel Pedicure', 'price': '\$55'},
      {'image': 'assets/c_5.jpg', 'title': 'Acrylic Extensions', 'price': '\$100'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: r.h(16)),
            _buildTopBar(context, r),
            SizedBox(height: r.h(52)),
            const StateDots(activeIndex: 1),
            SizedBox(height: r.h(38)),
            _buildTitle(r),
            SizedBox(height: r.h(32)),
            Expanded(
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return ServiceCard(
                    imagePath: services[index]['image']!,
                    title: services[index]['title']!,
                    price: services[index]['price']!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingChooseProfessional(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(26)),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(71)),
      child: Text(
        'Now, choose one\nthat fit your needs:',
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
}
