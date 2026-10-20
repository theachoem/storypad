/// How far list items, tasks and paragraphs indent, and the marker column before a list item's or task's text: one set
/// of numbers for all of them, so switching (or mixing) block types keeps text lined up.
class CompactIndent {
  const CompactIndent._();

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
  static const markerColumnWidth = 24.0;

  /// The space between a task's checkbox and its text. Taken from inside [markerColumnWidth] (the checkbox moves left),
  /// so task text stays aligned with list item text.
  static const checkboxTextGap = 6.0;

  /// The extra width added per indent level beyond the first, for both list
  /// items and tasks.
  ///
  /// Deliberately smaller than [markerColumnWidth]: using the full marker
  /// column width per level (as SuperEditor's stock formula effectively does,
  /// scaled up) makes each nested level jump by as much horizontal space as
  /// the *entire* first-level marker column, which reads as an oversized step
  /// once markers are already this compact.
  static const indentStepWidth = 16.0;
}
