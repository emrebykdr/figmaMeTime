import 'package:flutter/material.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class ProfessionalCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final String role;
  final double rating;
  final bool isSelected;
  final VoidCallback? onTap;

  const ProfessionalCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.role,
    required this.rating,
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
          horizontal: r.w(30),
          vertical: r.h(12),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0x267A7A7A),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(r.r(12)),
              child: Image.asset(
                imagePath,
                width: r.w(83),
                height: r.w(83),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: r.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(16),
                      height: 1.5,
                      color: AppColors.almostBlack,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(fontFamily: 'Raleway',
                      fontWeight: FontWeight.w500,
                      fontSize: r.sp(14),
                      height: 1.5,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: r.w(18),
                  color: const Color(0xFFFFD700),
                ),
                SizedBox(width: r.w(4)),
                Text(
                  rating.toString(),
                  style: TextStyle(fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    fontSize: r.sp(14),
                    color: AppColors.almostBlack,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
