import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppTextButton({
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
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(r.w(10)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.r(10)),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w600,
            fontSize: r.sp(16),
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
