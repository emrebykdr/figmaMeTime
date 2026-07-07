import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/main_page.dart';
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
          padding: EdgeInsets.symmetric(horizontal: r.w(47)),
          child: Column(
            children: [
              SizedBox(height: r.h(50)),
              _buildHeartIcon(r),
              _buildTitle(r),
              SizedBox(height: r.h(50)),
              _buildDetails(r),
              const Spacer(),
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
    return SizedBox(
      width: r.w(281),
      height: r.h(252),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            'assets/images/s_kalp.png',
            width: r.w(120),
            height: r.w(120),
            fit: BoxFit.cover,
          ),
        ),
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
          letterSpacing: -0.48,
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
    return SizedBox(
      width: r.w(226),
      child: Column(
        children: [
          Text(
            'Your booking details:',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              height: 1.36,
              letterSpacing: -0.48,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(16)),
          Text(
            '$day    $time',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              height: 1.36,
              letterSpacing: -0.48,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: r.h(16)),
          Text(
            'At The Gallery Salon',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              height: 1.36,
              letterSpacing: -0.48,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(16)),
          Text(
            '8502 Preston Rd. Inglewood',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(18),
              height: 1.36,
              letterSpacing: -0.48,
              color: AppColors.secondary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeepBookingButton(BuildContext context, Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(293),
        height: r.h(54),
        child: ElevatedButton(
          onPressed: () {
            // Yeni oluşturulan randevu admin onaylayana kadar 'waiting'
            // statüsünde durur (bkz. booking_service.dart addBooking), bu
            // yüzden Upcoming değil Waiting sekmesine yönlendiriyoruz.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingsPage(initialTab: 2)),
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
          MaterialPageRoute(builder: (_) => const MainPage()),
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
