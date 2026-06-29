import 'dart:math';
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
  bool get isLandscape => screenWidth > screenHeight;

  ScreenType get screenType {
    final shortSide = min(screenWidth, screenHeight);
    if (shortSide < _mobileBreak) return ScreenType.mobile;
    if (shortSide < _tabletBreak) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  double get _effectiveWidth {
    final width = isLandscape
        ? min(screenWidth * 0.5, maxContentWidth)
        : screenWidth;
    return width.clamp(320.0, maxContentWidth);
  }

  double get _effectiveHeight {
    final height = isLandscape ? screenHeight : screenHeight;
    return height.clamp(480.0, 932.0);
  }

  double get _scaleWidth => _effectiveWidth / _designWidth;
  double get _scaleHeight => _effectiveHeight / _designHeight;
  double get _scale => min(_scaleWidth, _scaleHeight);

  double w(double width) => width * _scaleWidth;
  double h(double height) => height * _scaleHeight;

  double sp(double fontSize) {
    final scaled = fontSize * _scale;
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(scaled);
  }

  double r(double radius) => radius * _scale;

  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isLandscape && isMobile) return tablet;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final maxWidth = isLandscape
            ? min(constraints.maxWidth * 0.5, Responsive.maxContentWidth)
            : Responsive.maxContentWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
