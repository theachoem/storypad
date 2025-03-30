import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

mixin StoryPagesManagable on ChangeNotifier {
  Map<int, TextEditingController> titleControllers = {};
  Map<int, QuillController> quillControllers = {};
  Map<int, ScrollController> scrollControllers = {};
  Map<int, FocusNode> focusNodes = {};

  late final PageController pageController;
  final ValueNotifier<double> currentPageNotifier = ValueNotifier(0);
  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);

  int get pagesCount => quillControllers.length;
  int get currentPage => currentPageNotifier.value.round();
  int get currentPageIndex => pageController.page!.round().toInt();

  bool get canEditPages => false;

  bool get initialManagingPage => false;

  late bool _managingPage = initialManagingPage;
  bool get managingPage => _managingPage;
  void toggleManagingPage() {
    _managingPage = !_managingPage;
    notifyListeners();
  }

  Future<void> addPage() {
    throw UnimplementedError();
  }

  Future<void> deletePage(int index) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPageNotifier.dispose();
    focusNodes.forEach((e, k) => k.dispose());
    titleControllers.forEach((e, k) => k.dispose());
    quillControllers.forEach((e, k) => k.dispose());
    scrollControllers.forEach((e, k) => k.dispose());
    lastSavedAtNotifier.dispose();
    super.dispose();
  }
}
