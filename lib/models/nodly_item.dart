import 'dart:convert';

class NodlyItem {
  final String id;
  String text;
  final String dateKey; // yyyy-MM-dd format
  final DateTime createdAt;

  NodlyItem({
    required this.id,
    required this.text,
    required this.dateKey,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'dateKey': dateKey,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NodlyItem.fromJson(Map<String, dynamic> json) => NodlyItem(
        id: json['id'] as String,
        text: json['text'] as String,
        dateKey: json['dateKey'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static String encode(List<NodlyItem> items) =>
      json.encode(items.map((item) => item.toJson()).toList());

  static List<NodlyItem> decode(String jsonString) =>
      (json.decode(jsonString) as List<dynamic>)
          .map((item) => NodlyItem.fromJson(item as Map<String, dynamic>))
          .toList();
}
