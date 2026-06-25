import 'package:flutter/material.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return SizedBox(
      width: r.w(149),
      height: r.h(54),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          padding: EdgeInsets.all(r.w(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.r(10)),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontFamily: 'Raleway',
            fontWeight: FontWeight.w600,
            fontSize: r.sp(16),
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
