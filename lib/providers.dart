import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'repository.dart';

class MoneyModel extends ChangeNotifier {
  final Repository _repo = Repository();
  List<MoneyTx> transactions = [];
  List<Goal> goals = [];
  List<Recurring> recurringTransactions = [];
  bool loading = true;
  String currency = '€';

  // Categorie
  final List<String> expenseCats = [
    'Spesa', 'Trasporti', 'Ristoranti', 'Shopping', 'Bollette',
    'Casa', 'Salute', 'Sport', 'Regali', 'Viaggi', 'Altro'
  ];
  
  final List<String> incomeCats = [
    'Stipendio', 'Freelance', 'Investimenti', 'Regalo', 'Altro'
  ];
  
  final List<String> goalCategories = [
    'COMPUTER', 'SMARTPHONE', 'VIAGGIO', 'AUTO', 'CASA', 'INVESTIMENTI', 'ALTRO'
  ];

  // Computed
  List<MoneyTx> get recent => transactions.take(20).toList();
  List<Goal> get activeGoals => goals.where((g) => !g.isCompleted).toList();
  List<Goal> get completedGoals => goals.where((g) => g.isCompleted).toList();

  // ✅ NUOVO: Processa automaticamente le transazioni ricorrenti
  Future<void> processRecurringTransactions() async {
    final now = DateTime.now();
    bool hasNewTransactions = false;

    for (var recurring in recurringTransactions) {
      if (recurring.shouldProcessNow()) {
        // Crea la transazione automatica
        final automaticTx = recurring.toTransaction();
        await _repo.insertTx(automaticTx);
        
        // Aggiorna il lastProcessed della ricorrente
        final updatedRecurring = Recurring(
          id: recurring.id,
          category: recurring.category,
          amount: recurring.amount,
          dayOfMonth: recurring.dayOfMonth,
          time: recurring.time,
          payment: recurring.payment,
          note: recurring.note,
          lastProcessed: now,
        );
        
        await _repo.updateRecurring(updatedRecurring);
        hasNewTransactions = true;
        
        debugPrint('✅ Transazione ricorrente processata: ${recurring.category} - €${recurring.amount}');
      }
    }

    if (hasNewTransactions) {
      await loadInitial();
      debugPrint('🔄 Transazioni ricorrenti aggiornate automaticamente');
    }
  }

  // ✅ Genera transazioni dalle ricorrenti - partono da OGGI in avanti
  List<MoneyTx> getRecurringTransactionsForPeriod(DateTime start, DateTime end) {
    final List<MoneyTx> generatedTxs = [];
    
    for (var recurring in recurringTransactions) {
      // ✅ Parte dal mese CORRENTE o successivo, non va indietro
      final now = DateTime.now();
      final firstValidMonth = DateTime(now.year, now.month, 1);
      
      // Inizia dal primo mese utile (o successivo se start è futuro)
      DateTime currentMonth = start.isAfter(firstValidMonth)
          ? DateTime(start.year, start.month, 1)
          : firstValidMonth;
      
      while (currentMonth.isBefore(end) || (currentMonth.month == end.month && currentMonth.year == end.year)) {
        // Data della ricorrente in questo mese
        final recurringDate = DateTime(
          currentMonth.year,
          currentMonth.month,
          recurring.dayOfMonth > 28 ? 28 : recurring.dayOfMonth,
          recurring.time.hour,
          recurring.time.minute,
        );
        
        // ✅ Solo se la data è >= oggi e cade nel periodo
        if (recurringDate.isAfter(now.subtract(const Duration(days: 1))) &&
            recurringDate.isAfter(start.subtract(const Duration(days: 1))) &&
            recurringDate.isBefore(end)) {
          generatedTxs.add(MoneyTx(
            id: null,
            isIncome: recurring.isIncome,
            category: recurring.category,
            amount: recurring.amount,
            date: recurringDate,
            note: '🔄 ${recurring.note ?? recurring.category}',
            payment: recurring.payment,
            isFromRecurring: true,
          ));
        }
        
        // Prossimo mese
        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
        
        // Evita loop infiniti
        if (currentMonth.year > DateTime.now().year + 10) break;
      }
    }
    
    return generatedTxs;
  }

  // ✅ Aggiorna netWorth per includere ricorrenti
  double get netWorth {
    final now = DateTime.now();
    final allTxs = [...transactions, ...getRecurringTransactionsForPeriod(DateTime(2020), now)];
    return allTxs.fold(0.0, (sum, tx) {
      return sum + (tx.isIncome ? tx.amount : -tx.amount);
    });
  }

  // ✅ Aggiorna monthlyIncome per includere ricorrenti
  double get monthlyIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    
    final allTxs = [...transactions, ...getRecurringTransactionsForPeriod(start, end)];
    final thisMonth = allTxs.where((tx) {
      return tx.isIncome &&
             tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
             tx.date.isBefore(end);
    });
    return thisMonth.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // ✅ Aggiorna monthlyExpense per includere ricorrenti
  double get monthlyExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    
    final allTxs = [...transactions, ...getRecurringTransactionsForPeriod(start, end)];
    final thisMonth = allTxs.where((tx) {
      return !tx.isIncome &&
             tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
             tx.date.isBefore(end);
    });
    return thisMonth.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  String format(double amount) {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  CategoryStyle getTransactionStyle(String category) {
    final Map<String, CategoryStyle> styles = {
      'Spesa': CategoryStyle(Icons.shopping_cart, const Color(0xFF10B981)),
      'Trasporti': CategoryStyle(Icons.directions_car, const Color(0xFF3B82F6)),
      'Ristoranti': CategoryStyle(Icons.restaurant, const Color(0xFFF59E0B)),
      'Shopping': CategoryStyle(Icons.shopping_bag, const Color(0xFFEC4899)),
      'Bollette': CategoryStyle(Icons.receipt_long, const Color(0xFFEF4444)),
      'Casa': CategoryStyle(Icons.home, const Color(0xFF8B5CF6)),
      'Salute': CategoryStyle(Icons.medical_services, const Color(0xFF06B6D4)),
      'Sport': CategoryStyle(Icons.fitness_center, const Color(0xFF84CC16)),
      'Regali': CategoryStyle(Icons.card_giftcard, const Color(0xFFF97316)),
      'Viaggi': CategoryStyle(Icons.flight, const Color(0xFF14B8A6)),
      'Altro': CategoryStyle(Icons.more_horiz, const Color(0xFF6B7280)),
      'Stipendio': CategoryStyle(Icons.work, const Color(0xFF10B981)),
      'Freelance': CategoryStyle(Icons.laptop_mac, const Color(0xFF6366F1)),
      'Investimenti': CategoryStyle(Icons.trending_up, const Color(0xFF8B5CF6)),
      'Regalo': CategoryStyle(Icons.card_giftcard, const Color(0xFFF59E0B)),
      'COMPUTER': CategoryStyle(Icons.computer, const Color(0xFF3B82F6)),
      'SMARTPHONE': CategoryStyle(Icons.smartphone, const Color(0xFF8B5CF6)),
      'VIAGGIO': CategoryStyle(Icons.flight, const Color(0xFF10B981)),
      'AUTO': CategoryStyle(Icons.directions_car, const Color(0xFFEF4444)),
      'CASA': CategoryStyle(Icons.home, const Color(0xFFF59E0B)),
      'INVESTIMENTI': CategoryStyle(Icons.trending_up, const Color(0xFF14B8A6)),
      'ALTRO': CategoryStyle(Icons.flag, const Color(0xFF6B7280)),
    };
    return styles[category] ?? CategoryStyle(Icons.help_outline, const Color(0xFF6B7280));
  }

  CategoryStyle getGoalStyle(String title) {
    final Map<String, CategoryStyle> styles = {
      'COMPUTER': CategoryStyle(Icons.computer, const Color(0xFF3B82F6)),
      'SMARTPHONE': CategoryStyle(Icons.smartphone, const Color(0xFF8B5CF6)),
      'VIAGGIO': CategoryStyle(Icons.flight, const Color(0xFF10B981)),
      'AUTO': CategoryStyle(Icons.directions_car, const Color(0xFFEF4444)),
      'CASA': CategoryStyle(Icons.home, const Color(0xFFF59E0B)),
      'INVESTIMENTI': CategoryStyle(Icons.trending_up, const Color(0xFF14B8A6)),
      'ALTRO': CategoryStyle(Icons.flag, const Color(0xFF6B7280)),
    };
    return styles[title] ?? CategoryStyle(Icons.flag, const Color(0xFF6366F1));
  }

  Future<void> loadInitial() async {
    loading = true;
    notifyListeners();
    transactions = await _repo.getAllTx();
    goals = await _repo.getAllGoals();
    recurringTransactions = await _repo.getRecurring();
    
    // ✅ NUOVO: Processa automaticamente le ricorrenti quando si carica l'app
    await processRecurringTransactions();
    
    loading = false;
    notifyListeners();
  }

  Future<void> addTx(MoneyTx tx) async {
    await _repo.insertTx(tx);
    await loadInitial();
  }

  Future<void> updateTransaction(MoneyTx tx) async {
    await _repo.updateTx(tx);
    await loadInitial();
  }

  Future<void> deleteTransaction(int id) async {
    await _repo.deleteTx(id);
    await loadInitial();
  }

  Future<void> addGoal(Goal goal) async {
    await _repo.insertGoal(goal);
    await loadInitial();
  }

  Future<void> contributeToGoal(int goalId, double amount) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    final updated = Goal(
      id: goal.id,
      title: goal.title,
      target: goal.target,
      saved: goal.saved + amount,
      isPurchased: goal.isPurchased,
    );
    await _repo.updateGoal(updated);
    await loadInitial();
  }

  Future<void> updateGoal(Goal goal) async {
    await _repo.updateGoal(goal);
    await loadInitial();
  }

  Future<void> purchaseGoal(int goalId) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    final tx = MoneyTx(
      id: null,
      isIncome: false,
      category: goal.title,
      amount: goal.target,
      date: DateTime.now(),
      note: 'Acquisto: ${goal.title}',
      payment: PaymentMethod.carta,
    );
    await addTx(tx);
    
    final updated = Goal(
      id: goal.id,
      title: goal.title,
      target: goal.target,
      saved: goal.saved,
      isPurchased: true,
    );
    await _repo.updateGoal(updated);
    await loadInitial();
  }

  Future<void> unpurchaseGoal(int goalId) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    final purchaseTxs = transactions.where(
      (tx) => tx.category == goal.title &&
              !tx.isIncome &&
              tx.amount == goal.target
    ).toList();
    
    if (purchaseTxs.isNotEmpty) {
      await deleteTransaction(purchaseTxs.first.id!);
    }
    
    final updated = Goal(
      id: goal.id,
      title: goal.title,
      target: goal.target,
      saved: goal.saved,
      isPurchased: false,
    );
    await _repo.updateGoal(updated);
    await loadInitial();
  }

  Future<void> deleteGoal(int id) async {
    await _repo.deleteGoal(id);
    await loadInitial();
  }

  Future<void> addRecurring(Recurring recurring) async {
    await _repo.insertRecurring(recurring);
    await loadInitial();
  }

  Future<void> updateRecurring(Recurring recurring) async {
    await _repo.updateRecurring(recurring);
    await loadInitial();
  }

  Future<void> deleteRecurring(int id) async {
    await _repo.deleteRecurring(id);
    await loadInitial();
  }
}

class CategoryStyle {
  final IconData icon;
  final Color color;
  CategoryStyle(this.icon, this.color);
}
