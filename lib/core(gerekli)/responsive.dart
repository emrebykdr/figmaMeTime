import 'dart:math';
import 'package:flutter/material.dart';

class Responsive {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;
  static const double maxAppWidth = 430.0;
  static const double maxAppHeight = 932.0;

  final BuildContext context;

  Responsive(this.context);

  double get screenWidth =>
      min(MediaQuery.of(context).size.width, maxAppWidth);
  double get screenHeight =>
      min(MediaQuery.of(context).size.height, maxAppHeight);

  double w(double width) => width * screenWidth / _designWidth;
  double h(double height) => height * screenHeight / _designHeight;
  double sp(double fontSize) => fontSize * screenWidth / _designWidth;
  double r(double radius) => radius * screenWidth / _designWidth;
}
