import 'package:flutter/material.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;

  CategoryStyle(this.icon, this.color);

  Map<String, dynamic> toJson() => {
    'icon': icon.codePoint,
    'color': color.value,
  };

  factory CategoryStyle.fromJson(Map json) {
    final iconCodePoint = json['icon'] as int;
    final colorValue = json['color'] as int;
    return CategoryStyle(
      IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      Color(colorValue),
    );
  }
}
