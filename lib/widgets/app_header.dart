import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Text(
      'MeTime',
      style: GoogleFonts.raleway(
        fontWeight: FontWeight.w700,
        fontSize: r.sp(19),
        height: 1.0,
        letterSpacing: -0.67,
        color: AppColors.almostBlack,
      ),
    );
  }
}
