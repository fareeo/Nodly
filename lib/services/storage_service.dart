import 'package:shared_preferences/shared_preferences.dart';
import '../models/nodly_item.dart';

class StorageService {
  static const String _prefix = 'nodly_items_';

  static Future<List<NodlyItem>> loadItems(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_prefix$dateKey');
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    return NodlyItem.decode(jsonString);
  }

  static Future<void> saveItems(String dateKey, List<NodlyItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$dateKey', NodlyItem.encode(items));
  }

  static Future<void> addItem(NodlyItem item) async {
    final items = await loadItems(item.dateKey);
    items.add(item);
    await saveItems(item.dateKey, items);
  }

  static Future<void> updateItem(NodlyItem item) async {
    final items = await loadItems(item.dateKey);
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      items[index] = item;
      await saveItems(item.dateKey, items);
    }
  }

  static Future<void> removeItem(String dateKey, String itemId) async {
    final items = await loadItems(dateKey);
    items.removeWhere((item) => item.id == itemId);
    await saveItems(dateKey, items);
  }

  /// Moves an item from [fromDateKey] to [toDateKey].
  /// Returns the moved item with updated dateKey.
  static Future<NodlyItem> moveItem(
      NodlyItem item, String fromDateKey, String toDateKey) async {
    if (fromDateKey == toDateKey) return item;
    await removeItem(fromDateKey, item.id);
    final movedItem = NodlyItem(
      id: item.id,
      text: item.text,
      dateKey: toDateKey,
      createdAt: item.createdAt,
    );
    await addItem(movedItem);
    return movedItem;
  }
}
