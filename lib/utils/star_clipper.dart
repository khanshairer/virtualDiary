import 'package:flutter/material.dart';

class StarClipper extends CustomClipper<Rect> {
  final double fillPercent;

  StarClipper(this.fillPercent);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fillPercent, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return (oldClipper as StarClipper).fillPercent != fillPercent;
  }
}
