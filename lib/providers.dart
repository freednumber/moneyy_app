import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
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

  // ✅ NUOVO: Reset completo di tutti i dati
  Future<void> resetAllData() async {
    loading = true;
    notifyListeners();
    
    try {
      await _repo.resetDatabase();
      
      // Pulisci le liste locali
      transactions.clear();
      goals.clear();
      recurringTransactions.clear();
      
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

  // ✅ NUOVO: Importa transazioni da CSV
  Future<void> importFromCSV(String csvContent, Map<String, String> categoryMapping) async {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return;
    
    // Salta l'header se presente
    final startIndex = lines[0].toLowerCase().contains('data') ? 1 : 0;
    
    int imported = 0;
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      try {
        final tx = _parseCSVLine(line, categoryMapping);
        if (tx != null) {
          await _repo.insertTx(tx);
          imported++;
        }
      } catch (e) {
        debugPrint('Errore parsing linea $i: $e');
      }
    }
    
    await loadInitial();
    debugPrint('✅ Importate $imported transazioni da CSV');
  }

  // ✅ NUOVO: Importa da file Excel (.xlsx)
  Future<void> importFromExcel(Uint8List fileBytes, Map<String, String> categoryMapping) async {
    try {
      final excel = Excel.decodeBytes(fileBytes);
      int totalImported = 0;
      
      for (var tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName]!;
        
        // Analizza il nome del foglio per determinare il tipo
        bool isExpenseSheet = tableName.toLowerCase().contains('spese');
        bool isIncomeSheet = tableName.toLowerCase().contains('entrate');
        bool isTransferSheet = tableName.toLowerCase().contains('bonifici');
        
        debugPrint('📄 Elaborando foglio: $tableName');
        
        if (isExpenseSheet || isIncomeSheet) {
          totalImported += await _processStandardSheet(sheet, !isExpenseSheet, categoryMapping);
        } else if (isTransferSheet) {
          totalImported += await _processTransferSheet(sheet, categoryMapping);
        }
      }
      
      await loadInitial();
      debugPrint('✅ Importate $totalImported transazioni da Excel');
    } catch (e) {
      debugPrint('❌ Errore importazione Excel: $e');
      rethrow;
    }
  }

  // ✅ NUOVO: Processa fogli Spese/Entrate
  Future<int> _processStandardSheet(Sheet sheet, bool isIncome, Map<String, String> categoryMapping) async {
    int imported = 0;
    
    // Trova le colonne (header sulla riga 1)
    final headerRow = sheet.rows.first;
    int? dateCol, categoryCol, amountCol, noteCol;
    
    for (int i = 0; i < headerRow.length; i++) {
      final header = headerRow[i]?.value?.toString()?.toLowerCase() ?? '';
      if (header.contains('data')) dateCol = i;
      if (header.contains('categoria')) categoryCol = i;
      if (header.contains('importo') && header.contains('predefinita')) amountCol = i;
      if (header.contains('commento')) noteCol = i;
    }
    
    if (dateCol == null || categoryCol == null || amountCol == null) {
      debugPrint('⚠️ Colonne non trovate nel foglio');
      return 0;
    }
    
    // Processa le righe dati (salta header)
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      
      try {
        final dateCell = row[dateCol]?.value;
        final categoryCell = row[categoryCol]?.value;
        final amountCell = row[amountCol]?.value;
        final noteCell = noteCol != null ? row[noteCol]?.value : null;
        
        if (dateCell == null || categoryCell == null || amountCell == null) continue;
        
        // Parse data (formato "2025-10-16 000000")
        DateTime date;
        final dateStr = dateCell.toString();
        if (dateStr.contains(' ')) {
          date = DateTime.parse(dateStr.split(' ')[0]);
        } else {
          date = DateTime.parse(dateStr);
        }
        
        // Parse categoria con mapping
        final rawCategory = categoryCell.toString().trim();
        final category = categoryMapping[rawCategory] ?? rawCategory;
        
        // Parse importo
        double amount = double.parse(amountCell.toString());
        
        // Crea transazione
        final tx = MoneyTx(
          isIncome: isIncome,
          category: category,
          amount: amount,
          date: date,
          note: noteCell?.toString(),
          payment: PaymentMethod.carta, // Default
        );
        
        await _repo.insertTx(tx);
        imported++;
      } catch (e) {
        debugPrint('Errore parsing riga $i: $e');
      }
    }
    
    return imported;
  }

  // ✅ NUOVO: Processa foglio Bonifici
  Future<int> _processTransferSheet(Sheet sheet, Map<String, String> categoryMapping) async {
    int imported = 0;
    
    // Trova le colonne
    final headerRow = sheet.rows.first;
    int? dateCol, outCol, inCol, outAmountCol, inAmountCol, noteCol;
    
    for (int i = 0; i < headerRow.length; i++) {
      final header = headerRow[i]?.value?.toString()?.toLowerCase() ?? '';
      if (header.contains('data')) dateCol = i;
      if (header.contains('uscita') && !header.contains('importo')) outCol = i;
      if (header.contains('entrata') && !header.contains('importo')) inCol = i;
      if (header.contains('importo') && header.contains('uscita')) outAmountCol = i;
      if (header.contains('importo') && header.contains('entrata')) inAmountCol = i;
      if (header.contains('commento')) noteCol = i;
    }
    
    // Processa righe
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;
      
      try {
        final dateCell = row[dateCol!]?.value;
        final outCell = outCol != null ? row[outCol]?.value : null;
        final inCell = inCol != null ? row[inCol]?.value : null;
        final outAmountCell = outAmountCol != null ? row[outAmountCol]?.value : null;
        final inAmountCell = inAmountCol != null ? row[inAmountCol]?.value : null;
        final noteCell = noteCol != null ? row[noteCol]?.value : null;
        
        if (dateCell == null) continue;
        
        DateTime date = DateTime.parse(dateCell.toString().split(' ')[0]);
        
        // Crea uscita se presente
        if (outCell != null && outAmountCell != null) {
          final category = categoryMapping[outCell.toString()] ?? 'Trasferimento';
          final tx = MoneyTx(
            isIncome: false,
            category: category,
            amount: double.parse(outAmountCell.toString()),
            date: date,
            note: noteCell?.toString(),
            payment: PaymentMethod.bonifico,
          );
          await _repo.insertTx(tx);
          imported++;
        }
        
        // Crea entrata se presente
        if (inCell != null && inAmountCell != null) {
          final category = categoryMapping[inCell.toString()] ?? 'Trasferimento';
          final tx = MoneyTx(
            isIncome: true,
            category: category,
            amount: double.parse(inAmountCell.toString()),
            date: date,
            note: noteCell?.toString(),
            payment: PaymentMethod.bonifico,
          );
          await _repo.insertTx(tx);
          imported++;
        }
      } catch (e) {
        debugPrint('Errore parsing bonifico riga $i: $e');
      }
    }
    
    return imported;
  }

  // ✅ NUOVO: Importa da MMBackup (.mmbackup - JSON)
  Future<void> importFromMMBackup(String jsonContent, Map<String, String> categoryMapping) async {
    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      int imported = 0;
      
      // Struttura tipica MMBackup
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      
      for (final txData in transactions) {
        try {
          final tx = _parseMMBackupTransaction(txData, categoryMapping);
          if (tx != null) {
            await _repo.insertTx(tx);
            imported++;
          }
        } catch (e) {
          debugPrint('Errore parsing transazione MMBackup: $e');
        }
      }
      
      await loadInitial();
      debugPrint('✅ Importate $imported transazioni da MMBackup');
    } catch (e) {
      debugPrint('❌ Errore importazione MMBackup: $e');
      rethrow;
    }
  }

  // ✅ NUOVO: Parser transazione MMBackup
  MoneyTx? _parseMMBackupTransaction(Map<String, dynamic> txData, Map<String, String> categoryMapping) {
    try {
      final amount = double.parse(txData['amount']?.toString() ?? '0');
      if (amount == 0) return null;
      
      final rawCategory = txData['category']?.toString() ?? 'Altro';
      final category = categoryMapping[rawCategory] ?? rawCategory;
      
      final date = DateTime.fromMillisecondsSinceEpoch(txData['date'] ?? 0);
      final note = txData['note']?.toString();
      final isIncome = (txData['type']?.toString() ?? '').toLowerCase() == 'income';
      
      return MoneyTx(
        isIncome: isIncome,
        category: category,
        amount: amount.abs(),
        date: date,
        note: note,
        payment: PaymentMethod.carta, // Default
      );
    } catch (e) {
      debugPrint('Errore parsing singola transazione: $e');
      return null;
    }
  }

  // ✅ NUOVO: Parser CSV line
  MoneyTx? _parseCSVLine(String line, Map<String, String> categoryMapping) {
    final fields = _parseCSVFields(line);
    if (fields.length < 4) return null;
    
    try {
      DateTime date;
      double amount;
      String category;
      bool isIncome;
      String? note;
      
      // Prova diversi formati di data
      try {
        date = DateTime.parse(fields[0]);
      } catch (_) {
        // Prova formato italiano
        final parts = fields[0].split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return null;
        }
      }
      
      // Categoria con mapping
      final rawCategory = fields[1].trim();
      category = categoryMapping[rawCategory] ?? rawCategory;
      
      // Amount (gestisce virgola e punto)
      amount = double.parse(fields[2].replaceAll(',', '.'));
      
      // Tipo (prova diversi formati)
      final typeField = fields.length > 4 ? fields[4].toLowerCase().trim() : '';
      if (typeField.contains('entrata') || typeField.contains('income') || typeField.contains('+'  ) || amount > 0) {
        isIncome = true;
        amount = amount.abs();
      } else {
        isIncome = false;
        amount = amount.abs();
      }
      
      // Nota
      note = fields.length > 3 && fields[3].trim().isNotEmpty ? fields[3].trim() : null;
      
      return MoneyTx(
        isIncome: isIncome,
        category: category,
        amount: amount,
        date: date,
        note: note,
        payment: PaymentMethod.carta, // Default
      );
    } catch (e) {
      debugPrint('Errore parsing: $e');
      return null;
    }
  }

  // ✅ NUOVO: Parser CSV semplice
  List<String> _parseCSVFields(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    fields.add(currentField.trim());
    return fields;
  }

  // ✅ NUOVO: Ottieni categorie non riconosciute da Excel
  Set<String> getUnrecognizedCategoriesFromExcel(Uint8List fileBytes) {
    final unrecognized = <String>{};
    
    try {
      final excel = Excel.decodeBytes(fileBytes);
      
      for (var tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName]!;
        
        // Trova colonna categoria
        final headerRow = sheet.rows.first;
        int? categoryCol;
        
        for (int i = 0; i < headerRow.length; i++) {
          final header = headerRow[i]?.value?.toString()?.toLowerCase() ?? '';
          if (header.contains('categoria')) {
            categoryCol = i;
            break;
          }
        }
        
        if (categoryCol == null) continue;
        
        // Estrai categorie
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length <= categoryCol) continue;
          
          final categoryCell = row[categoryCol]?.value?.toString()?.trim();
          if (categoryCell != null && categoryCell.isNotEmpty) {
            if (!expenseCats.contains(categoryCell) && 
                !incomeCats.contains(categoryCell)) {
              unrecognized.add(categoryCell);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Errore analisi categorie Excel: $e');
    }
    
    return unrecognized;
  }

  // ✅ NUOVO: Ottieni categorie non riconosciute da MMBackup
  Set<String> getUnrecognizedCategoriesFromMMBackup(String jsonContent) {
    final unrecognized = <String>{};
    
    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      
      for (final txData in transactions) {
        final category = txData['category']?.toString()?.trim();
        if (category != null && category.isNotEmpty) {
          if (!expenseCats.contains(category) && 
              !incomeCats.contains(category)) {
            unrecognized.add(category);
          }
        }
      }
    } catch (e) {
      debugPrint('Errore analisi categorie MMBackup: $e');
    }
    
    return unrecognized;
  }

  // ✅ NUOVO: Ottieni categorie non riconosciute dal CSV
  Set<String> getUnrecognizedCategories(String csvContent) {
    final unrecognized = <String>{};
    final lines = csvContent.split('\n');
    final startIndex = lines[0].toLowerCase().contains('data') ? 1 : 0;
    
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final fields = _parseCSVFields(line);
      if (fields.length >= 2) {
        final category = fields[1].trim();
        if (category.isNotEmpty && 
            !expenseCats.contains(category) && 
            !incomeCats.contains(category)) {
          unrecognized.add(category);
        }
      }
    }
    
    return unrecognized;
  }
}

class CategoryStyle {
  final IconData icon;
  final Color color;
  CategoryStyle(this.icon, this.color);
}
