import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
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
  bool _showPreview = false;
  List<Map<String, String>> _previewData = [];
  int _previewLimit = 100;
  int _maxImportItems = 10000;

  late AnimationController _previewAnimationController;
  late Animation<double> _previewAnimation;

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this
    );
    _previewAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0
    ).animate(CurvedAnimation(
      parent: _previewAnimationController,
      curve: Curves.easeOutCubic
    ));
  }

  @override
  void dispose() {
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
              tooltip: 'Chiudi anteprima'
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showPreview ? _buildPreviewWidget(model) : _buildMainContent(model),
      ),
    );
  }

  Widget _buildMainContent(MoneyModel model) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SEZIONE IMPORTA DATI
        if (!_showMappingStep) _buildImportSection(model),

        // Mapping step (quando necessario)
        if (_showMappingStep) ...[
          _buildCategoryMappingStep(model),
          const SizedBox(height: 16),
        ],

        if (!_showMappingStep) const SizedBox(height: 16),

        // SEZIONE ESPORTA DATI
        if (!_showMappingStep) _buildExportSection(model),

        // Statistiche
        if (model.transactions.isNotEmpty && !_showMappingStep) ...[
          const SizedBox(height: 16),
          _buildStatsCard(model),
        ],
      ],
    );
  }

  // 📥 SEZIONE IMPORTA DATI - Design accattivante
  Widget _buildImportSection(MoneyModel model) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.05),
              const Color(0xFF8B5CF6).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header sezione
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.file_download, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Importa Dati',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Carica le tue transazioni',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CARD SFOGLIA FILE - Design accattivante
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sfoglia File',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seleziona CSV, Excel o MMBackup',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Fino a 10.000+ transazioni',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OPPURE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
                ],
              ),
            ),

            // Incolla CSV Manuale
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF8B5CF6), size: 22),
              ),
              title: const Text(
                'Incolla CSV Manuale',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Se non riesci a caricare il file',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCSVImportDialog(context, model),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 📤 SEZIONE ESPORTA DATI
  Widget _buildExportSection(MoneyModel model) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF10B981).withOpacity(0.05),
              const Color(0xFF34D399).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header sezione
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.file_upload, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Esporta Dati',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Salva o condividi le tue transazioni',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Esporta CSV
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Color(0xFF10B981), size: 22),
              ),
              title: const Text(
                'Esporta CSV',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Salva tutte le transazioni in formato CSV',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _exportToCSV(context, model),
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),

            // Copia negli Appunti
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.content_copy, color: Color(0xFF6366F1), size: 22),
              ),
              title: const Text(
                'Copia negli Appunti',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Copia i dati CSV negli appunti',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _copyTransactionsToClipboard(context, model),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewWidget(MoneyModel model) {
    final itemsToShow = _previewData.length.clamp(0, _previewLimit);
    final totalItems = _previewData.length;

    return FadeTransition(
      opacity: _previewAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(BorderSide(color: Color(0x4A6366F1))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(_getFileIcon(), color: const Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('$totalItems transazioni trovate', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          if (totalItems > _previewLimit)
                            Text('Mostrate: $itemsToShow/$totalItems', style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500)),
                        ]
                      )
                    ),
                  ]
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _analyzeFile(model),
                        icon: const Icon(Icons.import_export),
                        label: Text('Importa Tutto ($totalItems)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white
                        ),
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _closePreview,
                        icon: const Icon(Icons.close),
                        label: const Text('Annulla')
                      )
                    ),
                  ]
                ),
              ]
            ),
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
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444)))
                    ),
                    title: Text(tx['categoria'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(tx['data'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('-€${tx['importo'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                        if (tx['nota']?.isNotEmpty == true)
                          Text(tx['nota']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ]
                    ),
                  ),
                );
              },
            ),
          ),

          if (totalItems > _previewLimit)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Mostrate $itemsToShow di $totalItems transazioni',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showMorePreview(),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Mostra più')
                  ),
                ]
              ),
            ),
        ]
      ),
    );
  }

  void _showMorePreview() {
    setState(() {
      _previewLimit = (_previewLimit + 100).clamp(100, _previewData.length);
    });
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'mmbackup', 'txt', 'json'],
        allowMultiple: false,
        withData: true,
        dialogTitle: 'Seleziona il file da importare'
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
          _fileBytes = file.bytes;
          _fileExtension = file.extension?.toLowerCase() ?? '';
          if ((_fileExtension == 'csv' || _fileExtension == 'txt') && file.bytes != null) {
            _csvContent = utf8.decode(file.bytes!, allowMalformed: true);
          }
        });

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📁 File "${file.name}" selezionato'),
            backgroundColor: Colors.green
          )
        );
        await _generatePreview();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore selezione file: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _generatePreview() async {
    if (_fileBytes == null) return;
    setState(() => _isAnalyzing = true);

    try {
      List<Map<String, String>> previewData = [];
      if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        previewData = _generateCSVPreview();
      } else if (_fileExtension == 'xlsx') {
        previewData = _generateExcelPreview();
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        previewData = _generateMMBackupPreview();
      }
      setState(() {
        _previewData = previewData;
        _showPreview = true;
        _isAnalyzing = false;
      });
      _previewAnimationController.forward();
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'anteprima: $e'), backgroundColor: Colors.red)
      );
    }
  }

  List<Map<String, String>> _generateCSVPreview() {
    final csvContent = _csvContent.isNotEmpty
        ? _csvContent
        : utf8.decode(_fileBytes!, allowMalformed: true);

    final lines = csvContent.split('\n');
    final previewData = <Map<String, String>>[];
    final startIndex = lines[0].toLowerCase().contains('data') ? 1 : 0;

    for (int i = startIndex; i < lines.length && previewData.length < _maxImportItems; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final normalized = line.replaceAll(';', ',');
        final f = _parseCSVFields(normalized);
        if (f.length >= 3) {
          previewData.add({
            'data': f[0],
            'categoria': f.length > 1 ? f[1] : 'N/A',
            'importo': f.length > 2 ? f[2] : '0.00',
            'nota': f.length > 3 ? f[3] : '',
            'tipo': f.length > 4 ? f[4] : 'Uscita'
          });
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
        final sheet = excel.tables[tableName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        final header = sheet.rows.first;
        int? dateCol, categoryCol, amountCol, noteCol;

        for (int i = 0; i < header.length; i++) {
          final h = header[i]?.value?.toString().toLowerCase() ?? '';
          if (h.contains('data')) dateCol = i;
          if (h.contains('categoria')) categoryCol = i;
          if (h.contains('importo')) amountCol = i;
          if (h.contains('commento') || h.contains('nota')) noteCol = i;
        }

        if (dateCol == null || categoryCol == null || amountCol == null) continue;

        for (int r = 1; r < sheet.rows.length && previewData.length < _maxImportItems; r++) {
          final row = sheet.rows[r];
          try {
            final dateCell = row.length > dateCol ? row[dateCol!]?.value : null;
            final catCell = row.length > categoryCol ? row[categoryCol!]?.value : null;
            final amountCell = row.length > amountCol ? row[amountCol!]?.value : null;
            final noteCell = (noteCol != null && row.length > noteCol) ? row[noteCol!]?.value : null;

            if (dateCell == null || catCell == null || amountCell == null) continue;

            String dateStr = dateCell.toString();
            if (dateStr.contains(' ')) dateStr = dateStr.split(' ').first;

            previewData.add({
              'data': dateStr,
              'categoria': catCell.toString(),
              'importo': amountCell.toString(),
              'nota': (noteCell ?? '').toString(),
              'tipo': 'Uscita'
            });
          } catch (_) {}
        }
      }
    } catch (_) {}
    return previewData;
  }

  List<Map<String, String>> _generateMMBackupPreview() {
    final previewData = <Map<String, String>>[];
    try {
      final jsonContent = utf8.decode(_fileBytes!, allowMalformed: true);
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final transactions = data['transactions'] as List<dynamic>? ?? [];

      for (final txData in transactions.take(_maxImportItems)) {
        try {
          final amount = txData['amount']?.toString() ?? '0';
          final category = txData['category']?.toString() ?? 'N/A';
          final date = DateTime.fromMillisecondsSinceEpoch(txData['date'] ?? 0);
          final note = txData['note']?.toString() ?? '';

          previewData.add({
            'data': DateFormat('yyyy-MM-dd').format(date),
            'categoria': category,
            'importo': amount,
            'nota': note,
            'tipo': 'Uscita'
          });
        } catch (_) {}
      }
    } catch (_) {}
    return previewData;
  }

  Future<void> _analyzeFile(MoneyModel model) async {
    if (_fileBytes == null || _fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun file selezionato'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      if (_fileExtension == 'xlsx') {
        _unrecognizedCategories = model.getUnrecognizedCategoriesFromExcel(_fileBytes!);
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        final jsonContent = utf8.decode(_fileBytes!, allowMalformed: true);
        _unrecognizedCategories = model.getUnrecognizedCategoriesFromMMBackup(jsonContent);
      } else if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        final csvContent = _csvContent.isNotEmpty
            ? _csvContent
            : utf8.decode(_fileBytes!, allowMalformed: true);
        _unrecognizedCategories = model.getUnrecognizedCategories(csvContent.replaceAll(';', ','));
      } else {
        throw Exception('Formato file non supportato: $_fileExtension');
      }

      if (_unrecognizedCategories.isNotEmpty) {
        _closePreview();
        setState(() {
          _showMappingStep = true;
          _isAnalyzing = false;
        });
      } else {
        await _performDirectImport(model);
        setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'analisi del file: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _performDirectImport(MoneyModel model) async {
    try {
      if (_fileExtension == 'xlsx') {
        await model.importFromExcel(_fileBytes!, {});
        _showResultSnack(imported: null, skipped: null);
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        final jsonContent = utf8.decode(_fileBytes!, allowMalformed: true);
        await model.importFromMMBackup(jsonContent, {});
        _showResultSnack(imported: null, skipped: null);
      } else if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        final csvContent = _csvContent.isNotEmpty
            ? _csvContent
            : utf8.decode(_fileBytes!, allowMalformed: true);
        final res = await model.importFromCSV(csvContent.replaceAll(';', ','), {});
        _showResultSnack(imported: res['imported'], skipped: res['skipped']);
      }
      _closePreview();
      _resetFileSelection();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore import: $e'), backgroundColor: Colors.red)
      );
    }
  }

  void _showCSVImportDialog(BuildContext context, MoneyModel model) {
    final csvController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF8B5CF6)),
            SizedBox(width: 8),
            Text('Incolla CSV')
          ]
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Incolla qui il contenuto del file CSV:',
                style: TextStyle(fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 12),
              TextField(
                controller: csvController,
                decoration: InputDecoration(
                  hintText: 'Data,Categoria,Importo,Nota,Tipo\n2025-01-15,Spesa,25.50,Supermercato,Uscita',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)
              ),
            ]
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla')
          ),
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : () => _analyzeCSV(dialogContext, csvController.text, model),
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.analytics),
            label: Text(_isAnalyzing ? 'Analizzando...' : 'Analizza')
          ),
        ],
      )
    );
  }

  Future<void> _analyzeCSV(BuildContext dialogContext, String csvContent, MoneyModel model) async {
    if (csvContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il contenuto CSV non può essere vuoto'),
          backgroundColor: Colors.red
        )
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _csvContent = csvContent;
    });
    try {
      _unrecognizedCategories = model.getUnrecognizedCategories(csvContent.replaceAll(';', ','));
      Navigator.pop(dialogContext);
      if (_unrecognizedCategories.isNotEmpty) {
        setState(() {
          _showMappingStep = true;
          _isAnalyzing = false;
        });
      } else {
        final res = await model.importFromCSV(csvContent.replaceAll(';', ','), {});
        _showResultSnack(imported: res['imported'], skipped: res['skipped']);
        setState(() => _isAnalyzing = false);
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'analisi del CSV: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Widget _buildCategoryMappingStep(MoneyModel model) {
    final allCategories = [...model.expenseCats, ...model.incomeCats];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trovate categorie non riconosciute',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    )
                  )
                ]
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(_getFileIcon(), color: const Color(0xFF6366F1), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'File: $_fileName',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            ),
            const SizedBox(height: 8),
            const Text(
              'Associa le categorie del file a quelle dell\'app:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _unrecognizedCategories.map((unknownCategory) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categoria trovata: "$unknownCategory"',
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Associa a',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            value: _categoryMapping[unknownCategory],
                            items: [
                              const DropdownMenuItem(value: null, child: Text('-- Seleziona categoria --')),
                              ...allCategories.map((cat) {
                                final style = model.getTransactionStyle(cat);
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Icon(style.icon, color: style.color, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          cat,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (model.incomeCats.contains(cat))
                                        const Text(
                                          ' (E)',
                                          style: TextStyle(color: Colors.green, fontSize: 10)
                                        )
                                    ]
                                  ),
                                );
                              })
                            ],
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _categoryMapping[unknownCategory] = value;
                                } else {
                                  _categoryMapping.remove(unknownCategory);
                                }
                              });
                            },
                          ),
                        ]
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showMappingStep = false;
                        _unrecognizedCategories.clear();
                        _categoryMapping.clear();
                        _resetFileSelection();
                      });
                    },
                    child: const Text('Annulla')
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _categoryMapping.length == _unrecognizedCategories.length
                        ? () => _performMappedImport(model)
                        : null,
                    icon: const Icon(Icons.import_export),
                    label: const Text('Importa')
                  )
                ),
              ]
            ),
          ]
        ),
      ),
    );
  }

  Future<void> _performMappedImport(MoneyModel model) async {
    setState(() => _isAnalyzing = true);
    try {
      if (_fileExtension == 'xlsx') {
        await model.importFromExcel(_fileBytes!, _categoryMapping);
        _showResultSnack(imported: null, skipped: null);
      } else if (_fileExtension == 'mmbackup' || _fileExtension == 'json') {
        final jsonContent = utf8.decode(_fileBytes!, allowMalformed: true);
        await model.importFromMMBackup(jsonContent, _categoryMapping);
        _showResultSnack(imported: null, skipped: null);
      } else if (_fileExtension == 'csv' || _fileExtension == 'txt') {
        final csvContent = _csvContent.isNotEmpty
            ? _csvContent
            : utf8.decode(_fileBytes!, allowMalformed: true);
        final res = await model.importFromCSV(csvContent.replaceAll(';', ','), _categoryMapping);
        _showResultSnack(imported: res['imported'], skipped: res['skipped']);
      }
      _closePreview();
      setState(() {
        _showMappingStep = false;
        _isAnalyzing = false;
        _categoryMapping.clear();
        _unrecognizedCategories.clear();
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'importazione: $e'), backgroundColor: Colors.red)
      );
    }
  }

  void _showResultSnack({int? imported, int? skipped}) {
    final imp = imported ?? _previewData.length;
    final ski = skipped ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Import completato: importate $imp, scartate $ski'),
        backgroundColor: imp > 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3)
      )
    );
  }

  Future<void> _exportToCSV(BuildContext context, MoneyModel model) async {
    if (model.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna transazione da esportare'), backgroundColor: Colors.orange)
      );
      return;
    }

    final b = StringBuffer();
    b.writeln('Data,Categoria,Importo,Nota,Tipo,Metodo Pagamento');
    for (final tx in model.transactions) {
      final type = tx.isIncome ? 'Entrata' : 'Uscita';
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      final note = tx.note?.replaceAll('"', '""') ?? '';
      final category = tx.category.replaceAll('"', '""');
      b.writeln('$dateStr,"$category",${tx.amount},"$note",$type,${tx.payment.name}');
    }

    await Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${model.transactions.length} transazioni esportate negli appunti'),
        backgroundColor: Colors.green
      )
    );
  }

  Future<void> _copyTransactionsToClipboard(BuildContext context, MoneyModel model) async {
    if (model.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna transazione da copiare'), backgroundColor: Colors.orange)
      );
      return;
    }

    final b = StringBuffer();
    b.writeln('Data,Categoria,Importo,Nota,Tipo');
    for (final tx in model.transactions) {
      final type = tx.isIncome ? 'Entrata' : 'Uscita';
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      b.writeln('$dateStr,"${tx.category}",${tx.amount},"${tx.note ?? ''}","$type"');
    }

    await Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Dati CSV copiati negli appunti'),
        backgroundColor: Colors.green
      )
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
                Text(
                  'Statistiche Database',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B5CF6)
          )
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _resetFileSelection() {
    setState(() {
      _fileName = '';
      _fileBytes = null;
      _fileExtension = '';
      _csvContent = '';
    });
  }

  IconData _getFileIcon() {
    switch (_fileExtension) {
      case 'xlsx':
        return Icons.table_chart;
      case 'csv':
      case 'txt':
        return Icons.description;
      case 'mmbackup':
      case 'json':
        return Icons.backup;
      default:
        return Icons.insert_drive_file;
    }
  }

  List<String> _parseCSVFields(String line) {
    final r = <String>[];
    bool q = false;
    var c = '';
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        q = !q;
      } else if (ch == ',' && !q) {
        r.add(c.trim());
        c = '';
      } else {
        c += ch;
      }
    }
    r.add(c.trim());
    return r;
  }
}
