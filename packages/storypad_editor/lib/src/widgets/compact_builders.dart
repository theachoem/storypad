import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// The width reserved for a bullet, numeral, or checkbox before the text of
/// a list item/task starts, per indent level — shared across all three so
/// switching (or mixing) list types keeps the text flush at the same x.
///
/// Stock SuperEditor reserves `(fontSize * 0.6) * 4` per level for bullets
/// and numerals (~43px at this app's font size, with the marker
/// right-aligned inside it, so most of that width is just blank space
/// before the marker) and reserves nothing for checkboxes at indent 0 but
/// then wraps the checkbox in its own fixed padding plus Flutter's oversized
/// Material tap target — three different, uncoordinated amounts. This is
/// the one shared number [CompactListItemComponentBuilder] and
/// [CompactTaskComponentBuilder] both build around instead.
const markerColumnWidth = 24.0;

/// The extra width added per indent level beyond the first, for both list
/// items and tasks.
///
/// Deliberately smaller than [markerColumnWidth]: using the full marker
/// column width per level (as SuperEditor's stock formula effectively does,
/// scaled up) makes each nested level jump by as much horizontal space as
/// the *entire* first-level marker column, which reads as an oversized step
/// once markers are already this compact.
const _indentStepWidth = 16.0;

/// Renders bullet/numbered list items with a [markerColumnWidth]-based
/// indent instead of SuperEditor's much wider stock formula.
///
/// This reuses the stock [UnorderedListItemComponent]/[OrderedListItemComponent]
/// widgets as-is (unlike blockquote's fix, no fork of their internals is
/// needed) — they already accept an `indentCalculator`, the stock
/// [ListItemComponentBuilder] just never varies it from its own default.
class CompactListItemComponentBuilder implements ComponentBuilder {
  const CompactListItemComponentBuilder();

  static const _delegate = ListItemComponentBuilder();

  static double _indentCalculator(TextStyle textStyle, int indent) => markerColumnWidth + _indentStepWidth * indent;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      _delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is UnorderedListItemComponentViewModel) {
      return UnorderedListItemComponent(
        componentKey: componentContext.componentKey,
        text: componentViewModel.text,
        styleBuilder: componentViewModel.textStyleBuilder,
        indent: componentViewModel.indent,
        indentCalculator: _indentCalculator,
        dotStyle: componentViewModel.dotStyle,
        textSelection: componentViewModel.selection,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    }

    if (componentViewModel is OrderedListItemComponentViewModel) {
      return OrderedListItemComponent(
        componentKey: componentContext.componentKey,
        indent: componentViewModel.indent,
        indentCalculator: _indentCalculator,
        listIndex: componentViewModel.ordinalValue!,
        text: componentViewModel.text,
        textDirection: componentViewModel.textDirection,
        textAlignment: componentViewModel.textAlignment,
        styleBuilder: componentViewModel.textStyleBuilder,
        numeralStyle: componentViewModel.numeralStyle,
        textSelection: componentViewModel.selection,
        selectionColor: componentViewModel.selectionColor,
        highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
        underlines: componentViewModel.createUnderlines(),
        inlineWidgetBuilders: componentViewModel.inlineWidgetBuilders,
      );
    }

    return null;
  }
}

/// Renders tasks with a [markerColumnWidth]-based indent and a checkbox
/// shrunk to fit that same column, instead of SuperEditor's stock
/// `Padding(left: 16, right: 4)` plus a full-size Material [Checkbox] (whose
/// own default tap target alone is roughly 40-48px).
///
/// The indent math needs a fork of [TaskComponent] itself, unlike list
/// items — the checkbox's padding is a literal in its `build()`, not a
/// configurable field, so there's no way to shrink it by just swapping in a
/// different `indentCalculator`.
///
/// [_CompactTaskComponent] computes its own indent inline (a local constant
/// formula) rather than reading `TaskComponentViewModel.indentCalculator` —
/// every styling/selection pass in SuperEditor's pipeline calls
/// `viewModel.copy()` to produce the next frame's view model, and
/// `TaskComponentViewModel.copy()`/`internalCopy()` never carries a custom
/// `indentCalculator` over to the copy, silently resetting it to the stock
/// formula on the very next render. That regression was invisible at indent
/// 0 (the stock formula also evaluates to 0 there), which is why it only
/// showed up as misaligned second-level-and-deeper tasks.
class CompactTaskComponentBuilder implements ComponentBuilder {
  CompactTaskComponentBuilder(this._editor);

  final Editor _editor;
  late final TaskComponentBuilder _delegate = TaskComponentBuilder(_editor);

  @override
  TaskComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      _delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! TaskComponentViewModel) {
      return null;
    }
    return _CompactTaskComponent(key: componentContext.componentKey, viewModel: componentViewModel);
  }
}

class _CompactTaskComponent extends StatefulWidget {
  const _CompactTaskComponent({super.key, required this.viewModel});

  final TaskComponentViewModel viewModel;

  @override
  State<_CompactTaskComponent> createState() => _CompactTaskComponentState();
}

class _CompactTaskComponentState extends State<_CompactTaskComponent>
    with ProxyDocumentComponent<_CompactTaskComponent>, ProxyTextComposable {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable => childDocumentComponentKey.currentState as TextComposable;

  TextStyle _computeStyles(Set<Attribution> attributions) {
    final style = widget.viewModel.textStyleBuilder(attributions);
    return widget.viewModel.isComplete
        ? style.copyWith(
            decoration: style.decoration == null
                ? TextDecoration.lineThrough
                : TextDecoration.combine([TextDecoration.lineThrough, style.decoration!]),
          )
        : style;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.viewModel.textStyleBuilder(const {});
    // Matches the same line-height trick UnorderedListItemComponent/
    // OrderedListItemComponent use for their own marker: without it, the Row's
    // `crossAxisAlignment: start` pins the checkbox to the very top of the
    // row, which only looked right by coincidence when the checkbox was
    // still Material's full, oversized size — now that it's shrunk to fit
    // markerColumnWidth, it needs to be centered against the text's *first
    // line* specifically (not the whole, possibly-wrapped task), not the top.
    final lineHeight = MediaQuery.textScalerOf(context).scale((textStyle.fontSize ?? 16) * (textStyle.height ?? 1.25));

    return Directionality(
      textDirection: widget.viewModel.textDirection,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Computed locally instead of via `widget.viewModel.indentCalculator`
          // — see the class doc comment on why that field can't be trusted to
          // survive this view model's `copy()`.
          SizedBox(width: _indentStepWidth * widget.viewModel.indent),
          SizedBox(
            width: markerColumnWidth,
            height: lineHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Checkbox(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: widget.viewModel.isComplete,
                onChanged: widget.viewModel.setComplete != null
                    ? (newValue) => widget.viewModel.setComplete!(newValue!)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: TextComponent(
              key: _textKey,
              text: widget.viewModel.text,
              textDirection: widget.viewModel.textDirection,
              textAlign: widget.viewModel.textAlignment,
              textStyleBuilder: _computeStyles,
              inlineWidgetBuilders: widget.viewModel.inlineWidgetBuilders,
              textSelection: widget.viewModel.selection,
              selectionColor: widget.viewModel.selectionColor,
              highlightWhenEmpty: widget.viewModel.highlightWhenEmpty,
              underlines: widget.viewModel.createUnderlines(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders paragraphs (which, per SuperEditor's model, also covers
/// headings, blockquotes, and code blocks — they're all `ParagraphNode`
/// with a different `blockType` metadata) with the same [_indentStepWidth]
/// step used above, instead of SuperEditor's much wider stock formula
/// (`(fontSize * 0.6) * 4` per level, the same oversized default list items
/// and tasks used before their own compact builders).
///
/// Unlike [CompactTaskComponentBuilder], this only needs to override
/// [createViewModel] — `ParagraphComponentViewModel.internalCopy` (unlike
/// `TaskComponentViewModel`'s) already carries `indentCalculator` over on
/// every `copy()`, so there's no need to fork [ParagraphComponent] itself
/// just to keep the override from being silently reset.
class CompactParagraphComponentBuilder implements ComponentBuilder {
  const CompactParagraphComponentBuilder();

  static const _delegate = ParagraphComponentBuilder();

  static double _indentCalculator(TextStyle textStyle, int indent) => _indentStepWidth * indent;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    final viewModel = _delegate.createViewModel(document, node);
    if (viewModel is ParagraphComponentViewModel) {
      viewModel.indentCalculator = _indentCalculator;
    }
    return viewModel;
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) => _delegate.createComponent(componentContext, componentViewModel);
}

/// Renders blockquotes without [BlockquoteComponent]'s built-in
/// `EdgeInsets.symmetric(horizontal: 16, vertical: 16)` container padding.
///
/// That padding is a literal inside the stock widget's `build()`, not read
/// from the stylesheet's `Styles.padding` the way every other block's
/// spacing is — so it survives even after [RawEditor]'s stylesheet zeroes
/// every block's padding, leaving the blockquote both visibly inset compared
/// to its now-flush neighbors, and out of step with
/// `ReorderableDocumentOverlay`'s drag handle (which aligns to the node's
/// rendered left edge, i.e. this padding's outer edge, not the text inside
/// it).
///
/// This is a near-identical copy of `BlockquoteComponentBuilder` — same view
/// model, same layout (an indent-spacer + the text) — with that one literal
/// dropped. Swap it in for the stock builder via `SuperEditor.componentBuilders`.
class NoPaddingBlockquoteComponentBuilder implements ComponentBuilder {
  const NoPaddingBlockquoteComponentBuilder();

  static const _delegate = BlockquoteComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      _delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! BlockquoteComponentViewModel) {
      return null;
    }

    return _NoPaddingBlockquoteComponent(
      textKey: componentContext.componentKey,
      text: componentViewModel.text,
      styleBuilder: componentViewModel.textStyleBuilder,
      indent: componentViewModel.indent,
      indentCalculator: componentViewModel.indentCalculator,
      backgroundColor: componentViewModel.backgroundColor,
      borderRadius: componentViewModel.borderRadius,
      textSelection: componentViewModel.selection,
      selectionColor: componentViewModel.selectionColor,
      highlightWhenEmpty: componentViewModel.highlightWhenEmpty,
      underlines: componentViewModel.createUnderlines(),
    );
  }
}

class _NoPaddingBlockquoteComponent extends StatelessWidget {
  const _NoPaddingBlockquoteComponent({
    required this.textKey,
    required this.text,
    required this.styleBuilder,
    this.textSelection,
    this.indent = 0,
    this.indentCalculator = defaultParagraphIndentCalculator,
    this.selectionColor = Colors.lightBlueAccent,
    required this.backgroundColor,
    required this.borderRadius,
    this.highlightWhenEmpty = false,
    this.underlines = const [],
  });

  final GlobalKey textKey;
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final TextSelection? textSelection;
  final int indent;
  final TextBlockIndentCalculator indentCalculator;
  final Color selectionColor;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final bool highlightWhenEmpty;
  final List<Underlines> underlines;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: borderRadius, color: backgroundColor),
        child: Row(
          children: [
            // Indent spacing on left.
            SizedBox(width: indentCalculator(styleBuilder({}), indent)),
            // The actual paragraph UI.
            Expanded(
              child: TextComponent(
                key: textKey,
                text: text,
                textStyleBuilder: styleBuilder,
                textSelection: textSelection,
                selectionColor: selectionColor,
                highlightWhenEmpty: highlightWhenEmpty,
                underlines: underlines,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
