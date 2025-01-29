import 'package:flutter/material.dart';
import 'package:storypad/core/base/base_view_model.dart';

mixin KeyboardHeightConcern on BaseViewModel {
  double get minimumKeyboardHeight => 300;
  double? _keyboardHeight;
  double get keyboardHeight => _keyboardHeight ?? minimumKeyboardHeight;

  void _setKeyboardHeight(double height) {
    if (height == 0) return;
    if (height <= keyboardHeight) return;

    _keyboardHeight = height;
  }

  @override
  void onBuild(BuildContext context) {
    _setKeyboardHeight(MediaQuery.of(context).viewInsets.bottom);
  }
}
