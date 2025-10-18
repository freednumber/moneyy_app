import 'package:flutter/material.dart';

// Enumerazioni
enum PaymentMethod { contanti, carta, bancomat }

// Transazione
class MoneyTx {
  final int? id;
  final bool isIncome;
  final String category;
  final double amount;
  final DateTime date;
  final String? note;
  final PaymentMethod payment;

  MoneyTx({
    this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.payment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'payment': payment.index,
    };
  }

  factory MoneyTx.fromMap(Map<String, dynamic> m) {
    return MoneyTx(
      id: m['id'],
      isIncome: m['isIncome'] == 1,
      category: m['category'],
      amount: m['amount'],
      date: DateTime.parse(m['date']),
      note: m['note'],
      payment: PaymentMethod.values[m['payment']],
    );
  }
}

// Obiettivo
class Goal {
  final int? id;
  final String title;
  final double target;
  final double saved;
  final bool isPurchased;

  Goal({
    this.id,
    required this.title,
    required this.target,
    required this.saved,
    this.isPurchased = false,
  });

  bool get isCompleted => saved >= target;
  double get progress => (saved / target * 100).clamp(0, 100);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'saved': saved,
      'isPurchased': isPurchased ? 1 : 0,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> m) {
    return Goal(
      id: m['id'],
      title: m['title'],
      target: m['target'],
      saved: m['saved'],
      isPurchased: m['isPurchased'] == 1,
    );
  }
}

// ✅ TRANSAZIONE RICORRENTE - VERSIONE SEMPLIFICATA CON dayOfMonth
class Recurring {
  final int? id;
  final String category;
  final double amount;
  final int dayOfMonth; // Giorno del mese (1-31)
  final PaymentMethod payment;
  final String? note;
  final DateTime? lastProcessed;

  Recurring({
    this.id,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    required this.payment,
    this.note,
    this.lastProcessed,
  });

  // Getter per compatibilità
  bool get isIncome => false; // Le ricorrenti sono sempre uscite

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'payment': payment.index,
      'note': note,
      'lastProcessed': lastProcessed?.toIso8601String(),
    };
  }

  factory Recurring.fromMap(Map<String, dynamic> map) {
    return Recurring(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      dayOfMonth: map['dayOfMonth'],
      payment: PaymentMethod.values[map['payment']],
      note: map['note'],
      lastProcessed: map['lastProcessed'] != null
          ? DateTime.parse(map['lastProcessed'])
          : null,
    );
  }

  // Verifica se deve essere processata questo mese
  bool shouldProcessThisMonth() {
    final now = DateTime.now();
    final thisMonthProcessDate = DateTime(now.year, now.month, dayOfMonth);

    if (lastProcessed == null) {
      return now.isAfter(thisMonthProcessDate) || now.isAtSameMomentAs(thisMonthProcessDate);
    }

    final lastProcessedDate = lastProcessed!;
    if (lastProcessedDate.year == now.year && lastProcessedDate.month == now.month) {
      return false;
    }

    return now.isAfter(thisMonthProcessDate) || now.isAtSameMomentAs(thisMonthProcessDate);
  }

  // Crea transazione da ricorrente
  MoneyTx toTransaction() {
    return MoneyTx(
      isIncome: false,
      category: category,
      amount: amount,
      date: DateTime.now(),
      note: note != null ? 'Ricorrente: $note' : 'Pagamento ricorrente',
      payment: payment,
    );
  }
}

// Style per categoria
class CategoryStyle {
  final IconData icon;
  final Color color;
  CategoryStyle(this.icon, this.color);
}
