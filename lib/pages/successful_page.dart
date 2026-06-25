import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/home_page.dart';
import 'package:figmaap/pages/bookings_page.dart';

class SuccessfulPage extends StatelessWidget {
  final String day;
  final String time;

  const SuccessfulPage({
    super.key,
    required this.day,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(30)),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildHeartIcon(r),
              SizedBox(height: r.h(40)),
              _buildTitle(r),
              SizedBox(height: r.h(40)),
              _buildDetails(r),
              const Spacer(flex: 3),
              _buildKeepBookingButton(context, r),
              SizedBox(height: r.h(16)),
              _buildMainPageButton(context, r),
              SizedBox(height: r.h(30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartIcon(Responsive r) {
    return ClipOval(
      child: Image.asset(
        'assets/s_kalp.png',
        width: r.w(120),
        height: r.w(120),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTitle(Responsive r) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(24),
          height: 1.36,
          color: AppColors.almostBlack,
        ),
        children: const [
          TextSpan(text: 'Thank you for booking\nwith '),
          TextSpan(
            text: 'MeTime',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Responsive r) {
    return Column(
      children: [
        Text(
          'Your booking details:',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(16),
            color: AppColors.tertiary,
          ),
        ),
        SizedBox(height: r.h(16)),
        Text(
          '$day    $time',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w600,
            fontSize: r.sp(18),
            color: AppColors.almostBlack,
          ),
        ),
        SizedBox(height: r.h(8)),
        Text(
          'At The Gallery Salon',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(16),
            color: AppColors.tertiary,
          ),
        ),
        SizedBox(height: r.h(8)),
        Text(
          '8502 Preston Rd. Inglewood',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(16),
            color: AppColors.almostBlack,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  Widget _buildKeepBookingButton(BuildContext context, Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(293),
        height: r.h(54),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingsPage(initialTab: 1)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(10)),
            ),
          ),
          child: Text(
            'Keep booking',
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

  Widget _buildMainPageButton(BuildContext context, Responsive r) {
    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      },
      child: Text(
        'Main page',
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(16),
          color: AppColors.primary,
        ),
      ),
    );
  }
}
