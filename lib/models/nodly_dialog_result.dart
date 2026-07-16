/// Result returned from [NodlyDialog].
///
/// Either carries edited text or a move-to-date action (days offset).
class NodlyDialogResult {
  /// Edited/created text. Null when the result is a move action.
  final String? text;

  /// Number of days to move the item: -1 = previous day, +1 = next day.
  /// Null when the result is a text edit/create.
  final int? moveDays;

  const NodlyDialogResult({this.text, this.moveDays});

  bool get isMove => moveDays != null;
  bool get isTextEdit => text != null;
}
