import 'package:flutter/material.dart';

class Responsive {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;
  static const double maxAppWidth = 430.0;
  static const double maxAppHeight = 932.0;
  static const double _minAppWidth = 320.0;
  static const double _minAppHeight = 568.0;

  final BuildContext context;

  Responsive(this.context);

  double get _screenWidth {
    final width = MediaQuery.sizeOf(context).width;
    return width.clamp(_minAppWidth, maxAppWidth);
  }

  double get _screenHeight {
    final height = MediaQuery.sizeOf(context).height;
    return height.clamp(_minAppHeight, maxAppHeight);
  }

  double get _scaleWidth => _screenWidth / _designWidth;
  double get _scaleHeight => _screenHeight / _designHeight;

  double w(double width) => width * _scaleWidth;

  double h(double height) => height * _scaleHeight;

  double sp(double fontSize) {
    final scaled = fontSize * _scaleWidth;
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(scaled);
  }

  double r(double radius) => radius * _scaleWidth;
}
