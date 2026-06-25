import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

class StateDots extends StatelessWidget {
  final int totalDots;
  final int activeIndex;

  const StateDots({
    super.key,
    this.totalDots = 4,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: index < totalDots - 1 ? r.w(10) : 0),
          child: Container(
            width: isActive ? r.w(40) : r.w(10),
            height: r.h(10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.dotInactive,
              borderRadius: BorderRadius.circular(r.r(5)),
            ),
          ),
        );
      }),
    );
  }
}
