import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' show Vector3;

extension Matrix4Extension on Matrix4 {
  void spTranslate(
    dynamic x, [
    double y = 0.0,
    double z = 0.0,
  ]) {
    return translateByVector3(Vector3(x, y, z));
  }
}
