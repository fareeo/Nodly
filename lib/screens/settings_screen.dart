import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Full-page settings screen with themed sections.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final fontFamily = theme.textTheme.bodyLarge?.fontFamily;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4, right: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Scrollable settings ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── APPEARANCE ─────────────────────────────────────────
                  _sectionTitle('Appearance', fontFamily, textColor),
                  const SizedBox(height: 8),
                  _buildThemeSelector(theme, fontFamily, accentColor, textColor),
                  const SizedBox(height: 20),

                  _sectionTitle('Accent Color', fontFamily, textColor),
                  const SizedBox(height: 8),
                  _buildAccentPicker(accentColor),
                  const SizedBox(height: 24),

                  // ── TYPOGRAPHY ─────────────────────────────────────────
                  _sectionTitle('Typography', fontFamily, textColor),
                  const SizedBox(height: 8),
                  _buildFontPicker(theme, fontFamily, accentColor, textColor),
                  const SizedBox(height: 16),

                  _sectionTitle(
                      'Global Font Size (${(_settings.fontSizeScale * 100).round()}%)',
                      fontFamily,
                      textColor),
                  const SizedBox(height: 4),
                  _buildFontSizeSlider(accentColor),
                  const SizedBox(height: 24),

                  // ── NOTIFICATIONS ──────────────────────────────────────
                  _sectionTitle('Reminders', fontFamily, textColor),
                  const SizedBox(height: 8),
                  _buildNotificationToggle(
                      theme, fontFamily, accentColor, textColor),
                  const SizedBox(height: 12),
                  if (_settings.notificationsEnabled) ...[
                    _sectionTitle('Repeat Period', fontFamily, textColor),
                    const SizedBox(height: 8),
                    _buildPeriodPicker(
                        theme, fontFamily, accentColor, textColor),
                  ],
                  const SizedBox(height: 32),

                  // ── ABOUT ──────────────────────────────────────────────
                  _buildAbout(theme, fontFamily, textColor),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable title / label ─────────────────────────────────────────────

  Widget _sectionTitle(String title, String? font, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: font,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Theme selector ─────────────────────────────────────────────────────

  Widget _buildThemeSelector(
      ThemeData theme, String? font, Color accent, Color textColor) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SettingsService.themeNames.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final name = SettingsService.themeNames[index];
          final isSelected = _settings.themeName == name;

          // Build mini preview from the theme data
          final themeSeed = AppTheme.getThemeSeedColor(name);
          final previewTheme = AppTheme.buildTheme(
            themeName: name,
            brightness: Theme.of(context).brightness,
            accentColor: themeSeed,
            fontFamily: font ?? 'RobotoCondensed',
            fontSizeScale: 1.0,
          );

          return GestureDetector(
            onTap: () => _settings.setThemeName(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: previewTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accent : Colors.transparent,
                  width: isSelected ? 2.5 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mini accent circle + background preview
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: previewTheme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Accent picker ──────────────────────────────────────────────────────

  Widget _buildAccentPicker(Color currentAccent) {
    final presets = SettingsService.accentPresets;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presets.map((color) {
        final isSelected = currentAccent.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => _settings.setAccentColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ── Font picker ────────────────────────────────────────────────────────

  Widget _buildFontPicker(
      ThemeData theme, String? font, Color accent, Color textColor) {
    final fonts = SettingsService.fontFamilies;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fonts.map((fName) {
        final isSelected = _settings.fontFamily == fName;
        final label = fName == 'System' ? 'System' : fName;
        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontFamily: fName == 'System' ? null : fName,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : textColor,
            ),
          ),
          selected: isSelected,
          selectedColor: accent,
          backgroundColor: theme.cardColor,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onSelected: (_) => _settings.setFontFamily(fName),
        );
      }).toList(),
    );
  }

  // ── Font size slider ───────────────────────────────────────────────────

  Widget _buildFontSizeSlider(Color accent) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.2),
        overlayColor: accent.withValues(alpha: 0.1),
      ),
      child: Slider(
        value: _settings.fontSizeScale.clamp(0.8, 1.5),
        min: 0.8,
        max: 1.5,
        divisions: 14,
        onChanged: (value) => _settings.setFontSizeScale(
          (value * 20).round() / 20.0, // snap to 0.05 increments
        ),
      ),
    );
  }

  // ── Notification toggle ────────────────────────────────────────────────

  Widget _buildNotificationToggle(
      ThemeData theme, String? font, Color accent, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Enable Reminders',
            style: TextStyle(
              fontFamily: font,
              fontSize: 15,
              color: textColor,
            ),
          ),
        ),
        Switch(
          value: _settings.notificationsEnabled,
          activeTrackColor: accent,
          onChanged: (value) async {
            await _settings.setNotificationsEnabled(value);
            if (value) {
              await NotificationService().scheduleReminder();
            } else {
              await NotificationService().cancelReminder();
            }
          },
        ),
      ],
    );
  }

  // ── Period picker ──────────────────────────────────────────────────────

  Widget _buildPeriodPicker(
      ThemeData theme, String? font, Color accent, Color textColor) {
    final presets = SettingsService.notificationPresets;
    final currentPeriod = _settings.notificationPeriodMinutes;
    final isCustom = !presets.contains(currentPeriod);

    String formatPeriod(int mins) {
      if (mins < 60) return '${mins}m';
      final h = mins ~/ 60;
      final m = mins % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((mins) {
              final isSelected = currentPeriod == mins && !isCustom;
              return ChoiceChip(
                label: Text(
                  formatPeriod(mins),
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : textColor,
                  ),
                ),
                selected: isSelected,
                selectedColor: accent,
                backgroundColor: theme.cardColor,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;
                    await _settings.setNotificationPeriodMinutes(mins);
                    await NotificationService().scheduleReminder();
                  });
                },
              );
            }),
            ChoiceChip(
              label: Text(
                isCustom ? 'Custom (${formatPeriod(currentPeriod)})' : 'Custom',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                  fontWeight: isCustom ? FontWeight.w600 : FontWeight.w400,
                  color: isCustom ? Colors.white : textColor,
                ),
              ),
              selected: isCustom,
              selectedColor: accent,
              backgroundColor: theme.cardColor,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _showCustomPeriodDialog(font, textColor);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCustomPeriodDialog(String? font, Color textColor) async {
    final controller = TextEditingController(
      text: _settings.notificationPeriodMinutes.toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final accent = theme.colorScheme.primary;
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor ??
              theme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Custom Period (minutes)',
            style: TextStyle(
              fontFamily: font,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(fontFamily: font, color: textColor),
            decoration: InputDecoration(
              hintText: 'e.g. 120 (must be >= 1)',
              hintStyle: TextStyle(
                fontFamily: font,
                color: textColor.withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              },
              child: Text('Cancel',
                  style: TextStyle(fontFamily: font, color: textColor)),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value >= 1) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(value);
                    }
                  });
                }
              },
              child: Text('Set',
                  style: TextStyle(fontFamily: font, color: accent)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null && result >= 1) {
      // Allow dialog exit transition and keyboard closure to complete fully
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _settings.setNotificationPeriodMinutes(result);
        await NotificationService().scheduleReminder();
      });
    }
  }

  // ── About ──────────────────────────────────────────────────────────────

  Widget _buildAbout(ThemeData theme, String? font, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nodly v1.0.0',
            style: TextStyle(
              fontFamily: font,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A daily quick things-to-do app.',
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Made by Fareeo.',
            style: TextStyle(
              fontFamily: font,
              fontSize: 13,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
