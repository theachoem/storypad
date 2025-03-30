import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

mixin StoryPagesManagable on ChangeNotifier {
  List<TextEditingController> titleControllers = [];
  List<QuillController> quillControllers = [];
  List<ScrollController> scrollControllers = [];
  List<FocusNode> focusNodes = [];

  late final PageController pageController;
  final ValueNotifier<double> currentPageNotifier = ValueNotifier(0);
  final ValueNotifier<DateTime?> lastSavedAtNotifier = ValueNotifier(null);

  final ValueNotifier<bool> draggingNotifier = ValueNotifier(false);

  bool get canDeletePage => pagesCount > 1;
  int get pagesCount => quillControllers.length;
  int get currentPage => currentPageNotifier.value.round();
  int get currentPageIndex => pageController.page!.round().toInt();

  bool get canEditPages => true;

  late bool _managingPage = false;
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

  void reorderPages({
    required int oldIndex,
    required int newIndex,
  }) {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPageNotifier.dispose();
    lastSavedAtNotifier.dispose();

    for (var e in focusNodes) {
      e.dispose();
    }

    for (var e in titleControllers) {
      e.dispose();
    }

    for (var e in quillControllers) {
      e.dispose();
    }

    for (var e in scrollControllers) {
      e.dispose();
    }

    super.dispose();
  }
}
