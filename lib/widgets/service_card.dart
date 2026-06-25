import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class ServiceCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;
  final bool isSelected;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: r.w(16),
          vertical: r.h(12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(r.r(8)),
              child: Image.asset(
                imagePath,
                width: r.w(72),
                height: r.w(72),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: r.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(16),
                      height: 1.5,
                      color: AppColors.almostBlack,
                    ),
                  ),
                  Text(
                    price,
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w500,
                      fontSize: r.sp(16),
                      height: 1.5,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: r.w(14),
              color: AppColors.almostBlack,
            ),
          ],
        ),
      ),
    );
  }
}
