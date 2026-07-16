import 'package:flutter/material.dart';

import '../models/nodly_dialog_result.dart';
export '../models/nodly_dialog_result.dart';

/// Create / Edit dialog for a Nodly item.
///
/// Title is just **"Create"** or **"Edit"** (not "New Nodly" / "Edit Nodly").
/// In edit mode two calendar-arrow buttons let the user move the item
/// to the previous or next day.
class NodlyDialog extends StatefulWidget {
  final String? initialText;

  const NodlyDialog({super.key, this.initialText});

  bool get isEditMode => initialText != null;

  /// Shows the dialog and returns a [NodlyDialogResult] or null on cancel.
  static Future<NodlyDialogResult?> show({
    required BuildContext context,
    String? initialText,
  }) {
    return showGeneralDialog<NodlyDialogResult?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return NodlyDialog(initialText: initialText);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<NodlyDialog> createState() => _NodlyDialogState();
}

class _NodlyDialogState extends State<NodlyDialog> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_hasText) {
      Navigator.of(context)
          .pop(NodlyDialogResult(text: _controller.text.trim()));
    }
  }

  void _moveDate(int days) {
    Navigator.of(context).pop(NodlyDialogResult(moveDays: days));
  }

  // ── Calendar + arrow icon builder ──────────────────────────────────────

  Widget _buildMoveIcon(bool isPrevious, Color iconColor) {
    return Tooltip(
      message: isPrevious ? 'Move to previous day' : 'Move to next day',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _moveDate(isPrevious ? -1 : 1),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Calendar base
                Center(
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                // Direction arrow overlay
                Positioned(
                  right: isPrevious ? null : -3,
                  left: isPrevious ? -3 : null,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dialogTheme.backgroundColor ??
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPrevious
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isEdit = widget.isEditMode;

    final accentColor = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    return Align(
      alignment: const Alignment(0.0, -0.35),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.dialogTheme.backgroundColor ??
                theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ──────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    isEdit ? 'Edit' : 'Create',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  // Move-to-date buttons (edit mode only)
                  if (isEdit) ...[
                    _buildMoveIcon(true, textColor),
                    const SizedBox(width: 4),
                    _buildMoveIcon(false, textColor),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Text input ─────────────────────────────────────────────
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 16,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter Text',
                  hintStyle: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),

              // ── Action buttons ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _hasText ? _submit : null,
                    child: Opacity(
                      opacity: _hasText ? 1.0 : 0.4,
                      child: Text(
                        isEdit ? 'Done' : 'Create',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
