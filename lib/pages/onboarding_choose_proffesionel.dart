import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/proffessionals_no_preference.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/state_dots.dart';
import 'package:figmaap/widgets/professional_card.dart';
import 'package:figmaap/widgets/page_sheet.dart';

class OnboardingChooseProfessional extends StatefulWidget {
  const OnboardingChooseProfessional({super.key});

  @override
  State<OnboardingChooseProfessional> createState() =>
      _OnboardingChooseProfessionalState();
}

class _OnboardingChooseProfessionalState
    extends State<OnboardingChooseProfessional> {
  int? _selectedIndex;

  final professionals = [
    {
      'image': 'assets/images/prof_1.jpg',
      'name': 'Anna Smith',
      'role': 'Nail designer',
      'rating': 5.0,
    },
    {
      'image': 'assets/images/prof_2.jpg',
      'name': 'Jordan Mcmiller',
      'role': 'Nail designer',
      'rating': 4.9,
    },
    {
      'image': 'assets/images/prof_3.jpg',
      'name': 'Paty Sinclair',
      'role': 'Nail designer',
      'rating': 4.9,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: r.h(16)),
            _buildTopBar(context, r),
            SizedBox(height: r.h(52)),
            const StateDots(activeIndex: 2),
            SizedBox(height: r.h(38)),
            _buildTitle(r),
            SizedBox(height: r.h(32)),
            Expanded(
              child: ListView.builder(
                itemCount: professionals.length,
                itemBuilder: (context, index) {
                  final pro = professionals[index];
                  return ProfessionalCard(
                    imagePath: pro['image'] as String,
                    name: pro['name'] as String,
                    role: pro['role'] as String,
                    rating: pro['rating'] as double,
                    isSelected: _selectedIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      LoginSheet.show(context, professional: pro);
                    },
                  );
                },
              ),
            ),
            _buildNoPreference(r),
            SizedBox(height: r.h(40)),
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
      padding: EdgeInsets.symmetric(horizontal: r.w(53)),
      child: Text(
        'Choose a professional e\nsee the slots available',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(24),
          height: 1.36,
          letterSpacing: -0.48,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildNoPreference(Responsive r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoPreference()),
        );
      },
      child: Text(
        "I don't have a preference",
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w700,
          fontSize: r.sp(18),
          height: 1.0,
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}
