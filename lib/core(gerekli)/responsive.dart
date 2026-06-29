import 'dart:math';
import 'package:flutter/material.dart';

enum ScreenType { compact, mobile, tablet, desktop }

class Responsive {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;
  static const double maxContentWidth = 500.0;

  static const double _compactBreak = 320.0;
  static const double _mobileBreak = 600.0;
  static const double _tabletBreak = 1024.0;

  final BuildContext context;

  Responsive(this.context);

  double get screenWidth => MediaQuery.sizeOf(context).width;
  double get screenHeight => MediaQuery.sizeOf(context).height;
  bool get isLandscape => screenWidth > screenHeight;
  double get shortSide => min(screenWidth, screenHeight);
  double get longSide => max(screenWidth, screenHeight);

  ScreenType get screenType {
    if (shortSide < _compactBreak) return ScreenType.compact;
    if (shortSide < _mobileBreak) return ScreenType.mobile;
    if (shortSide < _tabletBreak) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  bool get isCompact => screenType == ScreenType.compact;
  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  double get _effectiveWidth {
    if (isLandscape) {
      return min(screenWidth * 0.5, maxContentWidth).clamp(280.0, maxContentWidth);
    }
    return screenWidth.clamp(280.0, maxContentWidth);
  }

  double get _effectiveHeight {
    return screenHeight.clamp(480.0, 932.0);
  }

  double get _scaleWidth => _effectiveWidth / _designWidth;
  double get _scaleHeight => _effectiveHeight / _designHeight;
  double get _scale => min(_scaleWidth, _scaleHeight);

  double w(double width) => width * _scaleWidth;
  double h(double height) => height * _scaleHeight;

  double sp(double fontSize) {
    final scaled = fontSize * _scale;
    final clamped = scaled.clamp(fontSize * 0.75, fontSize * 1.4);
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(clamped);
  }

  double r(double radius) => radius * _scale;

  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isLandscape && isMobile) return tablet;
    if (isCompact) return 1;
    switch (screenType) {
      case ScreenType.compact:
        return 1;
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  double get horizontalPadding {
    if (isCompact) return w(16);
    if (isTablet || isDesktop) return w(40);
    return w(30);
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
            : min(constraints.maxWidth, Responsive.maxContentWidth);

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
