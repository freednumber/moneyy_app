import 'package:flutter/material.dart';
import 'transaction_model.dart'; // ✅ Importa questo per trovare PaymentMethod e MoneyTx

class Recurring {
  final int? id;
  final bool isIncome;
  final String category;
  final double amount;
  final String? note;
  final int dayOfMonth;
  final TimeOfDay time;
  final DateTime? lastProcessed;
  final PaymentMethod payment;

  Recurring({
    this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    this.note,
    required this.dayOfMonth,
    required this.time,
    this.lastProcessed,
    this.payment = PaymentMethod.carta,
  });

  bool shouldProcessNow() {
    final now = DateTime.now();
    if (lastProcessed != null) {
      final lastMonth = DateTime(lastProcessed!.year, lastProcessed!.month);
      final currentMonth = DateTime(now.year, now.month);
      if (!currentMonth.isAfter(lastMonth)) return false;
    }
    return now.day >= dayOfMonth;
  }

  MoneyTx toTransaction() {
    final now = DateTime.now();
    // Creiamo la data per "questo mese"
    // Se oggi è 20 e la ricorrenza è il 5, sarà il 5 di questo mese (già passato)
    // Se oggi è 1 e la ricorrenza è il 5, sarà il 5 di questo mese (futuro)
    // Ma toTransaction viene chiamato solo quando è il momento giusto.
    
    return MoneyTx(
      id: null, // Nuovo ID generato dal DB
      isIncome: isIncome,
      category: category,
      amount: amount,
      date: DateTime.now(), // Usa l'orario di esecuzione effettivo
      note: note ?? 'Ricorrenza automatica',
      payment: payment,
      isRecurring: true, // ✅ CORRETTO: usa isRecurring, non isFromRecurring
    );
  }

  factory Recurring.fromMap(Map<String, dynamic> map) {
    return Recurring(
      id: map['id'],
      isIncome: (map['isIncome'] ?? 0) == 1,
      category: map['category'],
      amount: map['amount'],
      note: map['note'],
      dayOfMonth: map['dayOfMonth'],
      time: TimeOfDay(hour: map['timeHour'], minute: map['timeMinute']),
      lastProcessed: map['lastProcessed'] != null ? DateTime.parse(map['lastProcessed']) : null,
      payment: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['payment'] ?? 'carta'),
        orElse: () => PaymentMethod.carta,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'amount': amount,
      'note': note,
      'dayOfMonth': dayOfMonth,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'lastProcessed': lastProcessed?.toIso8601String(),
      'payment': payment.name,
    };
  }

  Recurring copyWith({
    int? id,
    bool? isIncome,
    String? category,
    double? amount,
    String? note,
    int? dayOfMonth,
    TimeOfDay? time,
    DateTime? lastProcessed,
    PaymentMethod? payment,
  }) {
    return Recurring(
      id: id ?? this.id,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      time: time ?? this.time,
      lastProcessed: lastProcessed ?? this.lastProcessed,
      payment: payment ?? this.payment,
    );
  }
}
