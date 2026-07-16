import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// A swipeable task card for the Nodly to-do app.
///
/// • Swipe **right** → mark **Done** (green).
/// • Swipe **left**  → **Delete** (red).
/// • Long-press → glow pulse + haptic → edit.
class NodlyCard extends StatefulWidget {
  const NodlyCard({
    super.key,
    required this.id,
    required this.text,
    required this.onDone,
    required this.onDelete,
    required this.onEdit,
    this.animation,
  });

  final String id;
  final String text;
  final VoidCallback onDone;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Animation<double>? animation;

  @override
  State<NodlyCard> createState() => _NodlyCardState();
}

class _NodlyCardState extends State<NodlyCard>
    with TickerProviderStateMixin {
  // ── Swipe state ────────────────────────────────────────────────────────
  static const double _gap = 8.0;
  static const double _dismissThreshold = 0.35;
  static const double _iconRevealWidth = 64.0; // min bg width before icon shows

  late AnimationController _slideController;
  double _dragExtent = 0;
  bool _isDismissing = false;
  int _swipeDirection = 0; // 1 = right, -1 = left

  // ── Long-press glow state ──────────────────────────────────────────────
  bool _pressing = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.reverse();
      } else if (status == AnimationStatus.dismissed && _pressing) {
        _glowController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ── Drag handlers ──────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    _dragExtent = 0;
    _swipeDirection = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_swipeDirection == 0 && _dragExtent != 0) {
        _swipeDirection = _dragExtent > 0 ? 1 : -1;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDismissing) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final ratio = _dragExtent.abs() / screenWidth;

    if (ratio >= _dismissThreshold ||
        details.primaryVelocity!.abs() > 700) {
      _isDismissing = true;
      final targetExtent =
          screenWidth * (_dragExtent > 0 ? 1.0 : -1.0);
      final isRightSwipe = _dragExtent > 0;

      final startExtent = _dragExtent;
      _slideController.reset();
      _slideController.addListener(_animateDismiss(startExtent, targetExtent));
      _slideController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (isRightSwipe) {
            widget.onDelete();
          } else {
            widget.onDone();
          }
        }
      });
      _slideController.forward();
    } else {
      // Snap back
      final startExtent = _dragExtent;
      _slideController.reset();
      _slideController.addListener(_animateSnapBack(startExtent));
      _slideController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _swipeDirection = 0;
        }
      });
      _slideController.forward();
    }
  }

  VoidCallback _animateDismiss(double start, double target) {
    return () {
      if (mounted) {
        setState(() {
          _dragExtent = start +
              (target - start) *
                  Curves.easeOut.transform(_slideController.value);
        });
      }
    };
  }

  VoidCallback _animateSnapBack(double start) {
    return () {
      if (mounted) {
        setState(() {
          _dragExtent =
              start * (1.0 - Curves.easeOut.transform(_slideController.value));
        });
      }
    };
  }

  // ── Long-press handlers ────────────────────────────────────────────────

  void _onLongPressStart(LongPressStartDetails _) {
    HapticFeedback.mediumImpact();
    setState(() => _pressing = true);
    _glowController.forward();
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    setState(() => _pressing = false);
    _glowController.stop();
    _glowController.reset();
    widget.onEdit();
  }

  void _onLongPressCancel() {
    setState(() => _pressing = false);
    _glowController.stop();
    _glowController.reset();
  }

  // ── Background builders ────────────────────────────────────────────────

  Widget _buildBackground(double absOffset, bool isRightSwipe) {
    final bgWidth = math.max(0.0, absOffset - _gap);
    if (bgWidth <= 0) return const SizedBox.shrink();

    final bgColor = isRightSwipe
        ? const Color(0xFFD32F2F)
        : Theme.of(context).colorScheme.primary;
    final icon = isRightSwipe ? Icons.delete_rounded : Icons.check_circle;
    final label = isRightSwipe ? 'Delete' : 'Done';

    // Icon only reveals after background reaches a minimum width
    final iconOpacity = ((bgWidth - _iconRevealWidth) / 20.0).clamp(0.0, 1.0);

    return Container(
      width: bgWidth,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: iconOpacity,
        child: bgWidth > _iconRevealWidth + 10
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // ── Card builder ───────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final accentColor = theme.colorScheme.primary;
    final fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    final textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: theme.textTheme.bodyLarge?.fontSize,
      color: theme.textTheme.bodyLarge?.color,
    );

    final absOffset = _dragExtent.abs();
    final isRightSwipe = _dragExtent >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Stack(
        children: [
          // Swipe background
          if (absOffset > 2)
            Positioned(
              left: isRightSwipe ? 0 : null,
              right: isRightSwipe ? null : 0,
              top: 0,
              bottom: 0,
              child: _buildBackground(absOffset, isRightSwipe),
            ),

          // Main card
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onLongPressStart: _onLongPressStart,
              onLongPressEnd: _onLongPressEnd,
              onLongPressCancel: _onLongPressCancel,
              child: ListenableBuilder(
                listenable: _glowAnimation,
                builder: (context, child) {
                  final glowValue = _glowAnimation.value;
                  return AnimatedScale(
                    scale: _pressing ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _pressing
                            ? [
                                BoxShadow(
                                  color: accentColor
                                      .withValues(alpha: 0.3 * glowValue),
                                  blurRadius: 12 + (8 * glowValue),
                                  spreadRadius: 1 + (3 * glowValue),
                                ),
                              ]
                            : null,
                        border: _pressing
                            ? Border.all(
                                color: accentColor
                                    .withValues(alpha: 0.4 * glowValue),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Text(
                        widget.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    final animation = widget.animation;
    if (animation == null) return card;

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: animation,
        child: card,
      ),
    );
  }
}
