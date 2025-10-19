import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'repository.dart';

class MoneyModel extends ChangeNotifier {
  final Repository _repo = Repository();
  List<MoneyTx> transactions = [];
  List<Goal> goals = [];
  List<Recurring> recurringTransactions = [];
  bool loading = true;
  String currency = '€';

  // ... (resto invariato sopra)

  // PATCH: Import CSV tollerante con contatore scarti
  Future<Map<String,int>> importFromCSV(String csvContent, Map<String, String> categoryMapping) async {
    // Normalizza separatore e fine riga
    final normalized = csvContent.replaceAll(';', ',').replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty) return {'imported': 0, 'skipped': 0};

    // Salta eventuali righe "titolo" extra prima dell'header vero e proprio
    int headerIndex = 0;
    while (headerIndex < lines.length && !lines[headerIndex].toLowerCase().contains('data')) {
      headerIndex++;
    }
    if (headerIndex >= lines.length) return {'imported': 0, 'skipped': lines.length};

    int imported = 0, skipped = 0;
    for (int i = headerIndex + 1; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) { skipped++; continue; }
      final line = raw;

      try {
        final tx = _parseCSVLineTolerant(line, categoryMapping);
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

  MoneyTx? _parseCSVLineTolerant(String line, Map<String,String> categoryMapping) {
    // Supporta virgolette e virgola; normalizza separatore
    final s = line.replaceAll(';', ',');
    final fields = _parseCSVFields(s);
    if (fields.length < 3) return null; // almeno Data, Categoria, Importo

    // Se mancano Nota/Tipo, riempi
    while (fields.length < 5) { fields.add(''); }

    try {
      // Data: ISO o DD/MM/YYYY
      DateTime date;
      try { date = DateTime.parse(fields[0]); }
      catch (_) {
        final parts = fields[0].split('/');
        if (parts.length == 3) { date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0])); }
        else { return null; }
      }

      // Categoria con mapping
      final rawCategory = fields[1].trim();
      final category = categoryMapping[rawCategory] ?? _mapCommonCategory(rawCategory);

      // Importo con virgola/punto ed eventuale simbolo euro
      final amountStr = fields[2].replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
      final amountParsed = double.tryParse(amountStr);
      if (amountParsed == null) return null;
      double amount = amountParsed.abs();

      // Tipo: se vuoto deduci dal segno
      final typeField = fields[4].toLowerCase();
      final isIncome = typeField.contains('entrata') || typeField.contains('income') || typeField.contains('+');

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

  // Parser CSV semplice (immutato)
  List<String> _parseCSVFields(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    String current = '';
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') { inQuotes = !inQuotes; }
      else if (ch == ',' && !inQuotes) { fields.add(current.trim()); current = ''; }
      else { current += ch; }
    }
    fields.add(current.trim());
    return fields;
  }

  // _mapCommonCategory rimane invariato sotto...
}
