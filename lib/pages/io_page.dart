import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
// Alias per evitare conflitti con Border/BorderStyle di Flutter
import 'package:excel/excel.dart' as xls;
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
  int _previewLimit = 100; // Limite visualizzazione nella lista
  int _maxImportItems = 10000; // Limite massimo import
  
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;
  late AnimationController _previewAnimationController;
  late Animation<double> _previewAnimation;

  @override
  void initState() {
    super.initState();
    _dragAnimationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _dragAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _dragAnimationController, curve: Curves.easeInOut));
    _previewAnimationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _previewAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _previewAnimationController, curve: Curves.easeOutCubic));
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
            IconButton(icon: const Icon(Icons.close), onPressed: _closePreview, tooltip: 'Chiudi anteprima'),
          if (_showPreview && _previewData.length > _previewLimit)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showPreviewSettings(),
              tooltip: 'Impostazioni preview',
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showPreview ? _buildPreviewWidget(model) : _buildMainContent(model),
      ),
    );
  }

  // ====== MAIN CONTENT ======
  Widget _buildMainContent(MoneyModel model) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildDragDropZone(model),
      const SizedBox(height: 16),
      _buildCard('Esporta Dati', Icons.file_upload, const Color(0xFF10B981), [
        ListTile(
          leading: const Icon(Icons.description, color: Color(0xFF10B981)),
          title: const Text('Esporta CSV'),
          subtitle: const Text('Salva tutte le transazioni in formato CSV'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _exportToCSV(context, model),
        ),
        ListTile(
          leading: const Icon(Icons.copy, color: Color(0xFF6366F1)),
          title: const Text('Copia negli Appunti'),
          subtitle: const Text('Copia i dati CSV negli appunti'),
          trailing: const Icon(Icons.content_copy, size: 16),
          onTap: () => _copyTransactionsToClipboard(context, model),
        ),
      ]),
      const SizedBox(height: 16),
      if (!_showMappingStep)
        _buildCard('Importa Dati', Icons.file_download, const Color(0xFF6366F1), [
          ListTile(
            leading: const Icon(Icons.folder_open, color: Color(0xFF6366F1)),
            title: const Text('Sfoglia File'),
            subtitle: const Text('Seleziona da Finder/Esplora File'),
            trailing: const Icon(Icons.upload_file, size: 20),
            onTap: _pickFile,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF8B5CF6)),
            title: const Text('Incolla CSV Manuale'),
            subtitle: const Text('Se non riesci a caricare il file'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showCSVImportDialog(context, model),
          ),
        ])
      else
        _buildCategoryMappingStep(model),
      if (model.transactions.isNotEmpty) ...[
        const SizedBox(height: 16),
        _buildStatsCard(model),
      ],
    ]);
  }

  // ====== PREVIEW WIDGET ======
  Widget _buildPreviewWidget(MoneyModel model) {
    final itemsToShow = _previewData.length.clamp(0, _previewLimit);
    final totalItems = _previewData.length;
    
    return FadeTransition(
      opacity: _previewAnimation,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(BorderSide(color: Color(0x4A6366F1))),
          ),
          child: Column(children: [
            Row(children: [
              Icon(_getFileIcon(), color: const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$totalItems transazioni trovate', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                if (totalItems > _previewLimit)
                  Text('Mostrate: $itemsToShow/$totalItems', style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500)),
              ])),
            ]),
            if (totalItems > 1000)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('File molto grande ($totalItems elementi). L\'importazione potrebbe richiedere tempo.', style: const TextStyle(fontSize: 12, color: Colors.amber))),
                ]),
              ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _analyzeFile(model), icon: const Icon(Icons.import_export), label: Text('Importa Tutto ($totalItems)'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: _closePreview, icon: const Icon(Icons.close), label: const Text('Annulla'))),
            ]),
          ]),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: itemsToShow,
            itemBuilder: (context, index) {
              final tx = _previewData[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFFEF4444).withOpacity(0.1), child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444)))),
                  title: Text(tx['categoria'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(tx['data'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('-€${tx['importo'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    if (tx['nota']?.isNotEmpty == true) Text(tx['nota']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ]),
                ),
              );
            },
          ),
        ),
        
        if (totalItems > _previewLimit)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text('Mostrate $itemsToShow di $totalItems transazioni', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _showMorePreview(), icon: const Icon(Icons.visibility), label: const Text('Mostra più'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => _showPreviewSettings(), icon: const Icon(Icons.settings), label: const Text('Impostazioni'))),
              ]),
            ]),
          ),
      ]),
    );
  }

  void _showMorePreview() {
    setState(() {
      _previewLimit = (_previewLimit + 100).clamp(100, _previewData.length);
    });
  }

  void _showPreviewSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impostazioni Preview'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('File: $_fileName'),
          Text('Totale elementi: ${_previewData.length}'),
          const SizedBox(height: 16),
          const Text('Elementi da mostrare:'),
          Slider(
            value: _previewLimit.toDouble(),
            min: 50,
            max: _previewData.length.toDouble().clamp(50, 1000),
            divisions: ((_previewData.length.clamp(50, 1000) - 50) / 50).round(),
            label: _previewLimit.toString(),
            onChanged: (value) => setState(() => _previewLimit = value.round()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _closePreview() {
    _previewAnimationController.reverse().then((_) {
      setState(() {
        _showPreview = false;
        _previewData.clear();
        _fileName = '';
        _fileBytes = null;
        _fileExtension = '';
        _previewLimit = 100;
      });
    });
  }

  // ====== DRAG & DROP ZONE ======
  Widget _buildDragDropZone(MoneyModel model) {
    return AnimatedBuilder(
      animation: _dragAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _dragAnimation.value,
          child: DropTarget(
            onDragDone: (detail) => _handleDragDrop(detail, model),
            onDragEntered: (_) => _setDragging(true),
            onDragExited: (_) => _setDragging(false),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isDragging ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.4), width: _isDragging ? 3 : 2),
                boxShadow: [if (_isDragging) BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 12, spreadRadius: 2)],
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _isDragging ? [const Color(0xFF6366F1).withOpacity(0.08), const Color(0xFF8B5CF6).withOpacity(0.08)] : [Colors.grey.withOpacity(0.04), Colors.grey.withOpacity(0.02)]),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Icon(_isDragging ? Icons.file_download : Icons.cloud_upload_outlined, size: _isDragging ? 60 : 48, color: _isDragging ? const Color(0xFF6366F1) : Colors.grey, key: ValueKey(_isDragging))),
                const SizedBox(height: 16),
                Text(_isDragging ? 'Rilascia il file qui!' : 'Trascina qui i tuoi file', style: TextStyle(fontSize: _isDragging ? 20 : 18, fontWeight: _isDragging ? FontWeight.bold : FontWeight.w500, color: _isDragging ? const Color(0xFF6366F1) : Colors.grey[700])),
                const SizedBox(height: 8),
                const Text('Supporta: CSV, Excel (.xlsx), MMBackup (.mmbackup)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                const Text('Fino a 10.000+ transazioni', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                if (!_isDragging) ...[
                  const SizedBox(height: 16),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Text('Oppure clicca "Sfoglia File" qui sotto', style: TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w500))),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }

  void _setDragging(bool isDragging) { setState(() => _isDragging = isDragging); if (isDragging) { _dragAnimationController.forward(); HapticFeedback.lightImpact(); } else { _dragAnimationController.reverse(); } }

  Future<void> _handleDragDrop(DropDoneDetails details, MoneyModel model) async {
    _setDragging(false);
    if (details.files.isEmpty) return;
    final file = details.files.first;
    final fileBytes = await file.readAsBytes();
    final fileName = file.name;
    final extension = fileName.split('.').last.toLowerCase();
    setState(() { _fileName = fileName; _fileBytes = fileBytes; _fileExtension = extension; });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File "$fileName" caricato con successo'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)));
    await _generatePreview();
  }

  Future<void> _generatePreview() async {
    if (_fileBytes == null) return; setState(() => _isAnalyzing = true);
    try {
      List<Map<String, String>> previewData = [];
      if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        previewData = _generateCSVPreview();
      } else if (_fileExtension == 'xlsx') {
        previewData = _generateExcelPreview();
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        previewData = _generateMMBackupPreview();
      }
      setState(() { _previewData = previewData; _showPreview = true; _isAnalyzing = false; });
      _previewAnimationController.forward();
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante l\'anteprima: $e'), backgroundColor: Colors.red));
    }
  }

  List<Map<String, String>> _generateCSVPreview() {
    final csvContent = String.fromCharCodes(_fileBytes!);
    final lines = csvContent.split('\n');
    final previewData = <Map<String, String>>[];
    final startIndex = lines[0].toLowerCase().contains('data') ? 1 : 0;
    // INCREMENTATO: da 100 a limite massimo import
    for (int i = startIndex; i < lines.length && previewData.length < _maxImportItems; i++) {
      final line = lines[i].trim(); if (line.isEmpty) continue;
      try {
        final f = _parseCSVFields(line);
        if (f.length >= 3) {
          previewData.add({'data': f[0], 'categoria': f.length > 1 ? f[1] : 'N/A', 'importo': f.length > 2 ? f[2] : '0.00', 'nota': f.length > 3 ? f[3] : '', 'tipo': f.length > 4 ? f[4] : 'Uscita'});
        }
      } catch (_) {}
    }
    return previewData;
  }

  List<Map<String, String>> _generateExcelPreview() {
    final previewData = <Map<String, String>>[];
    try {
      final excel = xls.Excel.decodeBytes(_fileBytes!);
      for (final tableName in excel.tables.keys) {
        final sheet = excel.tables[tableName]; if (sheet == null || sheet.rows.isEmpty) continue;
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
        // INCREMENTATO: da 100 a limite massimo import
        for (int r = 1; r < sheet.rows.length && previewData.length < _maxImportItems; r++) {
          final row = sheet.rows[r];
          try {
            final dateCell = row.length > dateCol ? row[dateCol!]?.value : null;
            final catCell = row.length > categoryCol ? row[categoryCol!]?.value : null;
            final amountCell = row.length > amountCol ? row[amountCol!]?.value : null;
            final noteCell = (noteCol != null && row.length > noteCol) ? row[noteCol!]?.value : null;
            if (dateCell == null || catCell == null || amountCell == null) continue;
            String dateStr = dateCell.toString(); if (dateStr.contains(' ')) dateStr = dateStr.split(' ').first;
            previewData.add({'data': dateStr, 'categoria': catCell.toString(), 'importo': amountCell.toString(), 'nota': (noteCell ?? '').toString(), 'tipo': 'Uscita'});
          } catch (_) {}
        }
      }
    } catch (_) {}
    return previewData;
  }

  List<Map<String, String>> _generateMMBackupPreview() {
    final previewData = <Map<String, String>>[];
    try {
      final jsonContent = String.fromCharCodes(_fileBytes!);
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      // INCREMENTATO: da take(100) a limite massimo
      for (final txData in transactions.take(_maxImportItems)) {
        try {
          final amount = txData['amount']?.toString() ?? '0';
          final category = txData['category']?.toString() ?? 'N/A';
          final date = DateTime.fromMillisecondsSinceEpoch(txData['date'] ?? 0);
          final note = txData['note']?.toString() ?? '';
          previewData.add({'data': DateFormat('yyyy-MM-dd').format(date), 'categoria': category, 'importo': amount, 'nota': note, 'tipo': 'Uscita'});
        } catch (_) {}
      }
    } catch (_) {}
    return previewData;
  }

  // ====== IMPORT/PICKER/CSV ======
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'csv', 'mmbackup', 'txt', 'json'], allowMultiple: false, withData: true, dialogTitle: 'Seleziona il file da importare');
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() { _fileName = file.name; _fileBytes = file.bytes; _fileExtension = file.extension?.toLowerCase() ?? ''; });
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📁 File "${file.name}" selezionato'), backgroundColor: Colors.green));
        await _generatePreview();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore selezione file: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _analyzeFile(MoneyModel model) async {
    if (_fileBytes == null || _fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun file selezionato'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      if (_fileExtension == 'xlsx') {
        _unrecognizedCategories = model.getUnrecognizedCategoriesFromExcel(_fileBytes!);
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        final jsonContent = String.fromCharCodes(_fileBytes!);
        _unrecognizedCategories = model.getUnrecognizedCategoriesFromMMBackup(jsonContent);
      } else if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        final csvContent = String.fromCharCodes(_fileBytes!);
        _unrecognizedCategories = model.getUnrecognizedCategories(csvContent);
      } else {
        throw Exception('Formato file non supportato: $_fileExtension');
      }
      if (_unrecognizedCategories.isNotEmpty) {
        _closePreview();
        setState(() { _showMappingStep = true; _isAnalyzing = false; });
      } else {
        await _performDirectImport(model);
        setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'analisi del file: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _performDirectImport(MoneyModel model) async {
    try {
      if (_fileExtension == 'xlsx') {
        await model.importFromExcel(_fileBytes!, {});
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        final jsonContent = String.fromCharCodes(_fileBytes!);
        await model.importFromMMBackup(jsonContent, {});
      } else if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        final csvContent = String.fromCharCodes(_fileBytes!);
        await model.importFromCSV(csvContent, {});
      }
      _showImportSuccess(); _closePreview(); _resetFileSelection();
    } catch (_) {}
  }

  void _showCSVImportDialog(BuildContext context, MoneyModel model) {
    final csvController = TextEditingController();
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Row(children: [Icon(Icons.edit, color: Color(0xFF8B5CF6)), SizedBox(width: 8), Text('Incolla CSV')]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Incolla qui il contenuto del file CSV:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        TextField(controller: csvController, decoration: InputDecoration(hintText: 'Data,Categoria,Importo,Nota,Tipo\n2025-01-15,Spesa,25.50,Supermercato,Uscita', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 8, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
        ElevatedButton.icon(onPressed: _isAnalyzing ? null : () => _analyzeCSV(dialogContext, csvController.text, model), icon: _isAnalyzing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.analytics), label: Text(_isAnalyzing ? 'Analizzando...' : 'Analizza')),
      ],
    ));
  }

  Future<void> _analyzeCSV(BuildContext dialogContext, String csvContent, MoneyModel model) async {
    if (csvContent.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Il contenuto CSV non può essere vuoto'), backgroundColor: Colors.red)); return; }
    setState(() { _isAnalyzing = true; _csvContent = csvContent; });
    try {
      _unrecognizedCategories = model.getUnrecognizedCategories(csvContent);
      Navigator.pop(dialogContext);
      if (_unrecognizedCategories.isNotEmpty) {
        setState(() { _showMappingStep = true; _isAnalyzing = false; });
      } else {
        await model.importFromCSV(csvContent, {}); _showImportSuccess(); setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nell\'analisi del CSV: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildCategoryMappingStep(MoneyModel model) {
    final allCategories = [...model.expenseCats, ...model.incomeCats];
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Expanded(child: Text('Trovate categorie non riconosciute', style: TextStyle(fontWeight: FontWeight.bold)))])),
      const SizedBox(height: 16),
      Row(children: [Icon(_getFileIcon(), color: const Color(0xFF6366F1), size: 20), const SizedBox(width: 8), Text('File: $_fileName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))]),
      const SizedBox(height: 8),
      const Text('Associa le categorie del file a quelle dell\'app:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      ..._unrecognizedCategories.map((unknownCategory) => Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Categoria trovata: "$unknownCategory"', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Associa a', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
          value: _categoryMapping[unknownCategory],
          items: [const DropdownMenuItem(value: null, child: Text('-- Seleziona categoria --')), ...allCategories.map((cat) { final style = model.getTransactionStyle(cat); return DropdownMenuItem(value: cat, child: Row(children: [Icon(style.icon, color: style.color, size: 16), const SizedBox(width: 8), Text(cat), if (model.incomeCats.contains(cat)) const Text(' (Entrata)', style: TextStyle(color: Colors.green, fontSize: 10))])); })],
          onChanged: (value) { setState(() { if (value != null) { _categoryMapping[unknownCategory] = value; } else { _categoryMapping.remove(unknownCategory); } }); },
        ),
      ])))) ,
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () { setState(() { _showMappingStep = false; _unrecognizedCategories.clear(); _categoryMapping.clear(); _resetFileSelection(); }); }, child: const Text('Annulla'))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(onPressed: _categoryMapping.length == _unrecognizedCategories.length ? () => _performMappedImport(model) : null, icon: const Icon(Icons.import_export), label: const Text('Importa'))),
      ]),
    ]));
  }

  Future<void> _performMappedImport(MoneyModel model) async {
    setState(() => _isAnalyzing = true);
    try {
      if (_fileExtension == 'xlsx') {
        await model.importFromExcel(_fileBytes!, _categoryMapping);
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        final jsonContent = String.fromCharCodes(_fileBytes!);
        await model.importFromMMBackup(jsonContent, _categoryMapping);
      } else if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        final csvContent = String.fromCharCodes(_fileBytes!);
        await model.importFromCSV(csvContent, _categoryMapping);
      }
      _showImportSuccess(); _closePreview();
      setState(() { _showMappingStep = false; _isAnalyzing = false; _categoryMapping.clear(); _unrecognizedCategories.clear(); });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante l\'importazione: $e'), backgroundColor: Colors.red));
    }
  }

  void _showImportSuccess() {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Importazione Completata')]), content: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.file_download_done, color: Colors.green, size: 48), const SizedBox(height: 16), Text('${_previewData.length} transazioni importate con successo!', style: const TextStyle(fontSize: 16), textAlign: TextAlign.center), const SizedBox(height: 8), const Text('Le transazioni sono state aggiunte al database', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)]), actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))]));
  }

  // ====== EXPORT/CLIPBOARD ======
  Future<void> _exportToCSV(BuildContext context, MoneyModel model) async {
    if (model.transactions.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessuna transazione da esportare'), backgroundColor: Colors.orange)); return; }
    final b = StringBuffer(); b.writeln('Data,Categoria,Importo,Nota,Tipo,Metodo Pagamento');
    for (final tx in model.transactions) { final type = tx.isIncome ? 'Entrata' : 'Uscita'; final dateStr = DateFormat('yyyy-MM-dd').format(tx.date); final note = tx.note?.replaceAll('"', '""') ?? ''; final category = tx.category.replaceAll('"', '""'); b.writeln('$dateStr,"$category",${tx.amount},"$note",$type,${tx.payment.name}'); }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${model.transactions.length} transazioni esportate negli appunti'), backgroundColor: Colors.green));
  }

  Future<void> _copyTransactionsToClipboard(BuildContext context, MoneyModel model) async {
    if (model.transactions.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessuna transazione da copiare'), backgroundColor: Colors.orange)); return; }
    final b = StringBuffer(); b.writeln('Data,Categoria,Importo,Nota,Tipo');
    for (final tx in model.transactions) { final type = tx.isIncome ? 'Entrata' : 'Uscita'; final dateStr = DateFormat('yyyy-MM-dd').format(tx.date); b.writeln('$dateStr,"${tx.category}",${tx.amount},"${tx.note ?? ''}","$type"'); }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Dati CSV copiati negli appunti'), backgroundColor: Colors.green));
  }

  // ====== UI HELPER WIDGETS ======
  Widget _buildCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatsCard(MoneyModel model) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF8B5CF6)),
                SizedBox(width: 8),
                Text('Statistiche Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Transazioni', model.transactions.length.toString(), Icons.receipt),
                _buildStatItem('Obiettivi', model.goals.length.toString(), Icons.flag),
                _buildStatItem('Ricorrenti', model.recurringTransactions.length.toString(), Icons.repeat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ====== UTILS ======
  void _resetFileSelection() { setState(() { _fileName = ''; _fileBytes = null; _fileExtension = ''; }); }
  IconData _getFileIcon() { switch (_fileExtension) { case 'xlsx': return Icons.table_chart; case 'csv': case 'txt': return Icons.description; case 'mmbackup': case 'json': return Icons.backup; default: return Icons.insert_drive_file; } }
  List<String> _parseCSVFields(String line) { final r = <String>[]; bool q = false; var c = ''; for (int i = 0; i < line.length; i++) { final ch = line[i]; if (ch == '"') { q = !q; } else if (ch == ',' && !q) { r.add(c.trim()); c = ''; } else { c += ch; } } r.add(c.trim()); return r; }
}