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

  // Categorie: aggiunto "Investimenti" anche tra le uscite
  final List<String> expenseCats = [
    'Spesa', 'Trasporti', 'Svago', 'Shopping', 'Bollette', 'Ricariche',
    'Casa', 'Salute', 'Sport', 'Regali', 'Viaggi', 'Investimenti', 'Altro'
  ];
  
  final List<String> incomeCats = [
    'Stipendio', 'Freelance', 'Investimenti', 'Regalo', 'Rimborso', 'Altro'
  ];
  
  final List<String> goalCategories = [
    'COMPUTER', 'SMARTPHONE', 'VIAGGIO', 'AUTO', 'CASA', 'INVESTIMENTI', 'ALTRO'
  ];

  // ... resto invariato ...

  CategoryStyle getTransactionStyle(String category) {
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
      'Investimenti': CategoryStyle(Icons.trending_up, const Color(0xFF8B5CF6)), // anche in uscite
      'Altro': CategoryStyle(Icons.more_horiz, const Color(0xFF6B7280)),
      'Stipendio': CategoryStyle(Icons.work, const Color(0xFF10B981)),
      'Freelance': CategoryStyle(Icons.laptop_mac, const Color(0xFF6366F1)),
      'Regalo': CategoryStyle(Icons.card_giftcard, const Color(0xFFF59E0B)),
      'Rimborso': CategoryStyle(Icons.undo, const Color(0xFF22C55E)),
      'COMPUTER': CategoryStyle(Icons.computer, const Color(0xFF3B82F6)),
      'SMARTPHONE': CategoryStyle(Icons.smartphone, const Color(0xFF8B5CF6)),
      'VIAGGIO': CategoryStyle(Icons.flight, const Color(0xFF10B981)),
      'AUTO': CategoryStyle(Icons.directions_car, const Color(0xFFEF4444)),
      'CASA': CategoryStyle(Icons.home, const Color(0xFFF59E0B)),
      'INVESTIMENTI': CategoryStyle(Icons.trending_up, const Color(0xFF14B8A6)),
      'ALTRO': CategoryStyle(Icons.flag, const Color(0xFF6B7280)),
      // Mappature comuni per import
      'Alimentari': CategoryStyle(Icons.shopping_cart, const Color(0xFF10B981)),
      'Auto': CategoryStyle(Icons.directions_car, const Color(0xFF3B82F6)),
      'Ristoranti': CategoryStyle(Icons.restaurant, const Color(0xFFF59E0B)),
      'Attività fisica': CategoryStyle(Icons.fitness_center, const Color(0xFF84CC16)),
      'PAC': CategoryStyle(Icons.trending_up, const Color(0xFF8B5CF6)),
      'Ricarica': CategoryStyle(Icons.smartphone, const Color(0xFF6366F1)),
      'Caffè': CategoryStyle(Icons.local_cafe, const Color(0xFFF59E0B)),
      'Abbigliamento': CategoryStyle(Icons.shopping_bag, const Color(0xFFEC4899)),
    };
    return styles[category] ?? CategoryStyle(Icons.help_outline, const Color(0xFF6B7280));
  }

  String _mapCommonCategory(String rawCategory) {
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
      // ENTRATE comuni
      'Rimborso': 'Rimborso',
      'Regalo': 'Regalo',
      'Stipendio': 'Stipendio',
      'Investimenti': 'Investimenti', // per coerenza
    };
    return mappings[rawCategory] ?? rawCategory;
  }
}
