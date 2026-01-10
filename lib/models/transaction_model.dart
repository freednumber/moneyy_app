import 'package:flutter/material.dart';

// Enum per il metodo di pagamento
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
  final String? receiptPath;
  
  final PaymentMethod payment;
  final bool isRecurring; // Usato per la UI

  MoneyTx({
    this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.receiptPath,
    this.payment = PaymentMethod.carta,
    this.isRecurring = false,
  });

  // Getter di compatibilità
  bool get isFromRecurring => isRecurring;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'receiptPath': receiptPath,
      'payment': payment.name,
      // ❌ RIMOSSO 'isRecurring': isRecurring ? 1 : 0 (Questo causava l'errore SQL)
      // ✅ MANTENUTO SOLO QUESTO che corrisponde alla colonna del DB
      'is_recurring': isRecurring ? 1 : 0,
    };
  }

  factory MoneyTx.fromMap(Map<String, dynamic> map) {
    return MoneyTx(
      id: map['id'],
      isIncome: (map['isIncome'] ?? 0) == 1,
      category: map['category'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      receiptPath: map['receiptPath'],
      payment: PaymentMethod.values.firstWhere(
        (e) => e.name == (map['payment'] ?? 'carta'),
        orElse: () => PaymentMethod.carta,
      ),
      // Legge correttamente gestendo i possibili nomi
      isRecurring: (map['is_recurring'] ?? map['isRecurring'] ?? 0) == 1,
    );
  }

  MoneyTx copyWith({
    int? id,
    bool? isIncome,
    String? category,
    double? amount,
    DateTime? date,
    String? note,
    String? receiptPath,
    PaymentMethod? payment,
    bool? isRecurring,
  }) {
    return MoneyTx(
      id: id ?? this.id,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptPath: receiptPath ?? this.receiptPath,
      payment: payment ?? this.payment,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
