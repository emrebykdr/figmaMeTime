import 'package:flutter/material.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/login_phone.dart';


class LoginSheet extends StatelessWidget {
  const LoginSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const LoginSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(41), vertical: r.h(40)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hey there!',
            style: TextStyle(fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(32),
              height: 1.3,
              letterSpacing: -0.32,
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(10)),
          Text(
            'Before schedule, please enter\nyour account or create one!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              height: 1.21,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(37)),
          SizedBox(
            width: r.w(293),
            height: r.h(61),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPhone()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.almostBlack,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(r.r(10)),
                ),
              ),
              child: Text(
                'Log In',
                style: TextStyle(fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(16),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: r.h(20)),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Create Account',
              style: TextStyle(fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: r.sp(16),
                height: 1.25,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: r.h(20)),
        ],
      ),
    );
  }
}
