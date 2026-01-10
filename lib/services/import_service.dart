import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class ImportService {
  
  // ==========================================
  // 📄 SEZIONE CSV
  // ==========================================

  /// Analizza una stringa CSV e restituisce una lista di transazioni pronte per essere salvate.
  static List<MoneyTx> parseCSV(String csvContent, Map<String, String> categoryMapping) {
    final normalized = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('ï»¿', ''); // Rimuove BOM se presente
    
    final lines = normalized.split('\n');
    final List<MoneyTx> transactions = [];

    // Trova l'intestazione
    int headerIndex = 0;
    while (headerIndex < lines.length && !lines[headerIndex].toLowerCase().contains('data')) {
      headerIndex++;
    }

    if (headerIndex >= lines.length) return [];

    // Parsa le righe
    for (int i = headerIndex + 1; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isNotEmpty) {
        final tx = _parseCSVLineTolerant(raw, categoryMapping);
        if (tx != null) transactions.add(tx);
      }
    }
    return transactions;
  }

  static MoneyTx? _parseCSVLineTolerant(String line, Map<String, String> categoryMapping) {
    final s = line.replaceAll('"', '');
    final fields = _parseCSVFields(s);
    
    // Controllo minimo campi
    if (fields.length < 3) return null;
    
    // Riempie campi mancanti se necessario
    while (fields.length < 5) {
      fields.add('');
    }

    try {
      // 1. Data
      DateTime date;
      try {
        date = DateTime.parse(fields[0]);
      } catch (_) {
        final parts = fields[0].split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return null;
        }
      }

      // 2. Categoria
      final rawCategory = fields[1].trim();
      final category = categoryMapping[rawCategory] ?? _mapCommonCategory(rawCategory);

      // 3. Importo
      final amountStr = fields[2].replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
      final amount = double.tryParse(amountStr)?.abs() ?? 0.0;
      if (amount == 0) return null;

      // 4. Tipo (Entrata/Uscita)
      final typeField = fields.length > 4 ? fields[4] : '';
      final lowerType = typeField.toLowerCase();
      final isIncome = lowerType.contains('entrata') ||
                       lowerType.contains('income') ||
                       lowerType.contains('+');

      // 5. Nota
      final note = fields[3].trim().isEmpty ? null : fields[3].trim();

      return MoneyTx(
        isIncome: isIncome,
        category: category,
        amount: amount,
        date: date,
        note: note,
        payment: PaymentMethod.carta, // Default
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _parseCSVFields(String line) {
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

  static Set<String> getUnrecognizedCategoriesFromCSV(String csvContent, List<String> allKnownCats) {
    final unrecognized = <String>{};
    final normalized = csvContent.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    
    // Trova l'inizio dati approssimativo
    final startIndex = lines.isNotEmpty && lines[0].toLowerCase().contains('data') ? 1 : 0;

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final fields = _parseCSVFields(line);
      if (fields.length > 2) {
        final rawCategory = fields[1].trim();
        if (rawCategory.isNotEmpty) {
          final mappedCategory = _mapCommonCategory(rawCategory);
          if (!allKnownCats.contains(mappedCategory)) {
            unrecognized.add(rawCategory);
          }
        }
      }
    }
    return unrecognized;
  }

  // ==========================================
  // 📊 SEZIONE EXCEL
  // ==========================================

  static Future<List<MoneyTx>> parseExcel(Uint8List fileBytes, Map<String, String> categoryMapping) async {
    final excel = Excel.decodeBytes(fileBytes);
    final List<MoneyTx> transactions = [];

    for (var tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName];
      if (sheet == null) continue;

      final lowerName = tableName.toLowerCase();
      final isExpenseSheet = lowerName.contains('spese');
      final isIncomeSheet = lowerName.contains('entrate');
      final isTransferSheet = lowerName.contains('bonifici');

      if (isExpenseSheet || isIncomeSheet) {
        transactions.addAll(await _processStandardSheet(sheet, isIncomeSheet, categoryMapping));
      } else if (isTransferSheet) {
        transactions.addAll(await _processTransferSheet(sheet, categoryMapping));
      }
    }
    return transactions;
  }

  static Future<List<MoneyTx>> _processStandardSheet(
      Sheet sheet, bool isIncome, Map<String, String> categoryMapping) async {
    final List<MoneyTx> txs = [];
    if (sheet.rows.isEmpty) return txs;

    final headerRow = sheet.rows.first;
    int? dateCol, categoryCol, amountCol, noteCol;

    // Trova le colonne
    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value == null) continue;
      final header = cell!.value.toString().toLowerCase();
      if (header.contains('data')) dateCol = i;
      if (header.contains('categoria')) categoryCol = i;
      if (header.contains('importo')) amountCol = i;
      if (header.contains('commento') || header.contains('nota')) noteCol = i;
    }

    if (dateCol == null || categoryCol == null || amountCol == null) return txs;

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      try {
        final dateCell = dateCol < row.length ? row[dateCol]?.value : null;
        final categoryCell = categoryCol < row.length ? row[categoryCol]?.value : null;
        final amountCell = amountCol < row.length ? row[amountCol]?.value : null;
        final noteCell = noteCol != null && noteCol < row.length ? row[noteCol]?.value : null;

        if (dateCell == null || categoryCell == null || amountCell == null) continue;

        // Parsing Data
        DateTime date;
        final dateStr = dateCell.toString();
        if (dateStr.contains(' ')) {
          date = DateTime.parse(dateStr.split(' ')[0]);
        } else {
          date = DateTime.parse(dateStr);
        }

        // Parsing Categoria
        final rawCategory = categoryCell.toString().trim();
        final category = categoryMapping[rawCategory] ?? _mapCommonCategory(rawCategory);

        // Parsing Importo
        double amount = double.parse(amountCell.toString().replaceAll(',', '.'));

        txs.add(MoneyTx(
          isIncome: isIncome,
          category: category,
          amount: amount,
          date: date,
          note: noteCell?.toString(),
          payment: PaymentMethod.carta,
        ));
      } catch (e) {
        debugPrint('❌ Errore parsing riga Excel $i: $e');
      }
    }
    return txs;
  }

  static Future<List<MoneyTx>> _processTransferSheet(Sheet sheet, Map<String, String> categoryMapping) async {
    final List<MoneyTx> txs = [];
    if (sheet.rows.isEmpty) return txs;

    final headerRow = sheet.rows.first;
    int? dateCol, outCol, inCol, outAmountCol, inAmountCol, noteCol;

    for (int i = 0; i < headerRow.length; i++) {
      final cell = headerRow[i];
      if (cell?.value == null) continue;
      final header = cell!.value.toString().toLowerCase();
      if (header.contains('data')) dateCol = i;
      if (header.contains('uscita') && !header.contains('importo')) outCol = i;
      if (header.contains('entrata') && !header.contains('importo')) inCol = i;
      if (header.contains('importo') && header.contains('uscita')) outAmountCol = i;
      if (header.contains('importo') && header.contains('entrata')) inAmountCol = i;
      if (header.contains('commento') || header.contains('nota')) noteCol = i;
    }

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      try {
        final dateCell = dateCol != null && dateCol < row.length ? row[dateCol]?.value : null;
        if (dateCell == null) continue;
        
        DateTime date = DateTime.parse(dateCell.toString().split(' ')[0]);
        final noteCell = noteCol != null && noteCol < row.length ? row[noteCol]?.value : null;

        // Gestione Uscita
        final outCell = outCol != null && outCol < row.length ? row[outCol]?.value : null;
        final outAmountCell = outAmountCol != null && outAmountCol < row.length ? row[outAmountCol]?.value : null;

        if (outCell != null && outAmountCell != null) {
          final rawCategory = outCell.toString().trim();
          final category = categoryMapping[rawCategory] ?? _mapCommonCategory(rawCategory);
          txs.add(MoneyTx(
            isIncome: false,
            category: category,
            amount: double.parse(outAmountCell.toString().replaceAll(',', '.')),
            date: date,
            note: noteCell?.toString(),
            payment: PaymentMethod.carta,
          ));
        }

        // Gestione Entrata
        final inCell = inCol != null && inCol < row.length ? row[inCol]?.value : null;
        final inAmountCell = inAmountCol != null && inAmountCol < row.length ? row[inAmountCol]?.value : null;

        if (inCell != null && inAmountCell != null) {
          final rawCategory = inCell.toString().trim();
          final category = categoryMapping[rawCategory] ?? _mapCommonCategory(rawCategory);
          txs.add(MoneyTx(
            isIncome: true,
            category: category,
            amount: double.parse(inAmountCell.toString().replaceAll(',', '.')),
            date: date,
            note: noteCell?.toString(),
            payment: PaymentMethod.carta,
          ));
        }
      } catch (e) {
        debugPrint('❌ Errore parsing bonifico Excel riga $i: $e');
      }
    }
    return txs;
  }

  static Set<String> getUnrecognizedCategoriesFromExcel(Uint8List fileBytes, List<String> allKnownCats) {
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
          if (cell!.value.toString().toLowerCase().contains('categoria')) {
            categoryCol = i;
            break;
          }
        }
        if (categoryCol == null) continue;

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length <= categoryCol) continue;
          final categoryCell = row[categoryCol]?.value?.toString().trim();
          if (categoryCell != null && categoryCell.isNotEmpty) {
            final mapped = _mapCommonCategory(categoryCell);
            if (!allKnownCats.contains(mapped)) {
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

  // ==========================================
  // 🔄 SEZIONE BACKUP MM (JSON)
  // ==========================================

  static List<MoneyTx> parseMMBackup(String jsonContent, Map<String, String> categoryMapping) {
    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final List<MoneyTx> transactions = [];
      final txList = (data['transactions'] as List?) ?? [];

      for (final txData in txList) {
        final tx = _parseMMBackupTransaction(txData, categoryMapping);
        if (tx != null) transactions.add(tx);
      }
      return transactions;
    } catch (e) {
      debugPrint('❌ Errore importazione MMBackup: $e');
      return [];
    }
  }

  static MoneyTx? _parseMMBackupTransaction(dynamic txData, Map<String, String> categoryMapping) {
    try {
      if (txData is! Map) return null;
      
      final amount = double.parse(txData['amount']?.toString() ?? '0');
      if (amount == 0) return null;

      final rawCategory = txData['category']?.toString() ?? 'Altro';
      final category = categoryMapping[rawCategory] ?? _mapCommonCategory(rawCategory);

      final date = DateTime.fromMillisecondsSinceEpoch(txData['date'] ?? 0);
      final note = txData['note']?.toString();
      final isIncome = (txData['type']?.toString() ?? '').toLowerCase() == 'income';

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

  static Set<String> getUnrecognizedCategoriesFromMMBackup(String jsonContent, List<String> allKnownCats) {
    final unrecognized = <String>{};
    try {
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final transactions = (data['transactions'] as List?) ?? [];

      for (final txData in transactions) {
        final rawCategory = txData['category']?.toString().trim();
        if (rawCategory != null && rawCategory.isNotEmpty) {
          final mapped = _mapCommonCategory(rawCategory);
          if (!allKnownCats.contains(mapped)) {
            unrecognized.add(rawCategory);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Errore analisi categorie MMBackup: $e');
    }
    return unrecognized;
  }

  // ==========================================
  // 🛠 HELPERS COMUNI
  // ==========================================

  static String _mapCommonCategory(String rawCategory) {
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
}
