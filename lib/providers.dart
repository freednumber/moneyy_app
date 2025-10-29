import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';

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
  List<String> get goalCategories => _goals.map((g) => g.name).toList();
  
  // Financial calculations
  double get netWorth => _transactions.fold(0.0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
  
  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.isIncome && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((tx) => !tx.isIncome && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  double get dailyIncome {
    final today = DateTime.now();
    return _transactions
        .where((tx) => tx.isIncome && _isSameDay(tx.date, today))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  double get dailyExpense {
    final today = DateTime.now();
    return _transactions
        .where((tx) => !tx.isIncome && _isSameDay(tx.date, today))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Transaction management
  void addTx(MoneyTx tx) {
    _transactions.insert(0, tx);
    notifyListeners();
  }
  
  void removeTx(MoneyTx tx) {
    _transactions.remove(tx);
    notifyListeners();
  }
  
  void updateTx(MoneyTx oldTx, MoneyTx newTx) {
    final index = _transactions.indexOf(oldTx);
    if (index != -1) {
      _transactions[index] = newTx;
      notifyListeners();
    }
  }

  // Goals management
  void addGoal(Goal goal) {
    _goals.add(goal);
    notifyListeners();
  }
  
  void updateGoal(Goal goal) {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      notifyListeners();
    }
  }
  
  void removeGoal(Goal goal) {
    _goals.remove(goal);
    notifyListeners();
  }

  // Budget management
  void setBudget(String category, double amount) {
    _budgets[category] = amount;
    notifyListeners();
  }
  
  double getBudgetUsage(String category) {
    final budget = _budgets[category] ?? 0;
    if (budget <= 0) return 0;
    
    final spent = getMonthlySpending(category);
    return (spent / budget).clamp(0.0, 2.0); // Max 200% for over-budget
  }
  
  double getMonthlySpending(String category) {
    final now = DateTime.now();
    return _transactions
        .where((tx) => !tx.isIncome && 
               tx.category == category && 
               tx.date.month == now.month && 
               tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // UI helpers
  String format(double amount) {
    return '€${amount.toStringAsFixed(2)}';
  }
  
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
      'Altro Reddito': TransactionStyle(Icons.attach_money, const Color(0xFF22C55E)),
    };
    return styles[category] ?? TransactionStyle(Icons.category, const Color(0xFF6B7280));
  }

  // Data loading (placeholder)
  Future<void> loadInitial() async {
    // Simulo caricamento dati iniziali
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Dati demo se non ci sono transazioni
    if (_transactions.isEmpty) {
      _transactions.addAll([
        MoneyTx(id: '1', isIncome: false, category: 'Spesa', amount: 45.30, date: DateTime.now().subtract(const Duration(hours: 2)), note: 'Supermercato Coop', payment: PaymentMethod.carta),
        MoneyTx(id: '2', isIncome: false, category: 'Trasporti', amount: 12.50, date: DateTime.now().subtract(const Duration(hours: 5)), note: 'Metro giornaliero', payment: PaymentMethod.contanti),
        MoneyTx(id: '3', isIncome: true, category: 'Stipendio', amount: 2500.00, date: DateTime.now().subtract(const Duration(days: 1)), note: 'Stipendio mensile', payment: PaymentMethod.bonifico),
        MoneyTx(id: '4', isIncome: false, category: 'Svago', amount: 28.90, date: DateTime.now().subtract(const Duration(days: 2)), note: 'Cinema Odeon', payment: PaymentMethod.carta),
        MoneyTx(id: '5', isIncome: false, category: 'Shopping', amount: 89.99, date: DateTime.now().subtract(const Duration(days: 3)), note: 'Zara via del Corso', payment: PaymentMethod.carta),
      ]);
    }
    
    // Goals demo se non ci sono
    if (_goals.isEmpty) {
      _goals.addAll([
        Goal(id: '1', name: 'Fondo Emergenza', targetAmount: 5000.0, currentAmount: 2890.0, deadline: DateTime.now().add(const Duration(days: 365)), icon: Icons.savings, color: const Color(0xFF10B981)),
        Goal(id: '2', name: 'Vacanze Estate', targetAmount: 2500.0, currentAmount: 850.0, deadline: DateTime.now().add(const Duration(days: 180)), icon: Icons.flight, color: const Color(0xFF8B5CF6)),
        Goal(id: '3', name: 'Nuova Auto', targetAmount: 15000.0, currentAmount: 4200.0, deadline: DateTime.now().add(const Duration(days: 720)), icon: Icons.directions_car, color: const Color(0xFF3B82F6)),
      ]);
    }
    
    notifyListeners();
  }
}

class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final IconData icon;
  final Color color;
  
  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
    required this.color,
  });
  
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;
}

class TransactionStyle {
  final IconData icon;
  final Color color;
  TransactionStyle(this.icon, this.color);
}