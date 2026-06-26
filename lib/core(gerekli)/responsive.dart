import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;
  static const double maxContentWidth = 500.0;

  static const double _mobileBreak = 600.0;
  static const double _tabletBreak = 1024.0;

  final BuildContext context;

  Responsive(this.context);

  double get screenWidth => MediaQuery.sizeOf(context).width;
  double get screenHeight => MediaQuery.sizeOf(context).height;

  ScreenType get screenType {
    if (screenWidth < _mobileBreak) return ScreenType.mobile;
    if (screenWidth < _tabletBreak) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  double get _effectiveWidth {
    if (screenWidth > maxContentWidth) return maxContentWidth;
    return screenWidth.clamp(320.0, maxContentWidth);
  }

  double get _effectiveHeight {
    return screenHeight.clamp(568.0, 932.0);
  }

  double get _scaleWidth => _effectiveWidth / _designWidth;
  double get _scaleHeight => _effectiveHeight / _designHeight;

  double w(double width) => width * _scaleWidth;
  double h(double height) => height * _scaleHeight;

  double sp(double fontSize) {
    final scaled = fontSize * _scaleWidth;
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(scaled);
  }

  double r(double radius) => radius * _scaleWidth;

  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: child,
      ),
    );
  }
}
