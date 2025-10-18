import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../models.dart';

class IOPage extends StatefulWidget {
  const IOPage({super.key});

  @override
  State<IOPage> createState() => _IOPageState();
}

class _IOPageState extends State<IOPage> {
  String _csvContent = '';
  Set<String> _unrecognizedCategories = {};
  Map<String, String> _categoryMapping = {};
  bool _isAnalyzing = false;
  bool _showMappingStep = false;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoneyModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importa / Esporta'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ SEZIONE ESPORTA
          _buildCard(
            'Esporta Dati',
            Icons.file_upload,
            const Color(0xFF10B981),
            [
              ListTile(
                leading: const Icon(Icons.csv_file, color: Color(0xFF10B981)),
                title: const Text('Esporta CSV'),
                subtitle: const Text('Salva tutte le transazioni in formato CSV'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _exportToCSV(context, model);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF6366F1)),
                title: const Text('Copia negli Appunti'),
                subtitle: const Text('Copia i dati CSV negli appunti'),
                trailing: const Icon(Icons.content_copy, size: 16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _copyTransactionsToClipboard(context, model);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ SEZIONE IMPORTA
          _buildCard(
            'Importa Dati',
            Icons.file_download,
            const Color(0xFF6366F1),
            [
              if (!_showMappingStep) ...[
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Color(0xFF6366F1)),
                  title: const Text('Importa CSV'),
                  subtitle: const Text('Carica transazioni da altre app'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showCSVImportDialog(context, model);
                  },
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📄 Formato CSV Supportato:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Data,Categoria,Importo,Nota,Tipo',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      Text(
                        '2025-01-15,Spesa,25.50,Supermercato,Uscita',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Date: YYYY-MM-DD o DD/MM/YYYY\n'
                        '• Importi: usa punto per decimali\n'
                        '• Tipo: Entrata/Uscita (opzionale)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildCategoryMappingStep(model),
              ],
            ],
          ),
          
          if (model.transactions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildStatsCard(model),
          ],
        ],
      ),
    );
  }

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
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                Text(
                  'Statistiche Database',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            color: Color(0xFF8B5CF6),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showCSVImportDialog(BuildContext context, MoneyModel model) {
    final csvController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Importa CSV'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Incolla qui il contenuto del file CSV:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: csvController,
                decoration: InputDecoration(
                  hintText: 'Data,Categoria,Importo,Nota,Tipo\n2025-01-15,Spesa,25.50,Supermercato,Uscita',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le categorie non riconosciute ti verranno mostrate per la mappatura',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : () {
              _analyzeCSV(dialogContext, csvController.text, model);
            },
            icon: _isAnalyzing 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.analytics),
            label: Text(_isAnalyzing ? 'Analizzando...' : 'Analizza'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeCSV(BuildContext dialogContext, String csvContent, MoneyModel model) async {
    if (csvContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il contenuto CSV non può essere vuoto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _csvContent = csvContent;
    });

    try {
      _unrecognizedCategories = model.getUnrecognizedCategories(csvContent);
      
      Navigator.pop(dialogContext); // Chiudi dialog CSV
      
      if (_unrecognizedCategories.isNotEmpty) {
        // Mostra step di mappatura
        setState(() {
          _showMappingStep = true;
          _isAnalyzing = false;
        });
      } else {
        // Importa direttamente
        await model.importFromCSV(csvContent, {});
        _showImportSuccess(csvContent.split('\n').length - 1);
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nell\'analisi del CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCategoryMappingStep(MoneyModel model) {
    final allCategories = [...model.expenseCats, ...model.incomeCats];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trovate ${_unrecognizedCategories.length} categorie non riconosciute',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Associa le categorie del tuo CSV a quelle dell\'app:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ..._unrecognizedCategories.map((unknownCategory) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria CSV: "$unknownCategory"',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Associa a',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      value: _categoryMapping[unknownCategory],
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('-- Seleziona categoria --'),
                        ),
                        ...allCategories.map((cat) {
                          final style = model.getTransactionStyle(cat);
                          return DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(style.icon, color: style.color, size: 16),
                                const SizedBox(width: 8),
                                Text(cat),
                                if (model.incomeCats.contains(cat))
                                  const Text(' (Entrata)', style: TextStyle(color: Colors.green, fontSize: 10)),
                              ],
                            ),
                          );
                        }),
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
                  ],
                ),
              ),
            );
          }),
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
                    });
                  },
                  child: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _categoryMapping.length == _unrecognizedCategories.length
                      ? () => _performImport(model)
                      : null,
                  icon: const Icon(Icons.import_export),
                  label: const Text('Importa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(MoneyModel model) async {
    setState(() => _isAnalyzing = true);
    
    try {
      await model.importFromCSV(_csvContent, _categoryMapping);
      
      setState(() {
        _showMappingStep = false;
        _isAnalyzing = false;
        _categoryMapping.clear();
        _unrecognizedCategories.clear();
      });
      
      _showImportSuccess(_csvContent.split('\n').length - 1);
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'importazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportSuccess(int totalLines) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Importazione Completata'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_download_done, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'Importazione completata con successo!',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Transazioni elaborate: ~$totalLines',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, MoneyModel model) async {
    if (model.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna transazione da esportare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Data,Categoria,Importo,Nota,Tipo,Metodo Pagamento');
    
    for (final tx in model.transactions) {
      final type = tx.isIncome ? 'Entrata' : 'Uscita';
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      final note = tx.note?.replaceAll('"', '""') ?? ''; // Escape quotes
      final category = tx.category.replaceAll('"', '""');
      
      buffer.writeln('$dateStr,"$category",${tx.amount},"$note",$type,${tx.payment.name}');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${model.transactions.length} transazioni esportate negli appunti'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'CONDIVIDI',
          textColor: Colors.white,
          onPressed: () {
            // Qui potresti aggiungere logica di condivisione
            HapticFeedback.lightImpact();
          },
        ),
      ),
    );
  }

  Future<void> _copyTransactionsToClipboard(BuildContext context, MoneyModel model) async {
    final transactions = model.transactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessuna transazione da copiare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Data,Categoria,Importo,Nota,Tipo');
    for (final tx in transactions) {
      final type = tx.isIncome ? 'Entrata' : 'Uscita';
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      buffer.writeln('$dateStr,"${tx.category}",${tx.amount},"${tx.note ?? ''}","$type"');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Dati CSV copiati negli appunti'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
