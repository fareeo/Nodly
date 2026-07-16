import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/nodly_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/date_selector.dart';
import '../widgets/nodly_card.dart';
import '../widgets/nodly_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const _quickAddChannel = MethodChannel('com.nodly.nodly/quick_add');
  late DateTime _selectedDate;
  List<NodlyItem> _items = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  bool _showTopFade = false;
  bool _showBottomFade = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _scrollController.addListener(_onScroll);
    _loadItems();

    _quickAddChannel.setMethodCallHandler((call) async {
      if (call.method == 'triggerQuickAdd') {
        _handleQuickAdd();
      }
    });
    _checkInitialQuickAdd();
  }

  Future<void> _checkInitialQuickAdd() async {
    try {
      final shouldAdd = await _quickAddChannel.invokeMethod<bool>('checkQuickAdd');
      if (shouldAdd == true && mounted) {
        _handleQuickAdd();
      }
    } catch (_) {}
  }

  void _handleQuickAdd() {
    final now = DateTime.now();
    if (!DateUtils.isSameDay(_selectedDate, now)) {
      setState(() {
        _selectedDate = now;
      });
      _loadItems();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _createItem();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTop = _scrollController.offset > 10;
    final showBottom = _scrollController.position.maxScrollExtent > 0 &&
        _scrollController.offset <
            _scrollController.position.maxScrollExtent - 10;

    if (showTop != _showTopFade || showBottom != _showBottomFade) {
      setState(() {
        _showTopFade = showTop;
        _showBottomFade = showBottom;
      });
    }
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await StorageService.loadItems(_dateKey);
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _onScroll();
      }
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadItems();
  }

  // ── Create ─────────────────────────────────────────────────────────────

  Future<void> _createItem() async {
    final result = await NodlyDialog.show(context: context);
    if (result != null && result.isTextEdit && result.text!.isNotEmpty) {
      final item = NodlyItem(
        id: const Uuid().v4(),
        text: result.text!,
        dateKey: _dateKey,
        createdAt: DateTime.now(),
      );
      await StorageService.addItem(item);
      setState(() {
        _items.add(item);
      });
      _listKey.currentState?.insertItem(
        _items.length - 1,
        duration: const Duration(milliseconds: 350),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _onScroll();
      });
      // Update notification content
      NotificationService().scheduleReminder();
    }
  }

  // ── Done (swipe right) ─────────────────────────────────────────────────

  Future<void> _markDoneById(String itemId) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final removedItem = _items[index];
    setState(() => _items.removeAt(index));

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedCard(animation),
      duration: const Duration(milliseconds: 400),
    );

    await StorageService.removeItem(_dateKey, removedItem.id);
    if (!mounted) return;

    _showActionSnackBar(
      icon: Icons.check_circle_rounded,
      label: 'Done!',
      isDelete: false,
      onUndo: () => _undoRemove(index, removedItem),
    );
    NotificationService().scheduleReminder();
  }

  // ── Delete (swipe left) ────────────────────────────────────────────────

  Future<void> _deleteItemById(String itemId) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final removedItem = _items[index];
    setState(() => _items.removeAt(index));

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedCard(animation),
      duration: const Duration(milliseconds: 400),
    );

    await StorageService.removeItem(_dateKey, removedItem.id);
    if (!mounted) return;

    _showActionSnackBar(
      icon: Icons.delete_rounded,
      label: 'Deleted',
      isDelete: true,
      onUndo: () => _undoRemove(index, removedItem),
    );
    NotificationService().scheduleReminder();
  }

  // ── Undo helper ────────────────────────────────────────────────────────

  Future<void> _undoRemove(int originalIndex, NodlyItem item) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final insertAt = originalIndex.clamp(0, _items.length);
    setState(() => _items.insert(insertAt, item));
    _listKey.currentState?.insertItem(
      insertAt,
      duration: const Duration(milliseconds: 350),
    );
    await StorageService.addItem(item);
    await StorageService.saveItems(_dateKey, _items);
    NotificationService().scheduleReminder();
  }

  void _showActionSnackBar({
    required IconData icon,
    required String label,
    required bool isDelete,
    required VoidCallback onUndo,
  }) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final deleteColor = const Color(0xFFD32F2F);
    final actionColor = isDelete ? deleteColor : accentColor;
    final fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.cardColor,
        content: Row(
          children: [
            Icon(icon, color: actionColor, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onUndo,
              child: Text(
                'Undo',
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: actionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRemovedCard(Animation<double> animation) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: const SizedBox(height: 0),
    );
  }

  // ── Edit ────────────────────────────────────────────────────────────────

  Future<void> _editItemById(String itemId) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _items[index];
    final result = await NodlyDialog.show(
      context: context,
      initialText: item.text,
    );

    if (result == null) return;

    if (result.isMove) {
      // Move to another date
      final targetDate =
          _selectedDate.add(Duration(days: result.moveDays!));
      final targetKey = DateFormat('yyyy-MM-dd').format(targetDate);

      // Remove from current list visually
      setState(() => _items.removeAt(index));
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildRemovedCard(animation),
        duration: const Duration(milliseconds: 400),
      );

      await StorageService.moveItem(item, _dateKey, targetKey);
      if (!mounted) return;

      final theme = Theme.of(context);
      final fontFamily = theme.textTheme.bodyLarge?.fontFamily;
      final accentColor = theme.colorScheme.primary;
      final dayName = result.moveDays! > 0 ? 'tomorrow' : 'yesterday';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.cardColor,
          content: Row(
            children: [
              Icon(Icons.event_rounded, color: accentColor, size: 22),
              const SizedBox(width: 12),
              Text(
                'Moved to $dayName',
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.down,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      NotificationService().scheduleReminder();
    } else if (result.isTextEdit && result.text!.isNotEmpty) {
      setState(() => _items[index].text = result.text!);
      await StorageService.updateItem(_items[index]);
      NotificationService().scheduleReminder();
    }
  }

  // ── Card builder ───────────────────────────────────────────────────────

  Widget _buildCard(
      BuildContext context, int index, Animation<double> animation) {
    if (index >= _items.length) return const SizedBox.shrink();
    final item = _items[index];
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: animation,
        child: NodlyCard(
          id: item.id,
          text: item.text,
          onDone: () => _markDoneById(item.id),
          onDelete: () => _deleteItemById(item.id),
          onEdit: () => _editItemById(item.id),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final fontFamily = theme.textTheme.bodyLarge?.fontFamily;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing Here!',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: textColor?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Add a ',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: textColor?.withValues(alpha: 0.5),
                    ),
                  ),
                  TextSpan(
                    text: 'Nodly.',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: textColor?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: DateSelector(
                selectedDate: _selectedDate,
                onDateSelected: _onDateSelected,
                onSettingsTap: _openSettings,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : _items.isEmpty
                      ? _buildEmptyState()
                      : _buildTaskList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createItem,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildTaskList() {
    return Stack(
      children: [
        AnimatedList(
          key: _listKey,
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 12, bottom: 80),
          initialItemCount: _items.length,
          itemBuilder: _buildCard,
        ),
        // Top fade
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _showTopFade ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Bottom fade
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _showBottomFade ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
