import 'package:flutter/material.dart';
import 'models.dart';

class MoneyModel extends ChangeNotifier {
  List<MoneyTx> _transactions = [];
  List<Goal> _goals = [];
  Map<String, double> _budgets = {
    'Spesa': 500.0,
    'Shopping': 600.0,
    'Trasporti': 200.0,
    'Svago': 300.0,
    'Casa': 800.0,
    'Salute': 150.0,
  };
  
  // Getters
  List<MoneyTx> get transactions => List.unmodifiable(_transactions);
  List<MoneyTx> get recent => _transactions.take(8).toList();
  List<Goal> get goals => List.unmodifiable(_goals);
  Map<String, double> get budgets => Map.unmodifiable(_budgets);
  
  // Categories
  final List<String> incomeCats = ['Stipendio', 'Freelance', 'Investimenti', 'Regalo', 'Altro Reddito'];
  final List<String> expenseCats = ['Spesa', 'Trasporti', 'Svago', 'Salute', 'Shopping', 'Bollette', 'Casa', 'Altro'];
  List<String> get goalCategories => _goals.map((g) => g.title).toList();
  
  // Financial calculations
  double get netWorth => _transactions.fold(0.0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
  double get monthlyIncome { final now = DateTime.now(); return _transactions.where((tx) => tx.isIncome && tx.date.month == now.month && tx.date.year == now.year).fold(0.0, (s, tx) => s + tx.amount); }
  double get monthlyExpense { final now = DateTime.now(); return _transactions.where((tx) => !tx.isIncome && tx.date.month == now.month && tx.date.year == now.year).fold(0.0, (s, tx) => s + tx.amount); }
  double get dailyIncome { final today = DateTime.now(); return _transactions.where((tx) => tx.isIncome && _isSameDay(tx.date, today)).fold(0.0, (s, tx) => s + tx.amount); }
  double get dailyExpense { final today = DateTime.now(); return _transactions.where((tx) => !tx.isIncome && _isSameDay(tx.date, today)).fold(0.0, (s, tx) => s + tx.amount); }
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // Transaction management
  void addTx(MoneyTx tx) { _transactions.insert(0, tx); notifyListeners(); }
  void removeTx(MoneyTx tx) { _transactions.remove(tx); notifyListeners(); }
  void updateTx(MoneyTx oldTx, MoneyTx newTx) { final i = _transactions.indexOf(oldTx); if (i != -1) { _transactions[i] = newTx; notifyListeners(); } }

  // Goals management (models.dart)
  void addGoal(Goal goal) { _goals.add(goal); notifyListeners(); }
  void updateGoal(Goal goal) { final i = _goals.indexWhere((g) => g.id == goal.id); if (i != -1) { _goals[i] = goal; notifyListeners(); } }
  void removeGoal(Goal goal) { _goals.remove(goal); notifyListeners(); }

  // Budget
  void setBudget(String category, double amount) { _budgets[category] = amount; notifyListeners(); }
  double getBudgetUsage(String category) { final b = _budgets[category] ?? 0; if (b <= 0) return 0; final spent = getMonthlySpending(category); return (spent / b).clamp(0.0, 2.0); }
  double getMonthlySpending(String category) { final now = DateTime.now(); return _transactions.where((tx) => !tx.isIncome && tx.category == category && tx.date.month == now.month && tx.date.year == now.year).fold(0.0, (s, tx) => s + tx.amount); }

  // UI helpers
  String format(double amount) => '€${amount.toStringAsFixed(2)}';
  TransactionStyle getTransactionStyle(String category) {
    final styles = {
      'Spesa': TransactionStyle(Icons.shopping_cart, const Color(0xFF10B981)),
      'Trasporti': TransactionStyle(Icons.directions_car, const Color(0xFF3B82F6)),
      'Svago': TransactionStyle(Icons.movie, const Color(0xFF8B5CF6)),
      'Salute': TransactionStyle(Icons.medical_services, const Color(0xFFEF4444)),
      'Shopping': TransactionStyle(Icons.shopping_bag, const Color(0xFFF59E0B)),
      'Bollette': TransactionStyle(Icons.receipt, const Color(0xFF6B7280)),
      'Casa': TransactionStyle(Icons.home, const Color(0xFF059669)),
      'Stipendio': TransactionStyle(Icons.work, const Color(0xFF10B981)),
      'Freelance': TransactionStyle(Icons.laptop, const Color(0xFF6366F1)),
      'Investimenti': TransactionStyle(Icons.trending_up, const Color(0xFF8B5CF6)),
      'Regalo': TransactionStyle(Icons.card_giftcard, const Color(0xFFEC4899)),
      'Altro': TransactionStyle(Icons.category, const Color(0xFF6B7280)),
    }; return styles[category] ?? TransactionStyle(Icons.category, const Color(0xFF6B7280));
  }

  Future<void> loadInitial() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_transactions.isEmpty) {
      _transactions.addAll([
        MoneyTx(id: null, isIncome: false, category: 'Spesa', amount: 45.30, date: DateTime.now().subtract(const Duration(hours: 2)), note: 'Supermercato', payment: PaymentMethod.carta),
        MoneyTx(id: null, isIncome: false, category: 'Trasporti', amount: 12.50, date: DateTime.now().subtract(const Duration(hours: 5)), note: 'Metro', payment: PaymentMethod.carta),
        MoneyTx(id: null, isIncome: true, category: 'Stipendio', amount: 2500.00, date: DateTime.now().subtract(const Duration(days: 1)), note: 'Mensile', payment: PaymentMethod.carta),
        MoneyTx(id: null, isIncome: false, category: 'Svago', amount: 28.90, date: DateTime.now().subtract(const Duration(days: 2)), note: 'Cinema', payment: PaymentMethod.carta),
      ]);
    }
    notifyListeners();
  }
}

class TransactionStyle { final IconData icon; final Color color; TransactionStyle(this.icon, this.color); }
