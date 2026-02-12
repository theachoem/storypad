import 'package:flutter/material.dart';

extension FontWeightExtension on FontWeight {
  int get weightIndex => (value ~/ 100 - 1).clamp(0, 8);
}
