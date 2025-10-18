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
  final bool isFromRecurring; // ✅ NUOVO: indica se proviene da ricorrente

  MoneyTx({
    this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.payment,
    this.isFromRecurring = false, // ✅ NUOVO
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
      'isFromRecurring': isFromRecurring ? 1 : 0, // ✅ NUOVO
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
      isFromRecurring: (m['isFromRecurring'] ?? 0) == 1, // ✅ NUOVO
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

// ✅ TRANSAZIONE RICORRENTE CON ORARIO
class Recurring {
  final int? id;
  final String category;
  final double amount;
  final int dayOfMonth; // Giorno del mese (1-31)
  final TimeOfDay time; // ✅ NUOVO: Orario di esecuzione
  final PaymentMethod payment;
  final String? note;
  final DateTime? lastProcessed;

  Recurring({
    this.id,
    required this.category,
    required this.amount,
    required this.dayOfMonth,
    required this.time, // ✅ NUOVO
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
      'timeHour': time.hour, // ✅ NUOVO
      'timeMinute': time.minute, // ✅ NUOVO
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
      time: TimeOfDay( // ✅ NUOVO
        hour: map['timeHour'] ?? 9, // Default 9:00 se non presente
        minute: map['timeMinute'] ?? 0,
      ),
      payment: PaymentMethod.values[map['payment']],
      note: map['note'],
      lastProcessed: map['lastProcessed'] != null
          ? DateTime.parse(map['lastProcessed'])
          : null,
    );
  }

  // ✅ MIGLIORATO: Verifica se deve essere processata considerando l'orario
  bool shouldProcessNow() {
    final now = DateTime.now();
    final thisMonthProcessDateTime = DateTime(
      now.year, 
      now.month, 
      dayOfMonth,
      time.hour,
      time.minute,
    );

    // Se non è mai stata processata
    if (lastProcessed == null) {
      return now.isAfter(thisMonthProcessDateTime) || now.isAtSameMomentAs(thisMonthProcessDateTime);
    }

    // Se è già stata processata questo mese, non processare
    final lastProcessedDate = lastProcessed!;
    if (lastProcessedDate.year == now.year && lastProcessedDate.month == now.month) {
      return false;
    }

    // Processa solo se è il momento giusto
    return now.isAfter(thisMonthProcessDateTime) || now.isAtSameMomentAs(thisMonthProcessDateTime);
  }

  // ✅ MIGLIORATO: Crea transazione con timestamp preciso
  MoneyTx toTransaction() {
    final now = DateTime.now();
    final transactionDateTime = DateTime(
      now.year,
      now.month,
      dayOfMonth,
      time.hour,
      time.minute,
    );

    return MoneyTx(
      isIncome: false,
      category: category,
      amount: amount,
      date: transactionDateTime,
      note: note != null ? '🔄 Ricorrente: $note' : '🔄 Pagamento ricorrente automatico',
      payment: payment,
      isFromRecurring: true, // ✅ NUOVO: marca come proveniente da ricorrente
    );
  }

  // ✅ NUOVO: Formatta l'orario
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Style per categoria
class CategoryStyle {
  final IconData icon;
  final Color color;
  CategoryStyle(this.icon, this.color);
}
