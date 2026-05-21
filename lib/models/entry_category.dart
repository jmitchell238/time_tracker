import 'package:flutter/material.dart';

class EntryCategory {
  final String id;
  final String name;
  final int colorValue; // 0xAARRGGBB
  final String createdAt;

  const EntryCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  EntryCategory copyWith({String? name, int? colorValue}) => EntryCategory(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'createdAt': createdAt,
      };

  factory EntryCategory.fromJson(Map<String, dynamic> j) => EntryCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        colorValue: j['colorValue'] as int,
        createdAt: j['createdAt'] as String,
      );

  static const List<Color> palette = [
    Color(0xFFF97316), // orange
    Color(0xFF3B82F6), // blue
    Color(0xFF10B981), // emerald
    Color(0xFF8B5CF6), // violet
    Color(0xFFEF4444), // red
    Color(0xFF14B8A6), // teal
    Color(0xFFEC4899), // pink
    Color(0xFFEAB308), // yellow
    Color(0xFF06B6D4), // cyan
    Color(0xFF6366F1), // indigo
  ];
}
