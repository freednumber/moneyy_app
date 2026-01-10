import 'package:flutter/material.dart';

class Goal {
  final int? id;
  final String title;
  final double target;
  final double saved;
  final bool isPurchased;
  final IconData? icon;

  Goal({
    this.id,
    required this.title,
    required this.target,
    required this.saved,
    this.isPurchased = false,
    this.icon,
  });

  double get progress => (target == 0) ? 0 : (saved / target * 100).clamp(0, 100);

  factory Goal.fromMap(Map<String, dynamic> map) {
    IconData? iconData;
    if (map['iconCodePoint'] != null) {
      iconData = IconData(
        map['iconCodePoint'] as int,
        fontFamily: 'MaterialIcons',
      );
    }
    return Goal(
      id: map['id'],
      title: map['title'],
      target: map['target'],
      saved: map['saved'],
      isPurchased: (map['isPurchased'] ?? 0) == 1,
      icon: iconData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'saved': saved,
      'isPurchased': isPurchased ? 1 : 0,
      'iconCodePoint': icon?.codePoint,
    };
  }

  Goal copyWith({
    int? id,
    String? title,
    double? target,
    double? saved,
    bool? isPurchased,
    IconData? icon,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      isPurchased: isPurchased ?? this.isPurchased,
      icon: icon ?? this.icon,
    );
  }
}
