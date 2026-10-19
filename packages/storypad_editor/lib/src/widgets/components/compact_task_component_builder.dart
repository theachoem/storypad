import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../document/text_alignment.dart';
import 'compact_indent.dart';

/// Renders tasks with a [CompactIndent.markerColumnWidth]-based indent and a checkbox
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
  CompactTaskComponentBuilder(this._editor, {this.enabled = true});

  final Editor _editor;

  /// Whether the checkboxes toggle.
  final bool enabled;
  late final TaskComponentBuilder _delegate = TaskComponentBuilder(_editor);

  /// Stock tasks ignore the node's `textAlign`; a Quill story can align any line.
  @override
  TaskComponentViewModel? createViewModel(Document document, DocumentNode node) {
    final viewModel = _delegate.createViewModel(document, node);
    if (viewModel == null) return null;
    final align = TextAlignment.of(node);
    if (align != null) viewModel.textAlignment = align;
    if (!enabled) viewModel.setComplete = null;
    return viewModel;
  }

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
    // CompactIndent.markerColumnWidth, it needs to be centered against the text's *first
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
          SizedBox(width: CompactIndent.indentStepWidth * widget.viewModel.indent),
          SizedBox(
            width: CompactIndent.markerColumnWidth,
            height: lineHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: CompactIndent.checkboxTextGap),
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
