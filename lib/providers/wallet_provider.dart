import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../models/models.dart';
import '../data/database_helper.dart';
import '../services/notifications_service.dart';
import '../services/import_service.dart';
import '../models/transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<MoneyTx> transactions = [];
  List<Goal> goals = [];
  List<Recurring> recurringTransactions = [];
  
  bool loading = true;
  String currency = '€';

  Future<void> loadInitial() async {
    loading = true;
    notifyListeners();

    try {
      transactions = await _db.getAllTx();
      // ⚡️ FONDAMENTALE: Ordina per data decrescente (più recenti in alto)
      // Senza questo, le nuove ricorrenti finiscono in fondo e non le vedi nella Home
      transactions.sort((a, b) => b.date.compareTo(a.date));

      goals = await _db.getAllGoals();
      recurringTransactions = await _db.getRecurring();

      if (transactions.isEmpty && goals.isEmpty && recurringTransactions.isEmpty) {
        await _restoreFromPrefs();
        transactions = await _db.getAllTx();
        transactions.sort((a, b) => b.date.compareTo(a.date)); // Riordina anche dopo restore
        goals = await _db.getAllGoals();
        recurringTransactions = await _db.getRecurring();
      }
      
      // Controllo ricorrenze
      await processRecurringTransactions();
    } catch (e) {
      debugPrint("Errore caricamento dati: $e");
    }

    loading = false;
    notifyListeners();
  }

  // --- GETTERS ---
  double get netBalance => transactions.fold(0.0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
  
  double get availableBalance {
    final totalSaved = goals.where((g) => !g.isPurchased).fold(0.0, (sum, g) => sum + g.saved);
    return netBalance - totalSaved;
  }

  List<MoneyTx> get recent => transactions.take(20).toList();
  List<Goal> get activeGoals => goals.where((g) => !g.isPurchased).toList();
  List<Goal> get completedGoals => goals.where((g) => g.isPurchased).toList();

  String format(double amount) => '${amount.toStringAsFixed(2)} $currency';
  
  double get monthlyIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return transactions.where((tx) =>
      tx.isIncome && tx.date.isAfter(start.subtract(const Duration(days: 1))) && tx.date.isBefore(end)
    ).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return transactions.where((tx) =>
      !tx.isIncome && tx.date.isAfter(start.subtract(const Duration(days: 1))) && tx.date.isBefore(end)
    ).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // --- CRUD TRANSAZIONI ---
  Future<void> addTx(MoneyTx tx) async {
    await _db.insertTx(tx);
    await loadInitial();
    _backupToPrefs();
  }

  Future<void> updateTransaction(MoneyTx tx) async {
    await _db.updateTx(tx);
    await loadInitial();
    _backupToPrefs();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTx(id);
    await loadInitial();
    _backupToPrefs();
  }

  // --- CRUD OBIETTIVI ---
  Future<void> addGoal(Goal goal) async {
    await _db.insertGoal(goal);
    await loadInitial();
    _backupToPrefs();
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.updateGoal(goal);
    await loadInitial();
    _backupToPrefs();
  }

  Future<void> deleteGoal(int id) async {
    await _db.deleteGoal(id);
    await loadInitial();
    _backupToPrefs();
  }

  Future<void> addMoneyToGoal(Goal goal, double amount) async {
    final tx = MoneyTx(
      isIncome: false, category: 'Risparmio: ${goal.title}',
      amount: amount, date: DateTime.now(),
      note: 'Versamento obiettivo', payment: PaymentMethod.carta
    );
    await addTx(tx);
    final updated = goal.copyWith(saved: goal.saved + amount);
    await updateGoal(updated);
  }

  Future<void> purchaseGoal(int goalId, String selectedCategory) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    final tx = MoneyTx(
      isIncome: false, category: selectedCategory,
      amount: goal.target, date: DateTime.now(),
      note: 'Acquisto obiettivo: ${goal.title}', payment: PaymentMethod.carta,
    );
    await addTx(tx);
    final updated = goal.copyWith(isPurchased: true);
    await updateGoal(updated);
  }
  
  Future<void> unpurchaseGoal(int goalId) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    try {
      final purchaseTx = transactions.firstWhere(
        (t) => t.note == 'Acquisto obiettivo: ${goal.title}' && !t.isIncome
      );
      if(purchaseTx.id != null) await deleteTransaction(purchaseTx.id!);
    } catch (_) {}
    final updated = goal.copyWith(isPurchased: false);
    await updateGoal(updated);
  }

  // --- CRUD RICORRENTI (CORRETTO) ---

  Future<void> addRecurring(Recurring recurring) async {
    // ⚡️ FIX CRITICO: Recupera l'ID generato dal database!
    // Prima, recurring.id era null, quindi la notifica veniva salvata con ID sbagliato.
    final int newId = await _db.insertRecurring(recurring);
    
    // Crea una copia con l'ID corretto per la notifica
    final recurringWithId = recurring.copyWith(id: newId);
    
    // Programma notifica usando l'oggetto con l'ID
    await NotificationsService.scheduleRecurringNotification(recurringWithId);
    
    await loadInitial();
    _backupToPrefs();
  }

  Future<void> updateRecurring(Recurring recurring) async {
    await _db.updateRecurring(recurring);
    
    // Aggiorna Notifica: Cancella vecchia -> Crea nuova
    if (recurring.id != null) {
      try {
        await NotificationsService.cancelRecurringNotification(recurring.id!);
        await NotificationsService.scheduleRecurringNotification(recurring);
      } catch (e) {
        debugPrint("Errore riprogrammazione notifica: $e");
      }
    }

    await loadInitial();
    _backupToPrefs();
  }

  Future<void> deleteRecurring(int id) async {
    // Try-catch per non bloccare l'eliminazione se la notifica non si trova
    try {
      await NotificationsService.cancelRecurringNotification(id);
    } catch (e) {
      debugPrint("Notifica non trovata o errore: $e");
    }
    
    await _db.deleteRecurring(id);
    await loadInitial();
    _backupToPrefs();
  }

  // ✅ LOGICA DI PROCESSAMENTO AUTOMATICO
  Future<void> processRecurringTransactions() async {
    final now = DateTime.now();
    bool hasNew = false;

    for (var rec in recurringTransactions) {
      bool processedThisMonth = false;
      if (rec.lastProcessed != null) {
         if (rec.lastProcessed!.year == now.year && rec.lastProcessed!.month == now.month) {
           processedThisMonth = true;
         }
      }
      if (processedThisMonth) continue;

      if (now.day < rec.dayOfMonth) continue;

      // Controllo Orario Rigoroso
      if (now.day == rec.dayOfMonth) {
         final scheduledTime = DateTime(now.year, now.month, now.day, rec.time.hour, rec.time.minute);
         if (now.isBefore(scheduledTime)) {
           continue;
         }
      }

      // Genera Transazione
      final tx = rec.toTransaction();
      await _db.insertTx(tx);
      
      final updated = rec.copyWith(lastProcessed: now);
      await _db.updateRecurring(updated);
      
      await NotificationsService.notifyRecurringCreated(rec);
      
      hasNew = true;
    }

    // Se ci sono nuove transazioni, ricarica tutto e riordina per mostrare le più recenti
    if (hasNew) {
      transactions = await _db.getAllTx();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }
  
  // --- IMPORTAZIONE ---
  Future<Map<String, int>> importFromCSV(String csvContent, Map<String, String> mapping) async {
    final txs = ImportService.parseCSV(csvContent, mapping);
    int count = 0;
    for (var tx in txs) { await _db.insertTx(tx); count++; }
    await loadInitial();
    return {'imported': count, 'skipped': 0};
  }
  
  Future<Map<String, int>> importFromExcel(Uint8List fileBytes, Map<String, String> mapping) async {
    final txs = await ImportService.parseExcel(fileBytes, mapping);
    int count = 0;
    for (var tx in txs) { await _db.insertTx(tx); count++; }
    await loadInitial();
    return {'imported': count, 'skipped': 0};
  }
  
  Future<Map<String, int>> importFromMMBackup(String jsonContent, Map<String, String> mapping) async {
    final txs = ImportService.parseMMBackup(jsonContent, mapping);
    int count = 0;
    for (var tx in txs) { await _db.insertTx(tx); count++; }
    await loadInitial();
    return {'imported': count, 'skipped': 0};
  }

  // --- BACKUP ---
  Future<void> resetAllData() async {
    await _db.wipeDatabase();
    await loadInitial();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  Future<void> _backupToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('backup_transactions', jsonEncode(transactions.map((t) => t.toMap()).toList()));
      prefs.setString('backup_goals', jsonEncode(goals.map((g) => g.toMap()).toList()));
      prefs.setString('backup_recurring', jsonEncode(recurringTransactions.map((r) => r.toMap()).toList()));
    } catch (_) {}
  }

  Future<void> _restoreFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final txJson = prefs.getString('backup_transactions');
      if (txJson != null) {
        final List<dynamic> d = jsonDecode(txJson);
        for (var m in d) await _db.insertTx(MoneyTx.fromMap(m));
      }
      final gJson = prefs.getString('backup_goals');
      if (gJson != null) {
        final List<dynamic> d = jsonDecode(gJson);
        for (var m in d) await _db.insertGoal(Goal.fromMap(m));
      }
      final rJson = prefs.getString('backup_recurring');
      if (rJson != null) {
        final List<dynamic> d = jsonDecode(rJson);
        for (var m in d) await _db.insertRecurring(Recurring.fromMap(m));
      }
    } catch (_) {}
  }
}
