import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';

class SalonPage extends StatelessWidget {
  const SalonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(context, r),
            SizedBox(height: r.h(24)),
            _buildActionButtons(r),
            SizedBox(height: r.h(16)),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: r.h(16)),
            _buildCoupons(r),
            SizedBox(height: r.h(16)),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: r.h(24)),
            _buildCustomerReviews(r),
            SizedBox(height: r.h(32)),
            _buildWriteReviewButton(r),
            SizedBox(height: r.h(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Responsive r) {
    return SizedBox(
      width: double.infinity,
      height: r.h(380),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/salon.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(26)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      'assets/icons/light.svg',
                      width: r.w(24),
                      height: r.w(24),
                    ),
                  ),
                  const Spacer(),
                  const AppHeader(),
                  const Spacer(),
                  SizedBox(width: r.w(24)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: r.h(50),
            left: r.w(30),
            child: Text(
              'The Gallery Salon',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: r.sp(32),
                color: AppColors.white,
              ),
            ),
          ),
          Positioned(
            bottom: r.h(24),
            left: r.w(30),
            child: Text(
              '8502 Preston Rd. Inglewood  •  \$\$',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(14),
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionItemImage(r, 'assets/icons/phone.png', 'Call'),
          _buildActionItem(r, Icons.chat_bubble_outline, 'Message'),
          _buildActionItem(r, Icons.person_outline, 'Directions'),
          _buildActionItem(r, Icons.ios_share, 'Share'),
        ],
      ),
    );
  }

  Widget _buildActionItemImage(Responsive r, String imagePath, String label) {
    return Column(
      children: [
        Container(
          width: r.w(56),
          height: r.w(56),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(r.r(12)),
          ),
          child: Center(
            child: Image.asset(imagePath, width: r.w(28), height: r.w(28)),
          ),
        ),
        SizedBox(height: r.h(8)),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(12),
            color: AppColors.almostBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(Responsive r, IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: r.w(56),
          height: r.w(56),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(r.r(12)),
          ),
          child: Icon(icon, size: r.w(28), color: AppColors.almostBlack),
        ),
        SizedBox(height: r.h(8)),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(12),
            color: AppColors.almostBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildCoupons(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Row(
        children: [
          Expanded(child: _buildCouponCard(r, '10% off', 'use code FREE10')),
          SizedBox(width: r.w(12)),
          Expanded(child: _buildCouponCard(r, '30% off on Debit Card', 'No coupon required')),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Responsive r, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.r(10)),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/Frame 21.svg',
                width: r.w(28),
                height: r.w(28),
              ),
              SizedBox(width: r.w(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                    fontSize: r.sp(14),
                    color: AppColors.almostBlack,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.h(4)),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(12),
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviews(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer reviews',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(22),
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(8)),
          Text(
            '4.8 out of 5',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            '27 global ratings',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(14),
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(20)),
          _buildRatingBar(r, 5.0, 0.80),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 4.5, 0.10),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 3.0, 0.05),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 2.0, 0.05),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 1.0, 0.00),
        ],
      ),
    );
  }

  Widget _buildRatingBar(Responsive r, double starRating, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: r.w(120),
          child: Row(
            children: List.generate(5, (index) {
              IconData icon;
              if (index < starRating.floor()) {
                icon = Icons.star;
              } else if (index < starRating) {
                icon = Icons.star_half;
              } else {
                icon = Icons.star_border;
              }
              return Icon(
                icon,
                size: r.w(20),
                color: const Color(0xFFFFB800),
              );
            }),
          ),
        ),
        SizedBox(width: r.w(12)),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(14),
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildWriteReviewButton(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(40)),
      child: SizedBox(
        width: double.infinity,
        height: r.h(54),
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(30)),
            ),
          ),
          child: Text(
            'Write a review',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
          ),
        ),
      ),
    );
  }
}
