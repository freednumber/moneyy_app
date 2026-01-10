import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/category_style.dart'; // Assicurati di aver creato questo file come detto prima

class CategoryProvider with ChangeNotifier {
  
  // ==========================================
  // 📋 LISTE CATEGORIE STANDARD
  // ==========================================

  List<String> expenseCats = [
    'Spesa', 'Trasporti', 'Svago', 'Shopping', 'Bollette',
    'Ricariche', 'Casa', 'Salute', 'Sport', 'Regali',
    'Viaggi', 'Investimenti', 'Altro'
  ];

  List<String> incomeCats = [
    'Stipendio', 'Freelance', 'Investimenti',
    'Regalo', 'Rimborso', 'Altro'
  ];

  final List<String> goalCategories = [
    'COMPUTER', 'SMARTPHONE', 'VIAGGIO', 'AUTO',
    'CASA', 'INVESTIMENTI', 'ALTRO'
  ];
  
  Future<void> resetCategoriesToDefault() async {
  // Svuota le liste personalizzate
  customExpenseCats.clear();
  customIncomeCats.clear();
  customCategoryIcons.clear();
  customCategoryColors.clear();
  
  // Pulisce SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('customExpenseCats');
  await prefs.remove('customIncomeCats');
  await prefs.remove('customCategoryIcons');
  await prefs.remove('customCategoryColors');
  
  notifyListeners();
}

  // ==========================================
  // 🎨 STATO PERSONALIZZATO (Custom)
  // ==========================================

  List<String> customExpenseCats = [];
  List<String> customIncomeCats = [];
  
  Map<String, IconData> customCategoryIcons = {};
  Map<String, Color> customCategoryColors = {};
  
  List<String> _expenseCatsOrder = [];
  List<String> _incomeCatsOrder = [];

  // Costruttore: Carica i dati salvati all'avvio
  CategoryProvider() {
    _loadCustomCategories();
  }

  // ==========================================
  // 📤 GETTERS (Liste Combinate e Ordinate)
  // ==========================================

  List<String> get allExpenseCats {
    final all = [...expenseCats, ...customExpenseCats];
    if (_expenseCatsOrder.isEmpty) return all;
    
    final ordered = <String>[];
    // Prima quelle nell'ordine salvato
    for (final cat in _expenseCatsOrder) {
      if (all.contains(cat)) ordered.add(cat);
    }
    // Poi le rimanenti (nuove o non ordinate)
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

  // ==========================================
  // 🖌️ GESTIONE STILE (Icone e Colori)
  // ==========================================

  CategoryStyle getTransactionStyle(String category) {
    // 1. Cerca nei custom (priorità alta)
    if (customCategoryIcons.containsKey(category)) {
      final color = customCategoryColors[category] ?? const Color(0xFF6366F1);
      return CategoryStyle(customCategoryIcons[category]!, color);
    }

    // 2. Mappa di default (Hardcoded)
    final Map<String, CategoryStyle> defaultStyles = {
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

    return defaultStyles[category] ?? CategoryStyle(Icons.help_outline, const Color(0xFF6B7280));
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

  // ==========================================
  // ⚙️ AZIONI CRUD (Modifica Liste)
  // ==========================================

  Future<void> addCustomCategory(String name, IconData icon, bool isIncome, [Color? color]) async {
    final list = isIncome ? customIncomeCats : customExpenseCats;
    final baseList = isIncome ? incomeCats : expenseCats;

    if (!baseList.contains(name) && !list.contains(name)) {
      list.add(name);
      customCategoryIcons[name] = icon;
      if (color != null) customCategoryColors[name] = color;
      
      await _saveCustomCategories();
      notifyListeners();
    }
  }

  Future<void> renameCategory({
    required String oldName,
    required String newName,
    required bool isIncome,
  }) async {
    if (newName.trim().isEmpty || oldName == newName) return;
    final trimmedNew = newName.trim();

    // 1. Aggiorna le liste
    if (isIncome) {
      _replaceInList(incomeCats, oldName, trimmedNew);
      _replaceInList(customIncomeCats, oldName, trimmedNew);
      _replaceInList(_incomeCatsOrder, oldName, trimmedNew);
    } else {
      _replaceInList(expenseCats, oldName, trimmedNew);
      _replaceInList(customExpenseCats, oldName, trimmedNew);
      _replaceInList(_expenseCatsOrder, oldName, trimmedNew);
    }

    // 2. Aggiorna stile (Icone e Colori)
    if (customCategoryIcons.containsKey(oldName)) {
      customCategoryIcons[trimmedNew] = customCategoryIcons[oldName]!;
      customCategoryIcons.remove(oldName);
    }
    if (customCategoryColors.containsKey(oldName)) {
      customCategoryColors[trimmedNew] = customCategoryColors[oldName]!;
      customCategoryColors.remove(oldName);
    }

    await _saveCustomCategories();
    notifyListeners();
  }

  void _replaceInList(List<String> list, String oldVal, String newVal) {
    final index = list.indexOf(oldVal);
    if (index != -1) list[index] = newVal;
  }

  Future<void> deleteCustomCategory(String name, bool isIncome) async {
    if (name == 'Altro') return;

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
    if (icon != null) customCategoryIcons[categoryName] = icon;
    if (color != null) customCategoryColors[categoryName] = color;
    await _saveCustomCategories();
    notifyListeners();
  }

  // ==========================================
  // 💾 PERSISTENZA (SharedPreferences)
  // ==========================================

  Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salva liste
    await prefs.setString('expenseCats', jsonEncode(expenseCats));
    await prefs.setString('incomeCats', jsonEncode(incomeCats));
    await prefs.setString('customExpenseCats', jsonEncode(customExpenseCats));
    await prefs.setString('customIncomeCats', jsonEncode(customIncomeCats));

    // Salva mappe icone/colori
    final iconsMap = customCategoryIcons.map((k, v) => MapEntry(k, v.codePoint));
    await prefs.setString('customCategoryIcons', jsonEncode(iconsMap));

    final colorsMap = customCategoryColors.map((k, v) => MapEntry(k, v.value));
    await prefs.setString('customCategoryColors', jsonEncode(colorsMap));
    
    // Salva ordine
    await prefs.setString('expenseCatsOrder', jsonEncode(_expenseCatsOrder));
    await prefs.setString('incomeCatsOrder', jsonEncode(_incomeCatsOrder));
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Helper per caricare liste
    void loadList(String key, Function(List<String>) onSuccess) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) onSuccess(List<String>.from(jsonDecode(jsonStr)));
    }

    loadList('expenseCats', (l) => expenseCats = l);
    loadList('incomeCats', (l) => incomeCats = l);
    loadList('customExpenseCats', (l) => customExpenseCats = l);
    loadList('customIncomeCats', (l) => customIncomeCats = l);
    loadList('expenseCatsOrder', (l) => _expenseCatsOrder = l);
    loadList('incomeCatsOrder', (l) => _incomeCatsOrder = l);

    // Carica Icone
    final iconsJson = prefs.getString('customCategoryIcons');
    if (iconsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(iconsJson);
      customCategoryIcons = decoded.map((k, v) =>
        MapEntry(k, IconData(v as int, fontFamily: 'MaterialIcons'))
      );
    }

    // Carica Colori
    final colorsJson = prefs.getString('customCategoryColors');
    if (colorsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(colorsJson);
      customCategoryColors = decoded.map((k, v) =>
        MapEntry(k, Color(v as int))
      );
    }

    notifyListeners();
  }
}
