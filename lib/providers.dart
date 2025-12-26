import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'repository.dart';

class CategoryStyle {
  final IconData icon;
  final Color color;

  CategoryStyle(this.icon, this.color);

  Map<String, dynamic> toJson() => {
        'icon': icon.codePoint,
        'color': color.value,
      };

  factory CategoryStyle.fromJson(Map<String, dynamic> json) => CategoryStyle(
        IconData(json['icon'], fontFamily: 'MaterialIcons'),
        Color(json['color']),
      );
}

class MoneyModel extends ChangeNotifier {
  final MoneyRepository _repo = MoneyRepository();
  List<MoneyTx> transactions = [];
  List<Goal> goals = [];
  List<Recurring> recurringTransactions = [];
  bool loading = true;
  String currency = '€';

  // ✅ MODIFICATO: Liste di default (possono essere modificate)
  List<String> expenseCats = [
    'Spesa',
    'Trasporti',
    'Svago',
    'Shopping',
    'Bollette',
    'Ricariche',
    'Casa',
    'Salute',
    'Sport',
    'Regali',
    'Viaggi',
    'Investimenti',
    'Altro'
  ];

  List<String> incomeCats = [
    'Stipendio',
    'Freelance',
    'Investimenti',
    'Regalo',
    'Rimborso',
    'Altro'
  ];

  final List<String> goalCategories = [
    'COMPUTER',
    'SMARTPHONE',
    'VIAGGIO',
    'AUTO',
    'CASA',
    'INVESTIMENTI',
    'ALTRO'
  ];

  List<String> customExpenseCats = [];
  List<String> customIncomeCats = [];
  Map<String, IconData> customCategoryIcons = {};
  Map<String, Color> customCategoryColors = {};

  List<String> _expenseCatsOrder = [];
  List<String> _incomeCatsOrder = [];

  List<String> get allExpenseCats {
    final all = [...expenseCats, ...customExpenseCats];
    if (_expenseCatsOrder.isEmpty) return all;
    final ordered = <String>[];
    for (final cat in _expenseCatsOrder) {
      if (all.contains(cat)) ordered.add(cat);
    }
    for (final cat in all) {
      if (!ordered.contains(cat)) ordered.add(cat);
    }
    return ordered;
  }

  List<String> get allIncomeCats {
    final all = [...incomeCats, ...customIncomeCats];
    if (_incomeCatsOrder.isEmpty) return all;
    final ordered = <String>[];
    for (final cat in _incomeCatsOrder) {
      if (all.contains(cat)) ordered.add(cat);
    }
    for (final cat in all) {
      if (!ordered.contains(cat)) ordered.add(cat);
    }
    return ordered;
  }

  double get netWorth => netBalance;

  Future<void> addCustomCategory(String name, IconData icon, bool isIncome,
      [Color? color]) async {
    if (isIncome) {
      if (!incomeCats.contains(name) && !customIncomeCats.contains(name)) {
        customIncomeCats.add(name);
        customCategoryIcons[name] = icon;
        if (color != null) customCategoryColors[name] = color;
        await _saveCustomCategories();
        notifyListeners();
      }
    } else {
      if (!expenseCats.contains(name) && !customExpenseCats.contains(name)) {
        customExpenseCats.add(name);
        customCategoryIcons[name] = icon;
        if (color != null) customCategoryColors[name] = color;
        await _saveCustomCategories();
        notifyListeners();
      }
    }
  }

  // ✅ MODIFICATA: Rinomina TUTTE le categorie (predefinite + custom)
  Future<void> renameCategory({
    required String oldName,
    required String newName,
    required bool isIncome,
  }) async {
    if (newName.trim().isEmpty || oldName == newName) return;
    final trimmedNew = newName.trim();

    if (isIncome) {
      // Rinomina in incomeCats (predefinite)
      final index = incomeCats.indexOf(oldName);
      if (index != -1) {
        incomeCats[index] = trimmedNew;
      }
      // Rinomina in customIncomeCats
      final customIndex = customIncomeCats.indexOf(oldName);
      if (customIndex != -1) {
        customIncomeCats[customIndex] = trimmedNew;
      }
      // Rinomina nell'ordine
      final orderIndex = _incomeCatsOrder.indexOf(oldName);
      if (orderIndex != -1) {
        _incomeCatsOrder[orderIndex] = trimmedNew;
      }
    } else {
      // Rinomina in expenseCats (predefinite)
      final index = expenseCats.indexOf(oldName);
      if (index != -1) {
        expenseCats[index] = trimmedNew;
      }
      // Rinomina in customExpenseCats
      final customIndex = customExpenseCats.indexOf(oldName);
      if (customIndex != -1) {
        customExpenseCats[customIndex] = trimmedNew;
      }
      // Rinomina nell'ordine
      final orderIndex = _expenseCatsOrder.indexOf(oldName);
      if (orderIndex != -1) {
        _expenseCatsOrder[orderIndex] = trimmedNew;
      }
    }

    // Sposta icona e colore
    if (customCategoryIcons.containsKey(oldName)) {
      customCategoryIcons[trimmedNew] = customCategoryIcons[oldName]!;
      customCategoryIcons.remove(oldName);
    }

    if (customCategoryColors.containsKey(oldName)) {
      customCategoryColors[trimmedNew] = customCategoryColors[oldName]!;
      customCategoryColors.remove(oldName);
    }

    await _repo.renameCategoryInTransactions(oldName, trimmedNew);
    await _repo.renameCategoryInRecurrings(oldName, trimmedNew);
    await loadInitial();
    await _saveCustomCategories();
    notifyListeners();
  }

  // ✅ MODIFICATA: Elimina TUTTE le categorie (predefinite + custom)
  Future<void> deleteCustomCategory(String name, bool isIncome) async {
    // Non permettere eliminazione di "Altro"
    if (name == 'Altro') {
      debugPrint('❌ Impossibile eliminare la categoria "Altro"');
      return;
    }

    if (isIncome) {
      incomeCats.remove(name);
      customIncomeCats.remove(name);
      _incomeCatsOrder.remove(name);
    } else {
      expenseCats.remove(name);
      customExpenseCats.remove(name);
      _expenseCatsOrder.remove(name);
    }

    customCategoryIcons.remove(name);
    customCategoryColors.remove(name);
    
    await _repo.renameCategoryInTransactions(name, 'Altro');
    await _repo.renameCategoryInRecurrings(name, 'Altro');
    await loadInitial();
    await _saveCustomCategories();
    notifyListeners();
  }

  Future<void> reorderCategories(List<String> newOrder, bool isIncome) async {
    if (isIncome) {
      _incomeCatsOrder = newOrder;
    } else {
      _expenseCatsOrder = newOrder;
    }

    await _saveCustomCategories();
    notifyListeners();
  }

  Future<void> updateCategoryStyle({
    required String categoryName,
    IconData? icon,
    Color? color,
  }) async {
    if (icon != null) {
      customCategoryIcons[categoryName] = icon;
    }

    if (color != null) {
      customCategoryColors[categoryName] = color;
    }

    await _saveCustomCategories();
    notifyListeners();
  }

  Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ SALVATO: Liste predefinite modificate
    await prefs.setString('expenseCats', jsonEncode(expenseCats));
    await prefs.setString('incomeCats', jsonEncode(incomeCats));
    
    await prefs.setString('customExpenseCats', jsonEncode(customExpenseCats));
    await prefs.setString('customIncomeCats', jsonEncode(customIncomeCats));

    final iconsMap = customCategoryIcons.map(
      (key, value) => MapEntry(key, value.codePoint),
    );
    await prefs.setString('customCategoryIcons', jsonEncode(iconsMap));

    final colorsMap = customCategoryColors.map(
      (key, value) => MapEntry(key, value.value),
    );
    await prefs.setString('customCategoryColors', jsonEncode(colorsMap));

    await prefs.setString('expenseCatsOrder', jsonEncode(_expenseCatsOrder));
    await prefs.setString('incomeCatsOrder', jsonEncode(_incomeCatsOrder));
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ CARICATO: Liste predefinite modificate
    final expenseJson = prefs.getString('expenseCats');
    if (expenseJson != null) {
      expenseCats = List<String>.from(jsonDecode(expenseJson));
    }

    final incomeJson = prefs.getString('incomeCats');
    if (incomeJson != null) {
      incomeCats = List<String>.from(jsonDecode(incomeJson));
    }

    final customExpenseJson = prefs.getString('customExpenseCats');
    if (customExpenseJson != null) {
      customExpenseCats = List<String>.from(jsonDecode(customExpenseJson));
    }

    final customIncomeJson = prefs.getString('customIncomeCats');
    if (customIncomeJson != null) {
      customIncomeCats = List<String>.from(jsonDecode(customIncomeJson));
    }

    final iconsJson = prefs.getString('customCategoryIcons');
    if (iconsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(iconsJson);
      customCategoryIcons = decoded.map(
        (key, value) =>
            MapEntry(key, IconData(value, fontFamily: 'MaterialIcons')),
      );
    }

    final colorsJson = prefs.getString('customCategoryColors');
    if (colorsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(colorsJson);
      customCategoryColors = decoded.map(
        (key, value) => MapEntry(key, Color(value)),
      );
    }

    final expenseOrderJson = prefs.getString('expenseCatsOrder');
    if (expenseOrderJson != null) {
      _expenseCatsOrder = List<String>.from(jsonDecode(expenseOrderJson));
    }

    final incomeOrderJson = prefs.getString('incomeCatsOrder');
    if (incomeOrderJson != null) {
      _incomeCatsOrder = List<String>.from(jsonDecode(incomeOrderJson));
    }
  }

  List<MoneyTx> get recent => transactions.take(20).toList();
  List<Goal> get activeGoals => goals.where((g) => !g.isPurchased).toList();
  List<Goal> get completedGoals => goals.where((g) => g.isPurchased).toList();

  Future<void> processRecurringTransactions() async {
    final now = DateTime.now();
    bool hasNewTransactions = false;

    for (var recurring in recurringTransactions) {
      if (recurring.dayOfMonth == now.day) {
        if (recurring.lastProcessed != null) {
          final lastProcessedDay = DateTime(
            recurring.lastProcessed!.year,
            recurring.lastProcessed!.month,
            recurring.lastProcessed!.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          if (lastProcessedDay.isAtSameMomentAs(today)) {
            continue;
          }
        }

        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          recurring.time.hour,
          recurring.time.minute,
        );

        if (now.isAfter(scheduledTime) || now.isAtSameMomentAs(scheduledTime)) {
          final automaticTx = MoneyTx(
            id: null,
            isIncome: recurring.isIncome,
            category: recurring.category,
            amount: recurring.amount,
            date: now,
            note: recurring.note,
            payment: recurring.payment,
          );

          await _repo.insertTx(automaticTx);

          final updatedRecurring = Recurring(
            id: recurring.id,
            isIncome: recurring.isIncome,
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
          debugPrint(
              '✅ Transazione ricorrente creata: ${recurring.category} - €${recurring.amount}');
        }
      }
    }

    if (hasNewTransactions) {
      await loadInitial();
      debugPrint('🔄 Transazioni ricorrenti aggiornate');
    }
  }

  Future<void> resetAllData() async {
    loading = true;
    notifyListeners();
    try {
      await _repo.resetDatabase();
      transactions.clear();
      goals.clear();
      recurringTransactions.clear();
      customExpenseCats.clear();
      customIncomeCats.clear();
      customCategoryIcons.clear();
      customCategoryColors.clear();
      _expenseCatsOrder.clear();
      _incomeCatsOrder.clear();
      
      // ✅ RESET: Ripristina categorie predefinite originali
      expenseCats = [
        'Spesa',
        'Trasporti',
        'Svago',
        'Shopping',
        'Bollette',
        'Ricariche',
        'Casa',
        'Salute',
        'Sport',
        'Regali',
        'Viaggi',
        'Investimenti',
        'Altro'
      ];
      
      incomeCats = [
        'Stipendio',
        'Freelance',
        'Investimenti',
        'Regalo',
        'Rimborso',
        'Altro'
      ];

      await _saveCustomCategories();
      loading = false;
      notifyListeners();
      debugPrint('✅ Reset completo effettuato con successo');
    } catch (e) {
      loading = false;
      notifyListeners();
      debugPrint('❌ Errore durante il reset: $e');
      rethrow;
    }
  }

  // ... [Il resto del codice rimane identico: getRecurringTransactionsForPeriod, netBalance, ecc.]
  
  List<MoneyTx> getRecurringTransactionsForPeriod(DateTime start, DateTime end) {
    final List<MoneyTx> generatedTxs = [];
    final now = DateTime.now();

    for (var recurring in recurringTransactions) {
      DateTime firstValidMonth;
      if (recurring.dayOfMonth >= now.day) {
        firstValidMonth = DateTime(now.year, now.month, 1);
      } else {
        firstValidMonth = DateTime(now.year, now.month + 1, 1);
      }

      if (firstValidMonth.isBefore(DateTime(start.year, start.month, 1))) {
        firstValidMonth = DateTime(start.year, start.month, 1);
      }

      DateTime currentMonth = firstValidMonth;
      while (currentMonth.isBefore(end) ||
          (currentMonth.month == end.month && currentMonth.year == end.year)) {
        final recurringDate = DateTime(
          currentMonth.year,
          currentMonth.month,
          recurring.dayOfMonth > 28 ? 28 : recurring.dayOfMonth,
          recurring.time.hour,
          recurring.time.minute,
        );

        if (recurringDate.isAfter(start.subtract(const Duration(days: 1))) &&
            recurringDate.isBefore(end)) {
          final alreadyExists = generatedTxs.any((tx) =>
              tx.category == recurring.category &&
              tx.amount == recurring.amount &&
              tx.date.year == recurringDate.year &&
              tx.date.month == recurringDate.month &&
              tx.date.day == recurringDate.day);

          if (!alreadyExists) {
            generatedTxs.add(MoneyTx(
              id: null,
              isIncome: recurring.isIncome,
              category: recurring.category,
              amount: recurring.amount,
              date: recurringDate,
              note: recurring.note,
              payment: recurring.payment,
              isFromRecurring: true,
            ));
          }
        }

        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
        if (currentMonth.year > DateTime.now().year + 10) break;
      }
    }

    return generatedTxs;
  }

  double get netBalance {
    return transactions.fold(0.0, (sum, tx) {
      return sum + (tx.isIncome ? tx.amount : -tx.amount);
    });
  }

  double get availableBalance {
    final totalSaved = goals
        .where((g) => !g.isPurchased)
        .fold(0.0, (sum, g) => sum + g.saved);
    return netBalance - totalSaved;
  }

  double get monthlyIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final thisMonth = transactions.where((tx) {
      return tx.isIncome &&
          tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
          tx.date.isBefore(end);
    });
    return thisMonth.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final thisMonth = transactions.where((tx) {
      return !tx.isIncome &&
          tx.date.isAfter(start.subtract(const Duration(days: 1))) &&
          tx.date.isBefore(end);
    });
    return thisMonth.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  String format(double amount) => '${amount.toStringAsFixed(2)} $currency';

  CategoryStyle getTransactionStyle(String category) {
    if (customCategoryIcons.containsKey(category)) {
      final color = customCategoryColors[category] ?? const Color(0xFF6366F1);
      return CategoryStyle(customCategoryIcons[category]!, color);
    }

    final Map<String, CategoryStyle> styles = {
      'Spesa': CategoryStyle(Icons.shopping_cart, const Color(0xFF10B981)),
      'Trasporti': CategoryStyle(Icons.directions_car, const Color(0xFF3B82F6)),
      'Svago': CategoryStyle(Icons.restaurant, const Color(0xFFF59E0B)),
      'Shopping': CategoryStyle(Icons.shopping_bag, const Color(0xFFEC4899)),
      'Bollette': CategoryStyle(Icons.receipt_long, const Color(0xFFEF4444)),
      'Ricariche': CategoryStyle(Icons.smartphone, const Color(0xFF6366F1)),
      'Casa': CategoryStyle(Icons.home, const Color(0xFF8B5CF6)),
      'Salute': CategoryStyle(Icons.medical_services, const Color(0xFF06B6D4)),
      'Sport': CategoryStyle(Icons.fitness_center, const Color(0xFF84CC16)),
      'Regali': CategoryStyle(Icons.card_giftcard, const Color(0xFFF97316)),
      'Viaggi': CategoryStyle(Icons.flight, const Color(0xFF14B8A6)),
      'Investimenti': CategoryStyle(Icons.trending_up, const Color(0xFF8B5CF6)),
      'Altro': CategoryStyle(Icons.more_horiz, const Color(0xFF6B7280)),
      'Stipendio': CategoryStyle(Icons.work, const Color(0xFF10B981)),
      'Freelance': CategoryStyle(Icons.laptop_mac, const Color(0xFF6366F1)),
      'Regalo': CategoryStyle(Icons.card_giftcard, const Color(0xFFF59E0B)),
      'Rimborso': CategoryStyle(Icons.undo, const Color(0xFF22C55E)),
    };

    return styles[category] ??
        CategoryStyle(Icons.help_outline, const Color(0xFF6B7280));
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

    return styles[title] ??
        CategoryStyle(Icons.flag, const Color(0xFF6366F1));
  }

  Future<void> loadInitial() async {
    loading = true;
    notifyListeners();
    transactions = await _repo.getAllTx();
    goals = await _repo.getAllGoals();
    recurringTransactions = await _repo.getRecurring();
    await _loadCustomCategories();
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

  Future<void> purchaseGoal(int goalId, String selectedCategory) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    if (netBalance < goal.target) {
      throw Exception(
          'Saldo insufficiente! Hai solo €${netBalance.toStringAsFixed(2)}, servono €${goal.target.toStringAsFixed(2)}');
    }

    final tx = MoneyTx(
      id: null,
      isIncome: false,
      category: selectedCategory,
      amount: goal.target,
      date: DateTime.now(),
      note: 'Acquisto obiettivo: ${goal.title}',
      payment: PaymentMethod.carta,
    );

    await addTx(tx);

    final updated = goal.copyWith(isPurchased: true);
    await _repo.updateGoal(updated);
    await loadInitial();
  }

  Future<void> unpurchaseGoal(int goalId) async {
    final goal = goals.firstWhere((g) => g.id == goalId);
    final purchaseTxs = transactions
        .where((tx) =>
            tx.note?.contains('Acquisto obiettivo: ${goal.title}') == true &&
            !tx.isIncome)
        .toList();

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

  Future<void> addMoneyToGoal(Goal goal, double amount) async {
    if (availableBalance < amount) {
      throw Exception(
          'Saldo disponibile insufficiente! Hai €${availableBalance.toStringAsFixed(2)} disponibili');
    }

    final updatedGoal = goal.copyWith(saved: goal.saved + amount);
    await updateGoal(updatedGoal);
  }

  Future<void> completeGoal(Goal goal) async {
    final completedGoal = goal.copyWith(isPurchased: true);
    await updateGoal(completedGoal);
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
    debugPrint('🗑️ Ricorrenza eliminata (transazioni passate conservate)');
  }

  // ... [CSV/Excel/MMBackup import rimangono identici]
  
  Future<Map<String, int>> importFromCSV(
      String csvContent, Map<String, String> categoryMapping) async {
    final normalized = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('', '');
    final lines = normalized.split('\n');

    if (lines.isEmpty) return {'imported': 0, 'skipped': 0};

    int headerIndex = 0;
    while (headerIndex < lines.length &&
        !lines[headerIndex].toLowerCase().contains('data')) {
      headerIndex++;
    }

    if (headerIndex >= lines.length) return {'imported': 0, 'skipped': lines.length};

    int imported = 0, skipped = 0;

    for (int i = headerIndex + 1; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) {
        skipped++;
        continue;
      }

      try {
        final tx = parseCSVLineTolerant(raw, categoryMapping);
        if (tx != null) {
          await _repo.insertTx(tx);
          imported++;
        } else {
          skipped++;
        }
      } catch (_) {
        skipped++;
      }
    }

    await loadInitial();
    return {'imported': imported, 'skipped': skipped};
  }

  MoneyTx? parseCSVLineTolerant(
      String line, Map<String, String> categoryMapping) {
    final s = line.replaceAll('"', '');
    final fields = parseCSVFields(s);

    if (fields.length < 3) return null;

    while (fields.length < 5) {
      fields.add('');
    }

    try {
      DateTime date;
      try {
        date = DateTime.parse(fields[0]);
      } catch (_) {
        final parts = fields[0].split('/');
        if (parts.length == 3) {
          date = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return null;
        }
      }

      final rawCategory = fields[1].trim();
      final category =
          categoryMapping[rawCategory] ?? mapCommonCategory(rawCategory);

      final amountStr = fields[2]
          .replaceAll('€', '')
          .replaceAll(' ', '')
          .replaceAll(',', '.');
      final amountParsed = double.tryParse(amountStr);
      if (amountParsed == null) return null;

      double amount = amountParsed.abs();

      final typeField = fields.length > 4 ? fields[4] : '';
      final lowerType = typeField.toLowerCase();
      final isIncome = lowerType.contains('entrata') ||
          lowerType.contains('income') ||
          lowerType.contains('+');

      return MoneyTx(
        isIncome: isIncome,
        category: category,
        amount: amount,
        date: date,
        note: fields[3].trim().isEmpty ? null : fields[3].trim(),
        payment: PaymentMethod.carta,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> parseCSVFields(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    String current = '';

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        fields.add(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }

    fields.add(current.trim());
    return fields;
  }

  String mapCommonCategory(String rawCategory) {
    final mappings = {
      'Alimentari': 'Spesa',
      'Auto': 'Trasporti',
      'Svago': 'Svago',
      'Ristoranti': 'Svago',
      'Attività fisica': 'Sport',
      'PAC': 'Investimenti',
      'Ricarica': 'Ricariche',
      'Telefono': 'Ricariche',
      'Internet': 'Bollette',
      'Luce': 'Bollette',
      'Gas': 'Bollette',
      'Acqua': 'Bollette',
      'Caffè': 'Svago',
      'Abbigliamento': 'Shopping',
      'Rimborso': 'Rimborso',
      'Regalo': 'Regalo',
      'Stipendio': 'Stipendio',
    };

    return mappings[rawCategory] ?? rawCategory;
  }

  Set<String> getUnrecognizedCategories(String csvContent) {
    final unrecognized = <String>{};
    final normalized = csvContent.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    final startIndex = lines[0].toLowerCase().contains('data') ? 1 : 0;

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = parseCSVFields(line);
      if (fields.length > 2) {
        final rawCategory = fields[1].trim();
        if (rawCategory.isNotEmpty) {
          final mappedCategory = mapCommonCategory(rawCategory);
          if (!expenseCats.contains(mappedCategory) &&
              !incomeCats.contains(mappedCategory)) {
            unrecognized.add(rawCategory);
          }
        }
      }
    }

    return unrecognized;
  }

  Future<Map<String, int>> importFromExcel(
      Uint8List fileBytes, Map<String, String> categoryMapping) async {
    try {
      final excel = Excel.decodeBytes(fileBytes);
      int totalImported = 0;

      for (var tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null) continue;

        bool isExpenseSheet = tableName.toLowerCase().contains('spese');
        bool isIncomeSheet = tableName.toLowerCase().contains('entrate');
        bool isTransferSheet = tableName.toLowerCase().contains('bonifici');

        if (isExpenseSheet || isIncomeSheet) {
          totalImported +=
              await processStandardSheet(sheet, isIncomeSheet, categoryMapping);
        } else if (isTransferSheet) {
          totalImported += await processTransferSheet(sheet, categoryMapping);
        }
      }

      await loadInitial();
      debugPrint('✅ Importate $totalImported transazioni da Excel');
      return {'imported': totalImported, 'skipped': 0};
    } catch (e) {
      debugPrint('❌ Errore importazione Excel: $e');
      rethrow;
    }
  }

  Future<int> processStandardSheet(
      Sheet sheet, bool isIncome, Map<String, String> categoryMapping) async {
    int imported = 0;

    if (sheet.rows.isEmpty) return 0;

    final headerRow = sheet.rows.first;
    int? dateCol, categoryCol, amountCol, noteCol;

    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value == null) continue;

      final header = cell!.value.toString().toLowerCase();
      if (header.contains('data')) dateCol = i;
      if (header.contains('categoria')) categoryCol = i;
      if (header.contains('importo')) amountCol = i;
      if (header.contains('commento') || header.contains('nota')) noteCol = i;
    }

    if (dateCol == null || categoryCol == null || amountCol == null) return 0;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      try {
        final dateCell = dateCol < row.length ? row[dateCol]?.value : null;
        final categoryCell =
            categoryCol < row.length ? row[categoryCol]?.value : null;
        final amountCell =
            amountCol < row.length ? row[amountCol]?.value : null;
        final noteCell =
            noteCol != null && noteCol < row.length ? row[noteCol]?.value : null;

        if (dateCell == null || categoryCell == null || amountCell == null)
          continue;

        DateTime date;
        final dateStr = dateCell.toString();
        if (dateStr.contains(' ')) {
          date = DateTime.parse(dateStr.split(' ')[0]);
        } else {
          date = DateTime.parse(dateStr);
        }

        final rawCategory = categoryCell.toString().trim();
        final category =
            categoryMapping[rawCategory] ?? mapCommonCategory(rawCategory);

        double amount =
            double.parse(amountCell.toString().replaceAll(',', '.'));

        final tx = MoneyTx(
          isIncome: isIncome,
          category: category,
          amount: amount,
          date: date,
          note: noteCell?.toString(),
          payment: PaymentMethod.carta,
        );

        await _repo.insertTx(tx);
        imported++;
      } catch (e) {
        debugPrint('❌ Errore parsing riga $i: $e');
      }
    }

    return imported;
  }

  Future<int> processTransferSheet(
      Sheet sheet, Map<String, String> categoryMapping) async {
    int imported = 0;

    if (sheet.rows.isEmpty) return 0;

    final headerRow = sheet.rows.first;
    int? dateCol, outCol, inCol, outAmountCol, inAmountCol, noteCol;

    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value == null) continue;

      final header = cell!.value.toString().toLowerCase();
      if (header.contains('data')) dateCol = i;
      if (header.contains('uscita') && !header.contains('importo')) outCol = i;
      if (header.contains('entrata') && !header.contains('importo')) inCol = i;
      if (header.contains('importo') && header.contains('uscita'))
        outAmountCol = i;
      if (header.contains('importo') && header.contains('entrata'))
        inAmountCol = i;
      if (header.contains('commento') || header.contains('nota')) noteCol = i;
    }

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      try {
        final dateCell =
            dateCol != null && dateCol < row.length ? row[dateCol]?.value : null;
        final outCell =
            outCol != null && outCol < row.length ? row[outCol]?.value : null;
        final inCell =
            inCol != null && inCol < row.length ? row[inCol]?.value : null;
        final outAmountCell = outAmountCol != null && outAmountCol < row.length
            ? row[outAmountCol]?.value
            : null;
        final inAmountCell = inAmountCol != null && inAmountCol < row.length
            ? row[inAmountCol]?.value
            : null;
        final noteCell =
            noteCol != null && noteCol < row.length ? row[noteCol]?.value : null;

        if (dateCell == null) continue;

        DateTime date = DateTime.parse(dateCell.toString().split(' ')[0]);

        if (outCell != null && outAmountCell != null) {
          final rawCategory = outCell.toString().trim();
          final category =
              categoryMapping[rawCategory] ?? mapCommonCategory(rawCategory);

          final tx = MoneyTx(
            isIncome: false,
            category: category,
            amount: double.parse(outAmountCell.toString().replaceAll(',', '.')),
            date: date,
            note: noteCell?.toString(),
            payment: PaymentMethod.carta,
          );

          await _repo.insertTx(tx);
          imported++;
        }

        if (inCell != null && inAmountCell != null) {
          final rawCategory = inCell.toString().trim();
          final category =
              categoryMapping[rawCategory] ?? mapCommonCategory(rawCategory);

          final tx = MoneyTx(
            isIncome: true,
            category: category,
            amount: double.parse(inAmountCell.toString().replaceAll(',', '.')),
            date: date,
            note: noteCell?.toString(),
            payment: PaymentMethod.carta,
          );

          await _repo.insertTx(tx);
          imported++;
        }
      } catch (e) {
        debugPrint('❌ Errore parsing bonifico riga $i: $e');
      }
    }

    return imported;
  }

  Set<String> getUnrecognizedCategoriesFromExcel(Uint8List fileBytes) {
    final unrecognized = <String>{};
    try {
      final excel = Excel.decodeBytes(fileBytes);

      for (var tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        final headerRow = sheet.rows.first;
        int? categoryCol;

        for (int i = 0; i < headerRow.length; i++) {
          final cell = headerRow[i];
          if (cell?.value == null) continue;

          final header = cell!.value.toString().toLowerCase();
          if (header.contains('categoria')) {
            categoryCol = i;
            break;
          }
        }

        if (categoryCol == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length <= categoryCol) continue;

          final categoryCell = row[categoryCol]?.value?.toString()?.trim();
          if (categoryCell != null && categoryCell.isNotEmpty) {
            final mappedCategory = mapCommonCategory(categoryCell);
            if (!expenseCats.contains(mappedCategory) &&
                !incomeCats.contains(mappedCategory)) {
              unrecognized.add(categoryCell);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Errore analisi categorie Excel: $e');
    }

    return unrecognized;
  }

  Future<Map<String, int>> importFromMMBackup(
      String jsonContent, Map<String, String> categoryMapping) async {
    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      int imported = 0;

      final transactions = (data['transactions'] as List?) ?? [];
      for (final txData in transactions) {
        try {
          final tx = parseMMBackupTransaction(txData, categoryMapping);
          if (tx != null) {
            await _repo.insertTx(tx);
            imported++;
          }
        } catch (e) {
          debugPrint('❌ Errore parsing transazione MMBackup: $e');
        }
      }

      await loadInitial();
      debugPrint('✅ Importate $imported transazioni da MMBackup');
      return {'imported': imported, 'skipped': 0};
    } catch (e) {
      debugPrint('❌ Errore importazione MMBackup: $e');
      rethrow;
    }
  }

  MoneyTx? parseMMBackupTransaction(
      Map<String, dynamic> txData, Map<String, String> categoryMapping) {
    try {
      final amount = double.parse(txData['amount']?.toString() ?? '0');
      if (amount == 0) return null;

      final rawCategory = txData['category']?.toString() ?? 'Altro';
      final category =
          categoryMapping[rawCategory] ?? mapCommonCategory(rawCategory);

      final date = DateTime.fromMillisecondsSinceEpoch(txData['date'] ?? 0);
      final note = txData['note']?.toString();
      final isIncome =
          (txData['type']?.toString() ?? '').toLowerCase() == 'income';

      return MoneyTx(
        isIncome: isIncome,
        category: category,
        amount: amount.abs(),
        date: date,
        note: note,
        payment: PaymentMethod.carta,
      );
    } catch (e) {
      return null;
    }
  }

  Set<String> getUnrecognizedCategoriesFromMMBackup(String jsonContent) {
    final unrecognized = <String>{};
    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final transactions = (data['transactions'] as List?) ?? [];

      for (final txData in transactions) {
        final rawCategory = txData['category']?.toString()?.trim();
        if (rawCategory != null && rawCategory.isNotEmpty) {
          final mappedCategory = mapCommonCategory(rawCategory);
          if (!expenseCats.contains(mappedCategory) &&
              !incomeCats.contains(mappedCategory)) {
            unrecognized.add(rawCategory);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Errore analisi categorie MMBackup: $e');
    }

    return unrecognized;
  }
}
