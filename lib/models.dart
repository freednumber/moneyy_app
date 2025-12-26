import 'package:flutter/material.dart';

enum PaymentMethod {
  contanti,
  carta,
  bancomat,
  bonifico,
}

class MoneyTx {
  final int? id;
  final bool isIncome;
  final String category;
  final double amount;
  final DateTime date;
  final String? note;
  final PaymentMethod payment;
  final bool isFromRecurring;

  MoneyTx({
    this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.payment,
    this.isFromRecurring = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'payment': payment.name,
    };
  }

  factory MoneyTx.fromMap(Map<String, dynamic> map) {
    return MoneyTx(
      id: map['id'],
      isIncome: map['isIncome'] == 1,
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      payment: PaymentMethod.values.firstWhere(
        (e) => e.name == map['payment'],
        orElse: () => PaymentMethod.contanti,
      ),
    );
  }
}

// ✨ CLASSE GOAL CON SUPPORTO ICONE (SENZA CATEGORIA)
class Goal {
  final int? id;
  final String title;
  final double target;
  final double saved;
  final bool isPurchased;
  final IconData? icon; // 🔥 Campo icona

  Goal({
    this.id,
    required this.title,
    required this.target,
    required this.saved,
    this.isPurchased = false,
    this.icon, // 🔥 Icona opzionale
  });

  bool get isCompleted => progress >= 100;
  double get progress => (saved / target * 100).clamp(0, 100);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'saved': saved,
      'isPurchased': isPurchased ? 1 : 0,
      'iconCodePoint': icon?.codePoint, // 🔥 Salva codePoint
    };
  }

  factory Goal.fromMap(Map map) {
  IconData? iconData;
  if (map['iconCodePoint'] != null) {
    final codePoint = map['iconCodePoint'] as int;  // ✅ FIX
    iconData = IconData(
      codePoint,
      fontFamily: 'MaterialIcons',
    );
  }

    return Goal(
      id: map['id'],
      title: map['title'],
      target: map['target'],
      saved: map['saved'],
      isPurchased: map['isPurchased'] == 1,
      icon: iconData,
    );
  }

  Goal copyWith({
    int? id,
    String? title,
    double? target,
    double? saved,
    bool? isPurchased,
    IconData? icon, // 🔥 Supporto modifica icona
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

class Recurring {
  final int? id;
  final bool isIncome;
  final String category;
  final double amount;
  final int dayOfMonth;
  final TimeOfDay time;
  final PaymentMethod payment;
  final String? note;
  final DateTime? lastProcessed;

  Recurring({
    this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    required this.time,
    required this.payment,
    this.note,
    this.lastProcessed,
  });

  bool shouldProcessNow() {
    final now = DateTime.now();
    if (lastProcessed != null) {
      final lastMonth = DateTime(lastProcessed!.year, lastProcessed!.month);
      final currentMonth = DateTime(now.year, now.month);
      if (!currentMonth.isAfter(lastMonth)) {
        return false;
      }
    }
    return now.day >= dayOfMonth;
  }

  MoneyTx toTransaction() {
    final now = DateTime.now();
    final txDate = DateTime(
      now.year,
      now.month,
      dayOfMonth > 28 ? 28 : dayOfMonth,
      time.hour,
      time.minute,
    );
    return MoneyTx(
      isIncome: isIncome,
      category: category,
      amount: amount,
      date: txDate,
      note: note,
      payment: payment,
      isFromRecurring: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'payment': payment.name,
      'note': note,
      'lastProcessed': lastProcessed?.toIso8601String(),
    };
  }

  factory Recurring.fromMap(Map<String, dynamic> map) {
    return Recurring(
      id: map['id'],
      isIncome: map['isIncome'] == 1,
      category: map['category'],
      amount: map['amount'],
      dayOfMonth: map['dayOfMonth'],
      time: TimeOfDay(hour: map['timeHour'], minute: map['timeMinute']),
      payment: PaymentMethod.values.firstWhere(
        (e) => e.name == map['payment'],
        orElse: () => PaymentMethod.contanti,
      ),
      note: map['note'],
      lastProcessed: map['lastProcessed'] != null
          ? DateTime.parse(map['lastProcessed'])
          : null,
    );
  }
}
