part of 'quill_adapter.dart';

/// Flutter Quill implementation of RichTextAdapter.
class QuillRichTextAdapter implements RichTextAdapter {
  @override
  List<LocalizationsDelegate> get localizationsDelegates {
    return [quill.FlutterQuillLocalizations.delegate];
  }

  @override
  Widget buildEditor({
    required BuildContext context,
    required RichTextController controller,
    required FocusNode focusNode,
    required ScrollController scrollController,
    required bool readOnly,
    required StoryContentDbModel storyContent,
    PageLayoutType? layoutType,
    VoidCallback? onChanged,
    VoidCallback? onGoToEdit,
  }) {
    return buildQuillEditor(
      context: context,
      controller: controller,
      focusNode: focusNode,
      scrollController: scrollController,
      readOnly: readOnly,
      storyContent: storyContent,
      layoutType: layoutType,
      onChanged: onChanged,
      onGoToEdit: onGoToEdit,
    );
  }

  @override
  Widget buildToolbar({
    required BuildContext context,
    required RichTextController controller,
    Color? backgroundColor,
  }) {
    return buildQuillToolbar(
      context: context,
      controller: controller,
      backgroundColor: backgroundColor,
    );
  }

  @override
  RichTextController createController({
    required List<dynamic> json,
    required TextSelection selection,
    required bool readOnly,
  }) {
    // Handle empty JSON - flutter_quill doesn't accept empty deltas
    if (json.isEmpty) return createEmptyController(readOnly: readOnly);

    return QuillRichTextController.fromJson(
      json: json,
      selection: selection,
      readOnly: readOnly,
    );
  }

  @override
  RichTextController createEmptyController({
    required bool readOnly,
  }) {
    return QuillRichTextController(
      document: quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: readOnly,
    );
  }

  @override
  RichTextDocument createDocument({
    required List<dynamic> json,
  }) {
    // Handle empty JSON - flutter_quill doesn't accept empty deltas
    if (json.isEmpty) {
      return createEmptyDocument();
    }

    return QuillRichTextDocument.fromJson(json);
  }

  @override
  RichTextDocument createEmptyDocument() {
    return QuillRichTextDocument.empty();
  }

  @override
  void insertImage({
    required RichTextController controller,
    required String imagePath,
  }) {
    if (controller is! QuillRichTextController) {
      throw ArgumentError('Controller must be a QuillRichTextController');
    }

    final quillController = controller.quillController;
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;

    quillController.replaceText(
      index,
      length,
      quill.BlockEmbed.image(imagePath),
      null,
    );
    quillController.moveCursorToPosition(index + 1);
  }

  @override
  void insertAudio({
    required RichTextController controller,
    required String audioPath,
  }) {
    if (controller is! QuillRichTextController) {
      throw ArgumentError('Controller must be a QuillRichTextController');
    }

    final quillController = controller.quillController;
    final index = quillController.selection.baseOffset;
    final length = quillController.selection.extentOffset - index;

    final audioEmbed = quill.BlockEmbed('audio', audioPath);

    quillController.replaceText(
      index,
      length,
      audioEmbed,
      null,
    );
    quillController.moveCursorToPosition(index + 1);
  }
}
