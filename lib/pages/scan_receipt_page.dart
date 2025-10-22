import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers.dart';
import '../parsed_receipt.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/receipt_service.dart';

class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  final _picker = ImagePicker();
  File? _image;
  bool _loading = false;
  ParsedReceipt? _parsed;
  late ReceiptService _receiptService;

  @override
  void initState() {
    super.initState();
    _receiptService = ReceiptService(storage: StorageService(), ai: AIService());
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _process() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _parsed = null;
    });
    try {
      final parsed = await _receiptService.processReceipt(_image!, currencyFallback: 'EUR');
      setState(() => _parsed = parsed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore estrazione: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAsTransaction() async {
    if (_parsed == null) return;
    final model = Provider.of<MoneyModel>(context, listen: false);
    await model.addTransaction(
      amount: _parsed!.amount,
      isIncome: false,
      category: _parsed!.categorySuggestion ?? 'Altro',
      date: _parsed!.date,
      note: '🧾 ${_parsed!.merchant} • scontrino',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transazione creata dalla scansione AI')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansiona scontrino'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Fotocamera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galleria'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_image != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_image != null && !_loading) ? _process : null,
              icon: const Icon(Icons.auto_awesome),
              label: _loading ? const Text('Estrazione in corso...') : const Text('Estrai con AI'),
            ),
            const SizedBox(height: 16),
            if (_parsed != null) _ParsedCard(parsed: _parsed!),
            const Spacer(),
            FilledButton.icon(
              onPressed: _parsed != null ? _saveAsTransaction : null,
              icon: const Icon(Icons.save),
              label: const Text('Salva come transazione'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedCard extends StatelessWidget {
  final ParsedReceipt parsed;
  const _ParsedCard({required this.parsed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dettagli estratti', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Importo: ${parsed.amount.toStringAsFixed(2)} ${parsed.currency}'),
          Text('Negozio: ${parsed.merchant}'),
          Text('Data: ${parsed.date}'),
          Text('Categoria AI: ${parsed.categorySuggestion ?? '-'}'),
          const SizedBox(height: 8),
          Text('Scontrino: ${parsed.imageUrl}', maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
