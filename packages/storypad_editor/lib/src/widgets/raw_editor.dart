import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart';

import '../controller/story_editor_controller.dart';
import 'android_toolbar.dart';
import 'block_frame.dart';
import 'compact_builders.dart';
import 'context_menu_action.dart';
import 'desktop_context_menu.dart';
import 'free_task_indent.dart';
import 'ios_system_context_menu.dart';
import 'link_tap_handler.dart';
import 'reorderable_document_overlay.dart';
import 'sliver_box.dart';
import 'story_embed_component.dart';
import 'title_hint.dart';

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
/// - Touch: no reordering or tap-outside handling of its own: move blocks with `actions.moveSelectedBlocks` (e.g.
///   toolbar buttons), and the keyboard's own key hides it.
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
    this.padding,
    this.styleRules = const [],
    this.scrollController,
    this.autofocus = false,
    this.inputRole,
    this.layout = StoryEditorLayout.scrolling,
    this.desktopContextMenu = showDefaultDesktopContextMenu,
    this.onTapLink,
    this.caretColor,
    this.selectionColor,
    this.placeholder,
    this.placeholderStyle,
    this.titlePlaceholder,
    this.checkboxesEnabled = true,
    this.contextMenuActions = const [],
    this.blockStyles,
  });

  final StoryEditorController controller;

  /// Merged into every block's text style -- e.g. a font. Per-block styling (heading sizes, …) is kept.
  final TextStyle? baseTextStyle;

  /// The document's padding, used exactly as given: the editor adds none of its own, and its text spans the full width
  /// inside it (no maximum width, no centering -- any of that is the app's choice). Defaults to 16 all round (18 on the
  /// left on desktop, room for the drag handle).
  final EdgeInsets? padding;

  /// Extra stylesheet rules, applied after the editor's own -- e.g. `StyleRule(BlockSelector('media'), …)` to style
  /// an embed type, or a blockquote border.
  final List<StyleRule> styleRules;

  final ScrollController? scrollController;

  final bool autofocus;

  /// Give each editor a distinct value when several are on screen at once (their IME connections are told apart by
  /// it).
  final String? inputRole;

  /// How the editor sizes and scrolls. See [StoryEditorLayout].
  final StoryEditorLayout layout;

  /// Shows the desktop right-click menu. Defaults to a Flutter-painted menu; pass a native one (see the example's
  /// macOS menu), or `null` for none.
  final DesktopContextMenuHandler? desktopContextMenu;

  /// Called when a link is tapped -- in read-only mode, or with Cmd/Ctrl held while editing (a plain tap places the
  /// caret). `null` opens the link with the platform's URL launcher.
  final LinkTapCallback? onTapLink;

  /// The desktop caret. Defaults to the theme's cursor color (`TextSelectionTheme`), else its primary color. Mobile
  /// carets and handles follow the theme's primary color.
  final Color? caretColor;

  /// The selection highlight. Defaults to the theme's selection color (`TextSelectionTheme`), else its primary color
  /// at 40% opacity.
  final Color? selectionColor;

  /// Shown while the document is a single empty paragraph.
  final String? placeholder;

  /// The [placeholder]'s style. Defaults to [baseTextStyle] in the theme's hint color.
  final TextStyle? placeholderStyle;

  /// Shown in an empty heading that's the first block -- an empty page title (see `StoryCodec.pageTitleOf`), e.g.
  /// the one a new page starts with -- in the heading's style and [placeholderStyle]'s color (default: the theme's
  /// hint color). Takes precedence over [placeholder] when the document is just that heading.
  final String? titlePlaceholder;

  /// Whether task checkboxes toggle -- also while read-only, where it's the only edit (reported like any other).
  /// Turn off for a view whose changes wouldn't be kept.
  final bool checkboxesEnabled;

  /// Extra items for the selection menus (Android toolbar, iOS system menu, desktop right-click menu), after the
  /// platform's own. See [StoryContextMenuAction] for where each shows.
  final List<StoryContextMenuAction> contextMenuActions;

  /// Frames per block type (`blockquote`, `code`, an embed's type, …): a background/border and the padding between it
  /// and the content. Defaults to a tinted quote with a left bar and a tinted code box, from the theme. Space *between*
  /// blocks is `Styles.padding` in [styleRules] (4px by default).
  final Map<String, StoryBlockStyle>? blockStyles;

  @override
  State<RawEditor> createState() => _RawEditorState();
}

/// How a [RawEditor] sizes and scrolls.
enum StoryEditorLayout {
  /// Fills its box and scrolls itself.
  scrolling,

  /// A box sized to its content, placed inside another scroll view -- e.g. in a `Column` in a
  /// `SingleChildScrollView`, below a title field. That scroll view scrolls the editor: dragging over the text scrolls
  /// it, and it follows the caret. (Without any scroll view around it, the editor still sizes to its content.)
  box,

  /// A sliver sized to its content, for placing several editors in one `CustomScrollView`. Has no reorder, right-click
  /// or tap-outside chrome (they need a box around the editor).
  sliver,
}

/// The document's left inset on desktop/web: just wide enough for [ReorderableDocumentOverlay]'s drag handle.
const _reorderGutterWidth = 18.0;

/// The IME keyboard actions (super_editor's default input source), with free task indent swapped in.
final _keyboardActions = List<SuperEditorKeyboardAction>.unmodifiable([
  for (final action in defaultImeKeyboardActions)
    if (action == tabToIndentTask)
      tabToIndentTaskFreely
    else if (action == shiftTabToUnIndentTask)
      shiftTabToUnIndentTaskFreely
    else
      action,
]);

class _RawEditorState extends State<RawEditor> {
  final _documentLayoutKey = GlobalKey();
  late CommonEditorOperations _editorOps;
  late final SuperEditorIosControlsController _iosControlsController;
  late final SuperEditorAndroidControlsController _androidControlsController;

  /// The scroll controller both the editor and the reader use, so the offset can be carried across a read-only switch.
  ScrollController? _ownScrollController;
  ScrollController get _scrollController => widget.scrollController ?? (_ownScrollController ??= ScrollController());

  /// Android "Process Text" actions, queried once up front (like `EditableText` does), well before any toolbar needs
  /// them.
  List<ProcessTextAction> _androidProcessTextActions = const [];

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
    _iosControlsController = SuperEditorIosControlsController(toolbarBuilder: _buildIosToolbar);
    _androidControlsController = SuperEditorAndroidControlsController(toolbarBuilder: _buildAndroidToolbar);
    _attach(_controller);
    _initAndroidProcessTextActions();
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
        oldWidget.titlePlaceholder != widget.titlePlaceholder ||
        oldWidget.baseTextStyle != widget.baseTextStyle ||
        oldWidget.checkboxesEnabled != widget.checkboxesEnabled) {
      _componentBuildersCache = null;
    }
    if (oldWidget.baseTextStyle != widget.baseTextStyle ||
        oldWidget.padding != widget.padding ||
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
    _iosControlsController.dispose();
    _androidControlsController.dispose();
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
  }

  void _detach(StoryEditorController controller) {
    controller.isSelectionHeld.removeListener(_rebuild);
    controller.readOnlyListenable.removeListener(_onReadOnlyChanged);
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

  Future<void> _initAndroidProcessTextActions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final actions = await DefaultProcessTextService().queryTextActions();
    if (mounted) setState(() => _androidProcessTextActions = actions);
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
      documentPadding: widget.padding ?? EdgeInsets.fromLTRB(_isDesktopOrWeb ? _reorderGutterWidth : 16, 16, 16, 16),
      addRulesAfter: [
        // The same small gap around every block (the default stylesheet's per-type block padding reads as
        // inconsistent spacing), with the base text style merged in. No side padding: the default stylesheet gives
        // every block 24 on each side, which only rules that also set left/right would override (a heading's top-only
        // padding would keep it, indenting headings past paragraphs) -- the document padding is the only side inset.
        // Frames and their inner padding: blockStyles.
        StyleRule(
          BlockSelector.all,
          (document, node) => {
            Styles.padding: const CascadingPadding.symmetric(vertical: 2, horizontal: 0),
            if (widget.baseTextStyle != null) Styles.textStyle: widget.baseTextStyle!,
          },
        ),
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
      for (final builder in _createComponentBuilders())
        blockStyles.isEmpty
            ? builder
            : FramedComponentBuilder(builder, document: _controller.document, styles: blockStyles),
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
    if (widget.titlePlaceholder case final titlePlaceholder?)
      TitleHintComponentBuilder(titlePlaceholder, (context) => widget.placeholderStyle?.color),
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

  Color _caretColor(BuildContext context) =>
      widget.caretColor ?? TextSelectionTheme.of(context).cursorColor ?? ColorScheme.of(context).primary;

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

  Widget _buildSuperReader(BuildContext context) {
    return SuperReader(
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
      keyboardActions: _keyboardActions,
      // Mobile drops the selection when the editor loses focus (so tap-outside unfocuses and enables reordering),
      // except while a toolbar holds it (its popup took focus, and its action still needs the selection). Desktop
      // always keeps it: its toolbar popups take focus too.
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
    if (_controller.readOnly) return _buildReadOnly(context);

    final editor = SuperEditorIosControlsScope(
      controller: _iosControlsController,
      child: SuperEditorAndroidControlsScope(controller: _androidControlsController, child: _buildSuperEditor(context)),
    );

    // Reorder, right-click and tap-outside chrome need a box around the editor, which a sliver can't have.
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

  /// No reordering or tap-outside handling; the desktop menu offers only Copy and Select All.
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
