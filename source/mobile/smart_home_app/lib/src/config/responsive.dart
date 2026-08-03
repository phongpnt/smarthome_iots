import 'package:flutter/material.dart';

double? height(double? height) => height;
double? width(double? width) => width;

EdgeInsets setPadding({
  double? top,
  double? bottom,
  double? left,
  double? right,
  double? horizontal,
  double? vertical,
  double? all,
}) =>
    EdgeInsets.only(
      top: (top ?? vertical ?? all ?? 0),
      bottom: (bottom ?? vertical ?? all ?? 0),
      left: (left ?? horizontal ?? all ?? 0),
      right: (right ?? horizontal ?? all ?? 0),
    );
EdgeInsets setMargin({
  double? top,
  double? bottom,
  double? left,
  double? right,
  double? horizontal,
  double? vertical,
  double? all,
}) =>
    EdgeInsets.only(
      top: (top ?? vertical ?? all ?? 0),
      bottom: (bottom ?? vertical ?? all ?? 0),
      left: (left ?? horizontal ?? all ?? 0),
      right: (right ?? horizontal ?? all ?? 0),
    );
