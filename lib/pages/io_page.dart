import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../providers.dart';
import '../models.dart';

class IOPage extends StatefulWidget {
  const IOPage({super.key});

  @override
  State<IOPage> createState() => _IOPageState();
}

class _IOPageState extends State<IOPage> with TickerProviderStateMixin {
  String _csvContent = '';
  Uint8List? _fileBytes;
  String _fileName = '';
  String _fileExtension = '';
  Set<String> _unrecognizedCategories = {};
  Map<String, String> _categoryMapping = {};
  bool _isAnalyzing = false;
  bool _showMappingStep = false;
  bool _isDragging = false;
  bool _showPreview = false;
  List<Map<String, String>> _previewData = [];
  
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;
  late AnimationController _previewAnimationController;
  late Animation<double> _previewAnimation;

  @override
  void initState() {
    super.initState();
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dragAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _dragAnimationController, curve: Curves.easeInOut),
    );
    
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _previewAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _previewAnimationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    _previewAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoneyModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importa / Esporta'),
        elevation: 0,
        actions: [
          if (_showPreview)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closePreview,
              tooltip: 'Chiudi anteprima',
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showPreview
            ? _buildPreviewWidget(model)
            : _buildMainContent(model),
      ),
    );
  }

  Widget _buildMainContent(MoneyModel model) { /* unchanged */ return Container(); }

  // ... Drag & Drop zone unchanged ...

  // ✅ Anteprima CSV (unchanged)
  List<Map<String, String>> _generateCSVPreview() { /* unchanged */ return []; }

  // ✅ NUOVO: Anteprima Excel reale
  List<Map<String, String>> _generateExcelPreview() {
    final previewData = <Map<String, String>>[];
    try {
      final excel = Excel.decodeBytes(_fileBytes!);
      for (final tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName];
        if (sheet == null || sheet.rows.isEmpty) continue;
        // Individua colonne principali dalla riga header
        final header = sheet.rows.first;
        int? dateCol, categoryCol, amountCol, noteCol;
        for (int i = 0; i < header.length; i++) {
          final h = header[i]?.value?.toString().toLowerCase() ?? '';
          if (h.contains('data')) dateCol = i;
          if (h.contains('categoria')) categoryCol = i;
          if (h.contains('importo') && h.contains('predefinita')) amountCol = i;
          if (h.contains('commento')) noteCol = i;
        }
        if (dateCol == null || categoryCol == null || amountCol == null) continue;
        // Scorri righe dati con limite anteprima
        for (int r = 1; r < sheet.rows.length && previewData.length < 100; r++) {
          final row = sheet.rows[r];
          try {
            final dateCell = row.length > dateCol ? row[dateCol!]?.value : null;
            final catCell = row.length > categoryCol ? row[categoryCol!]?.value : null;
            final amountCell = row.length > amountCol ? row[amountCol!]?.value : null;
            final noteCell = (noteCol != null && row.length > noteCol) ? row[noteCol!]?.value : null;
            if (dateCell == null || catCell == null || amountCell == null) continue;
            // Normalizza data
            String dateStr = dateCell.toString();
            if (dateStr.contains(' ')) dateStr = dateStr.split(' ').first;
            // Aggiungi alla preview
            previewData.add({
              'data': dateStr,
              'categoria': catCell.toString(),
              'importo': amountCell.toString(),
              'nota': (noteCell ?? '').toString(),
              'tipo': 'Uscita',
            });
          } catch (_) {}
        }
      }
    } catch (_) {}
    return previewData;
  }

  // ✅ NUOVO: Anteprima MMBackup (unchanged)
  List<Map<String, String>> _generateMMBackupPreview() { /* unchanged */ return []; }

  // ... resto file invariato ...
