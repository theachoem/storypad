import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';

import '../../controller/story_editor_controller.dart';
import '../style/story_editor_spacing.dart';
import '../input/story_link_tap_handler.dart';
import '../menus/story_context_menu_action.dart';
import '../style/story_block_style.dart';
import '../menus/android/story_process_text.dart';
import '../menus/ios/story_ios_system_context_menu.dart';
import '../menus/android/android_text_editing_floating_toolbar_with_process_text.dart';
import '../components/text_selection_highlight_component_builder.dart';
import '../style/framed_component_builder.dart';
import '../components/no_padding_blockquote_component_builder.dart';
import '../components/compact_paragraph_component_builder.dart';
import '../components/compact_list_item_component_builder.dart';
import '../components/story_embed_component_builder.dart';
import '../components/compact_task_component_builder.dart';
import '../menus/reader_menu.dart';
import '../menus/ios/story_ios_reader_toolbar.dart';
import '../menus/android/story_android_reader_toolbar.dart';
import '../menus/desktop/desktop_context_menu_region.dart';
import '../menus/desktop/desktop_context_menu.dart';
import 'sliver_box.dart';
import '../input/free_task_indent.dart';
import '../reorder/reorderable_document_overlay.dart';
import 'story_editor_layout.dart';

/// The editing surface for a [StoryEditorController]: renders its document and every embed, and handles input,
/// selection and platform chrome. Format-agnostic -- see `MarkdownEditor` for Markdown change notifications.
///
/// Brings no formatting toolbar of its own: build one from the controller (`controller.actions` for commands,
/// `controller.isToolbarActive` for show-on-focus, `controller.tapRegionGroupId` and `controller.holdSelection` so
/// using it doesn't dismiss the editor's selection).
///
/// When the controller is read-only, the document is shown in super_editor's `SuperReader` instead: selectable and
/// copyable, no typing, no reordering -- but task checkboxes still toggle (an edit, reported like any other), and
/// embeds render as usual, told `readOnly` so they can hide their editing controls. The scroll position is kept
/// across the switch.
///
/// Platform behavior:
/// - Desktop/web: drag handles to reorder blocks, and a right-click menu ([desktopContextMenu]).
/// - iOS: the OS-native context menu on a selection (Flutter-painted before iOS 16).
/// - Android: a floating toolbar with the OS "Process Text" actions (Translate, …).
/// - Touch: no reordering of its own: move blocks with `actions.moveSelectedBlocks` (e.g. toolbar buttons). Tapping
///   outside doesn't unfocus it; the keyboard's own key hides it.
///
/// Links open through [onTapLink]: on tap when read-only, on Cmd/Ctrl-click while editing.
///
/// [layout] decides how it sizes and scrolls: filling its box and scrolling itself (the default), as a box sized to
/// its content inside another scroll view, or as a sliver.
class RawEditor extends StatefulWidget {
  const RawEditor({
    super.key,
    required this.controller,
    this.baseTextStyle,
    this.spacing = const StoryEditorSpacing(),
    this.styleRules = const [],
    this.scrollController,
    this.autofocus = false,
    this.inputRole,
    this.layout = StoryEditorLayout.scrolling,
    this.desktopContextMenu = DesktopContextMenu.showDefault,
    this.onTapLink,
    this.caretColor,
    this.selectionColor,
    this.placeholder,
    this.placeholderStyle,
    this.checkboxesEnabled = true,
    this.contextMenuActions = const [],
    this.blockStyles,
  });

  final StoryEditorController controller;

  /// Merged into every block's text style -- e.g. a font. Per-block styling (heading sizes, …) is kept.
  final TextStyle? baseTextStyle;

  /// The space around the document ([StoryEditorSpacing.page], used exactly as given: text spans the full width inside
  /// it, with no maximum width or centering -- any of that is the app's choice) and above and below each block.
  final StoryEditorSpacing spacing;

  /// Extra stylesheet rules, applied after the editor's own and [spacing] -- e.g.
  /// `StyleRule(BlockSelector('media'), …)` to style an embed type, or a blockquote border.
  final List<StyleRule> styleRules;

  final ScrollController? scrollController;

  final bool autofocus;

  /// Give each editor a distinct value when several are on screen at once (their IME connections are told apart by
  /// it).
  final String? inputRole;

  /// How the editor sizes and scrolls. See [StoryEditorLayout].
  final StoryEditorLayout layout;

  /// Shows the desktop right-click menu. Defaults to [DesktopContextMenu.showDefault]: native on macOS, Flutter-painted
  /// elsewhere. `null` for none.
  final DesktopContextMenuHandler? desktopContextMenu;

  /// Called when a link is tapped -- in read-only mode, or with Cmd/Ctrl held while editing (a plain tap places the
  /// caret). `null` opens the link with the platform's URL launcher.
  final LinkTapCallback? onTapLink;

  /// The caret, and on mobile the selection handles and magnifier too. Defaults to the theme's cursor color
  /// (`TextSelectionTheme`), else its primary color.
  final Color? caretColor;

  /// The selection highlight. Defaults to the theme's selection color (`TextSelectionTheme`), else its primary color
  /// at 40% opacity.
  final Color? selectionColor;

  /// Shown while the document is a single empty paragraph.
  final String? placeholder;

  /// The [placeholder]'s style. Defaults to [baseTextStyle] in the theme's hint color.
  final TextStyle? placeholderStyle;

  /// Whether task checkboxes toggle -- also while read-only, where it's the only edit (reported like any other).
  /// Turn off for a view whose changes wouldn't be kept.
  final bool checkboxesEnabled;

  /// Extra items for the selection menus (Android toolbar, iOS system menu, desktop right-click menu), after the
  /// platform's own. See [StoryContextMenuAction] for where each shows.
  final List<StoryContextMenuAction> contextMenuActions;

  /// Frames per block type (`blockquote`, `code`, an embed's type, …): a background/border and the padding between it
  /// and the content. Defaults to a tinted quote with a left bar and a tinted code box, from the theme. Space *between*
  /// blocks is [spacing].
  final Map<String, StoryBlockStyle>? blockStyles;

  @override
  State<RawEditor> createState() => _RawEditorState();

  /// The default left padding on desktop/web: room for [ReorderableDocumentOverlay]'s full-size drag handle (it
  /// shrinks to fit a narrower padding the app passes, see `ReorderableDocumentOverlay.handleSizeFor`).
  static const _defaultDesktopLeftPadding = 18.0;

  /// The IME keyboard actions (super_editor's default input source), with free task indent swapped in, and without
  /// `enterToUnIndentParagraph`: Enter on an empty indented paragraph keeps its indent, as an on-screen keyboard's
  /// Enter does (it never runs keyboard actions) -- see `KeepIndent.newlineHandler`.
  static final _keyboardActions = List<SuperEditorKeyboardAction>.unmodifiable([
    for (final action in defaultImeKeyboardActions)
      if (action == enterToUnIndentParagraph)
        ...[]
      else if (action == tabToIndentTask)
        FreeTaskIndent.tab
      else if (action == shiftTabToUnIndentTask)
        FreeTaskIndent.shiftTab
      else
        action,
  ]);
}

class _RawEditorState extends State<RawEditor> {
  final _documentLayoutKey = GlobalKey();
  late CommonEditorOperations _editorOps;
  // The mobile controls (caret, handles, magnifier, toolbar), in the caret color: made on the first build, and again
  // whenever the color changes (super_editor only takes it when they're created).
  SuperEditorIosControlsController? _iosControlsController;
  SuperEditorAndroidControlsController? _androidControlsController;
  SuperReaderIosControlsController? _iosReaderControlsController;
  Color? _controlsColor;

  /// The scroll controller both the editor and the reader use, so the offset can be carried across a read-only switch.
  ScrollController? _ownScrollController;
  ScrollController get _scrollController => widget.scrollController ?? (_ownScrollController ??= ScrollController());

  /// Android "Process Text" actions, queried up front and again whenever a selection starts or the app comes back (an
  /// app may have been installed, removed or updated meanwhile), as a native TextView queries them for each menu --
  /// ahead of the menu, so it shows them at once.
  List<ProcessTextAction> _androidProcessTextActions = const [];
  AppLifecycleListener? _processTextLifecycle;
  bool _hadExpandedSelection = false;

  StoryEditorController get _controller => widget.controller;

  bool get _isDesktopOrWeb =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  DocumentLayout _layout() => _documentLayoutKey.currentState! as DocumentLayout;

  @override
  void initState() {
    super.initState();
    _attach(_controller);
    if (_queriesProcessText) {
      _processTextLifecycle = AppLifecycleListener(onResume: _queryAndroidProcessTextActions);
      _queryAndroidProcessTextActions();
    }
  }

  @override
  void didUpdateWidget(RawEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, _controller)) {
      _detach(oldWidget.controller);
      _attach(_controller);
      _componentBuildersCache = null;
    }
    if (oldWidget.placeholder != widget.placeholder ||
        oldWidget.placeholderStyle != widget.placeholderStyle ||
        oldWidget.baseTextStyle != widget.baseTextStyle ||
        oldWidget.checkboxesEnabled != widget.checkboxesEnabled) {
      _componentBuildersCache = null;
    }
    if (oldWidget.baseTextStyle != widget.baseTextStyle ||
        oldWidget.spacing != widget.spacing ||
        !identical(oldWidget.styleRules, widget.styleRules)) {
      _stylesheetCache = null;
    }
  }

  // Out of the tree (replaced, or being moved with a GlobalKey): not using the controller until reinserted.
  @override
  void deactivate() {
    _controller.detachEditor(this);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _controller.attachEditor(this);
  }

  @override
  void dispose() {
    _detach(_controller);
    _processTextLifecycle?.dispose();
    _disposeControls(_iosControlsController, _androidControlsController, _iosReaderControlsController);
    _ownScrollController?.dispose();
    super.dispose();
  }

  void _attach(StoryEditorController controller) {
    controller.attachEditor(this);
    _editorOps = CommonEditorOperations(
      document: controller.document,
      editor: controller.editor,
      composer: controller.composer,
      documentLayoutResolver: _layout,
    );
    // A selection hold suspends mobile's clear-selection-on-blur policy.
    controller.isSelectionHeld.addListener(_rebuild);
    controller.readOnlyListenable.addListener(_onReadOnlyChanged);
    if (_queriesProcessText) controller.composer.selectionNotifier.addListener(_onSelectionForProcessText);
  }

  void _detach(StoryEditorController controller) {
    controller.isSelectionHeld.removeListener(_rebuild);
    controller.readOnlyListenable.removeListener(_onReadOnlyChanged);
    controller.composer.selectionNotifier.removeListener(_onSelectionForProcessText);
    controller.detachEditor(this);
  }

  /// Swaps editor/reader, restoring the scroll offset once the new scrollable is laid out.
  void _onReadOnlyChanged() {
    final scrollController = _scrollController;
    // Only an editor scrolling itself owns its offset; box and sliver editors live in someone else's scroll view.
    final offset = widget.layout == StoryEditorLayout.scrolling && scrollController.hasClients
        ? scrollController.offset
        : null;
    _rebuild();
    if (offset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      final position = scrollController.position;
      scrollController.jumpTo(offset.clamp(position.minScrollExtent, position.maxScrollExtent));
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  bool get _queriesProcessText => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _queryAndroidProcessTextActions() async {
    final actions = await StoryProcessText.queryTextActions();
    if (mounted && !listEquals(actions, _androidProcessTextActions)) {
      setState(() => _androidProcessTextActions = actions);
    }
  }

  void _onSelectionForProcessText() {
    final expanded = _controller.composer.selection?.isCollapsed == false;
    if (expanded && !_hadExpandedSelection) _queryAndroidProcessTextActions();
    _hadExpandedSelection = expanded;
  }

  // These toolbar builders must never early-return based on the selection: super_editor calls them once and caches
  // the result, so each returned widget reacts to selection changes itself.

  Widget _buildIosToolbar(BuildContext context, Key mobileToolbarKey, LeaderLink focalPoint) {
    // With extra items, the system menu comes from us (super_editor's can only show the standard ones).
    if (widget.contextMenuActions.isNotEmpty &&
        !kIsWeb &&
        (MediaQuery.maybeSupportsShowingSystemContextMenu(context) ?? false)) {
      return StoryIosSystemContextMenu(
        leaderLink: focalPoint,
        selection: _controller.composer.selectionNotifier,
        extraActions: widget.contextMenuActions,
      );
    }
    return iOSSystemPopoverEditorToolbarWithFallbackBuilder(
      context,
      mobileToolbarKey,
      focalPoint,
      _editorOps,
      SuperEditorIosControlsScope.rootOf(context),
    );
  }

  Widget _buildAndroidToolbar(BuildContext context, Key mobileToolbarKey, LeaderLink focalPoint) {
    return AndroidTextEditingFloatingToolbarWithProcessText(
      floatingToolbarKey: mobileToolbarKey,
      focalPoint: focalPoint,
      document: _controller.document,
      editorOps: _editorOps,
      editorControlsController: SuperEditorAndroidControlsScope.rootOf(context),
      selectionNotifier: _controller.composer.selectionNotifier,
      processTextActions: _androidProcessTextActions,
      extraActions: widget.contextMenuActions,
      selectionRect: _selectionGlobalRect,
      replaceSelection: _replaceSelection,
    );
  }

  /// Replaces the selection with [text] (what a process-text app returned), as one undo step, as a native TextView
  /// does. (super_editor's `CommonEditorOperations.insertPlainText` also puts an empty paragraph before it: its
  /// "not in a text block" check tests the position, not the block.)
  void _replaceSelection(String text) {
    final selection = _controller.composer.selection;
    if (selection == null) return;
    final start = selection.normalize(_controller.document).start;
    _controller.editor.execute([
      if (!selection.isCollapsed) DeleteContentRequest(documentRange: selection),
      ChangeSelectionRequest(
        DocumentSelection.collapsed(position: start),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      InsertPlainTextAtCaretRequest(text),
    ]);
  }

  /// The selection's rect on screen, or null without an expanded one laid out.
  Rect? _selectionGlobalRect() {
    final selection = _controller.composer.selection;
    if (selection == null || _documentLayoutKey.currentState == null) return null;
    final layout = _layout();
    final rect = layout.getRectForSelection(selection.base, selection.extent);
    if (rect == null) return null;
    return Rect.fromPoints(
      layout.getGlobalOffsetFromDocumentOffset(rect.topLeft),
      layout.getGlobalOffsetFromDocumentOffset(rect.bottomRight),
    );
  }

  // Cached: super_editor rebuilds its whole layout presenter whenever the stylesheet or component builders it's given
  // aren't the same objects (neither has value equality), so a fresh one per build would restyle every block on every
  // focus change or parent rebuild.
  Stylesheet? _stylesheetCache;
  List<ComponentBuilder>? _componentBuildersCache;

  Stylesheet _stylesheet() => _stylesheetCache ??= _createStylesheet();

  Stylesheet _createStylesheet() {
    return defaultStylesheet.copyWith(
      // The default rules cap every block at 640 wide, centered in a wider editor. Text spans the editor instead: the
      // app decides any width limit or centering (e.g. through its padding). Removed from the default rules themselves,
      // since super_editor never lets a later rule override `maxWidth` (its style merge only overrides text styles and
      // padding).
      rules: [
        for (final rule in defaultStylesheet.rules)
          StyleRule(rule.selector, (document, node) => {...rule.styler(document, node)}..remove(Styles.maxWidth)),
      ],
      documentPadding:
          widget.spacing.page ??
          EdgeInsets.fromLTRB(_isDesktopOrWeb ? RawEditor._defaultDesktopLeftPadding : 16, 16, 16, 16),
      addRulesAfter: [
        // Space around each block, by kind (the default stylesheet's per-type block padding reads as inconsistent
        // spacing). It sets no side padding: the default stylesheet gives every block 24 on each side, which only
        // rules that also set left/right would override (a heading's top-only padding would keep it, indenting
        // headings past paragraphs) -- the document padding is the only side inset. Frames and their inner padding:
        // blockStyles.
        widget.spacing.toStyleRule(),
        if (widget.baseTextStyle case final baseTextStyle?)
          StyleRule(BlockSelector.all, (document, node) => {Styles.textStyle: baseTextStyle}),
        StyleRule(
          const BlockSelector('code'),
          (document, node) => {Styles.textStyle: const TextStyle(fontFamily: 'monospace')},
        ),
        ...widget.styleRules,
      ],
      inlineTextStyler: (attributions, existingStyle) {
        var style = defaultInlineTextStyler(attributions, existingStyle);
        if (attributions.contains(codeAttribution)) {
          style = style.copyWith(fontFamily: 'monospace', backgroundColor: const Color(0x1F000000));
        }
        // The default marks super/subscript with OpenType features most fonts lack, so it's invisible; shrink it.
        if (attributions.any((attribution) => attribution is ScriptAttribution)) {
          style = style.copyWith(fontSize: (style.fontSize ?? 18) * 0.7);
        }
        return style;
      },
    );
  }

  Map<String, StoryBlockStyle>? _blockStylesCache;

  List<ComponentBuilder> _componentBuilders(BuildContext context) {
    final blockStyles = widget.blockStyles ?? _defaultBlockStyles(context);
    if (!mapEquals(blockStyles, _blockStylesCache)) {
      _blockStylesCache = blockStyles;
      _componentBuildersCache = null;
    }
    return _componentBuildersCache ??= [
      for (final builder in _createComponentBuilders().map(TextSelectionHighlightComponentBuilder.new))
        _RepaintBoundaryComponentBuilder(
          blockStyles.isEmpty
              ? builder
              : FramedComponentBuilder(builder, document: _controller.document, styles: blockStyles),
        ),
    ];
  }

  static Map<String, StoryBlockStyle> _defaultBlockStyles(BuildContext context) {
    final onSurface = ColorScheme.of(context).onSurface;
    return {
      'blockquote': StoryBlockStyle(
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.04),
          border: Border(left: BorderSide(color: onSurface.withValues(alpha: 0.25), width: 3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      'code': StoryBlockStyle(
        decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.all(12),
      ),
    };
  }

  List<ComponentBuilder> _createComponentBuilders() => [
    if (widget.placeholder case final placeholder?) HintComponentBuilder(placeholder, _placeholderStyle),
    const NoPaddingBlockquoteComponentBuilder(),
    const CompactParagraphComponentBuilder(),
    const CompactListItemComponentBuilder(),
    StoryEmbedComponentBuilder(_controller),
    const ImageComponentBuilder(),
    const HorizontalRuleComponentBuilder(),
    // Wired to the editor even when read-only: checkboxes stay live (unless turned off).
    CompactTaskComponentBuilder(_controller.editor, enabled: widget.checkboxesEnabled),
  ];

  TextStyle _placeholderStyle(BuildContext context) {
    return widget.placeholderStyle ??
        (widget.baseTextStyle ?? const TextStyle()).copyWith(color: Theme.of(context).hintColor);
  }

  // Created once: super_editor re-creates its tap handlers whenever it's given a new list.
  late final _editorTapHandlers = <SuperEditorContentTapDelegateFactory>[
    (context) => StoryLinkTapHandler(context.document, () => widget.onTapLink, composer: context.composer),
  ];

  ContentTapDelegate _readerTapHandler(SuperReaderContext context) =>
      StoryLinkTapHandler(context.document, () => widget.onTapLink);

  /// The caret's (and on mobile the handles' and magnifier's) color: [caretColor], else the theme's cursor color,
  /// else its primary color -- the nearest theme's, so a themed subtree recolors it. Never super_editor's fallback,
  /// `ThemeData.primaryColor`: a dark theme's is near-black.
  Color _caretColor(BuildContext context) =>
      widget.caretColor ?? TextSelectionTheme.of(context).cursorColor ?? ColorScheme.of(context).primary;

  /// Makes the mobile controls in [color], unless they're already in it.
  void _updateControls(Color color) {
    if (_controlsColor == color && _iosControlsController != null) return;
    _controlsColor = color;
    final previous = (_iosControlsController, _androidControlsController, _iosReaderControlsController);
    _iosControlsController = SuperEditorIosControlsController(toolbarBuilder: _buildIosToolbar, handleColor: color);
    _androidControlsController = SuperEditorAndroidControlsController(
      toolbarBuilder: _buildAndroidToolbar,
      controlsColor: color,
    );
    _iosReaderControlsController = SuperReaderIosControlsController(
      handleColor: color,
      toolbarBuilder: _buildIosReaderToolbar,
    );
    // The previous ones are still in this frame's tree.
    if (previous.$1 != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _disposeControls(previous.$1, previous.$2, previous.$3));
    }
  }

  static void _disposeControls(
    SuperEditorIosControlsController? ios,
    SuperEditorAndroidControlsController? android,
    SuperReaderIosControlsController? iosReader,
  ) {
    ios?.dispose();
    android?.dispose();
    iosReader?.dispose();
  }

  SelectionStyles _selectionStyle(BuildContext context) {
    final color =
        widget.selectionColor ??
        TextSelectionTheme.of(context).selectionColor ??
        ColorScheme.of(context).primary.withValues(alpha: 0.4);
    if (_selectionStyleCache?.selectionColor != color) _selectionStyleCache = SelectionStyles(selectionColor: color);
    return _selectionStyleCache!;
  }

  SelectionStyles? _selectionStyleCache;

  /// super_editor's default overlays, with the desktop caret in [_caretColor]. Cached per color: super_editor rebuilds
  /// its layers whenever it's given a new list.
  List<SuperEditorLayerBuilder> _overlayBuilders(BuildContext context) {
    final color = _caretColor(context);
    if (_overlayBuildersColor != color) {
      _overlayBuildersColor = color;
      _overlayBuildersCache = [
        const SuperEditorIosToolbarFocalPointDocumentLayerBuilder(),
        const SuperEditorIosHandlesDocumentLayerBuilder(),
        const SuperEditorAndroidToolbarFocalPointDocumentLayerBuilder(),
        const SuperEditorAndroidHandlesDocumentLayerBuilder(),
        DefaultCaretOverlayBuilder(caretStyle: CaretStyle(width: 2, color: color)),
      ];
    }
    return _overlayBuildersCache!;
  }

  Color? _overlayBuildersColor;
  List<SuperEditorLayerBuilder>? _overlayBuildersCache;

  bool get _ownsScrolling => widget.layout == StoryEditorLayout.scrolling;

  ReaderMenu get _readerMenu => ReaderMenu(
    document: _controller.document,
    composer: _controller.composer,
    extraActions: widget.contextMenuActions,
  );

  Widget _buildIosReaderToolbar(BuildContext context, Key mobileToolbarKey, LeaderLink focalPoint) {
    if (kIsWeb) return const SizedBox.shrink();
    return StoryIosReaderToolbar(
      key: mobileToolbarKey,
      focalPoint: focalPoint,
      menu: _readerMenu,
      controlsController: SuperReaderIosControlsScope.rootOf(context),
    );
  }

  Widget _buildAndroidReaderToolbar(BuildContext context) {
    return StoryAndroidReaderToolbar(
      menu: _readerMenu,
      processTextActions: _androidProcessTextActions,
      selectionRect: _selectionGlobalRect,
    );
  }

  Widget _buildSuperReader(BuildContext context) {
    // super_reader looks up the outermost scope, so its iOS handles take this one's color.
    return SuperReaderIosControlsScope(
      controller: _iosReaderControlsController!,
      child: SuperReader(
        androidHandleColor: _controlsColor,
        androidToolbarBuilder: _buildAndroidReaderToolbar,
        contentTapDelegateFactory: _readerTapHandler,
        editor: _controller.editor,
        focusNode: _controller.focusNode,
        tapRegionGroupId: _controller.tapRegionGroupId,
        documentLayoutKey: _documentLayoutKey,
        scrollController: _ownsScrolling ? _scrollController : widget.scrollController,
        shrinkWrap: !_ownsScrolling,
        componentBuilders: _componentBuilders(context),
        stylesheet: _stylesheet(),
        selectionStyle: _selectionStyle(context),
      ),
    );
  }

  Widget _buildSuperEditor(BuildContext context) {
    final isDesktopOrWeb = _isDesktopOrWeb;
    final keepSelection = isDesktopOrWeb || _controller.isSelectionHeld.value;

    return SuperEditor(
      editor: _controller.editor,
      contentTapDelegateFactories: _editorTapHandlers,
      focusNode: _controller.focusNode,
      autofocus: widget.autofocus,
      scrollController: _ownsScrolling ? _scrollController : widget.scrollController,
      tapRegionGroupId: _controller.tapRegionGroupId,
      documentLayoutKey: _documentLayoutKey,
      inputRole: widget.inputRole,
      shrinkWrap: !_ownsScrolling,
      componentBuilders: _componentBuilders(context),
      keyboardActions: RawEditor._keyboardActions,
      // Mobile drops the selection when the editor loses focus, except while a toolbar holds it (its popup took focus,
      // and its action still needs the selection). Desktop always keeps it: its toolbar popups take focus too.
      selectionPolicies: SuperEditorSelectionPolicies(
        clearSelectionWhenEditorLosesFocus: !keepSelection,
        clearSelectionWhenImeConnectionCloses: !keepSelection,
      ),
      selectionStyle: _selectionStyle(context),
      documentOverlayBuilders: _overlayBuilders(context),
      stylesheet: _stylesheet(),
    );
  }

  /// [document] as laid out for [RawEditor.layout].
  ///
  /// Inside a scroll view, super_editor lays its document out as a sliver of that scroll view (it scrolls it, and
  /// follows the caret with it). The box layout hosts that sliver in a [SliverBox], sized to it. Without a scroll view
  /// around it, super_editor builds a shrink-wrapped box itself.
  Widget _laidOut(BuildContext context, Widget document) {
    if (widget.layout != StoryEditorLayout.box || Scrollable.maybeOf(context) == null) return document;
    return SliverBox(sliver: document);
  }

  @override
  Widget build(BuildContext context) {
    _updateControls(_caretColor(context));
    if (_controller.readOnly) return _buildReadOnly(context);

    final editor = SuperEditorIosControlsScope(
      controller: _iosControlsController!,
      child: SuperEditorAndroidControlsScope(
        controller: _androidControlsController!,
        child: _buildSuperEditor(context),
      ),
    );

    // Reorder and right-click chrome need a box around the editor, which a sliver can't have.
    if (widget.layout == StoryEditorLayout.sliver) return editor;
    final laidOut = _laidOut(context, editor);

    if (_isDesktopOrWeb) {
      final reorderable = ReorderableDocumentOverlay(
        document: _controller.document,
        composer: _controller.composer,
        editor: _controller.editor,
        documentLayoutResolver: _layout,
        child: laidOut,
      );
      final showMenu = widget.desktopContextMenu;
      if (showMenu == null) return reorderable;
      return DesktopContextMenuRegion(
        document: _controller.document,
        composer: _controller.composer,
        editorOps: _editorOps,
        documentLayoutResolver: _layout,
        showMenu: showMenu,
        extraActions: widget.contextMenuActions,
        child: reorderable,
      );
    }

    // Touch: the document alone -- a drag scrolls, a tap places the caret.
    return laidOut;
  }

  /// No reordering; the desktop menu offers Copy and Select All, then the read-only [RawEditor.contextMenuActions].
  Widget _buildReadOnly(BuildContext context) {
    final reader = _buildSuperReader(context);
    if (widget.layout == StoryEditorLayout.sliver) return reader;
    final laidOut = _laidOut(context, reader);

    final showMenu = widget.desktopContextMenu;
    if (!_isDesktopOrWeb || showMenu == null) return laidOut;
    return DesktopContextMenuRegion(
      document: _controller.document,
      composer: _controller.composer,
      editorOps: _editorOps,
      documentLayoutResolver: _layout,
      showMenu: showMenu,
      readOnly: true,
      extraActions: widget.contextMenuActions,
      child: laidOut,
    );
  }
}

/// Each block in a repaint boundary of its own, as a `ListView` gives its items: super_editor's layout has none, so a
/// keystroke repainted every block of the page (the cost growing with its length) instead of the one edited.
class _RepaintBoundaryComponentBuilder implements ComponentBuilder {
  const _RepaintBoundaryComponentBuilder(this.delegate);

  final ComponentBuilder delegate;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    final component = delegate.createComponent(componentContext, componentViewModel);
    // The component (holding the layout's component key) stays inside, so selection and hit testing are unchanged.
    return component == null ? null : RepaintBoundary(child: component);
  }
}
