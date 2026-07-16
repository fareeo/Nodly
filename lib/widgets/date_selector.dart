import 'package:flutter/material.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onSettingsTap;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onSettingsTap,
  });

  List<DateTime> _buildWeekDays() {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (i) => today.add(Duration(days: i - 3)));
  }

  double _opacityForIndex(int index) {
    const opacities = [0.4, 0.6, 0.8, 1.0, 0.8, 0.6, 0.4];
    return opacities[index];
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildWeekDays();
    final today = DateUtils.dateOnly(DateTime.now());
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);
    final fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top bar: Nodly | Month | Settings gear (top right) ─────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top left: Nodly title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nodly',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              // Center: Month name
              Center(
                child: Text(
                  _monthName(today.month),
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              // Top right: Settings gear icon
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.settings_rounded,
                    color: textColor.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  onPressed: onSettingsTap,
                  tooltip: 'Settings',
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Date row ─────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final day = days[index];
            final isToday = day == today;
            final isSelected = day == DateUtils.dateOnly(selectedDate);
            final opacity = _opacityForIndex(index);

            return Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () => onDateSelected(day),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: isToday ? 22 : 18,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? accentColor : textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          height: 3,
                          width: 20,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
