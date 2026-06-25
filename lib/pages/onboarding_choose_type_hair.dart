import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/state_dots.dart';
import 'package:figmaap/widgets/service_card.dart';

class OnboardingChooseTypeHair extends StatelessWidget {
  const OnboardingChooseTypeHair({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    final services = [
      {'image': 'assets/choose_hair.jpg', 'title': 'Haircut', 'price': '\$35'},
      {'image': 'assets/choose_hair.jpg', 'title': 'Hair Coloring', 'price': '\$70'},
      {'image': 'assets/choose_hair.jpg', 'title': 'Blowout', 'price': '\$40'},
      {'image': 'assets/choose_hair.jpg', 'title': 'Keratin Treatment', 'price': '\$120'},
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
                    onTap: () {},
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(71)),
      child: Text(
        'Now, choose one\nthat fit your needs:',
        textAlign: TextAlign.center,
        style: GoogleFonts.raleway(
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
