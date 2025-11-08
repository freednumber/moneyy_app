import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;  // Preprocessing per scanner
import '../models.dart';
import '../providers.dart';
import '../utils/permission_helper.dart';

class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});
  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  bool _showResult = false;

  String _extractedMerchant = '';
  double _extractedAmount = 0.0;
  String _suggestedCategory = 'Spesa';
  DateTime _extractedDate = DateTime.now();
  List<Map<String, dynamic>> _extractedItems = [];
  double _confidence = 0.0;

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _selectedCategory = 'Spesa';
  DateTime _selectedDate = DateTime.now();

  static const String _ocrSpaceUrl = 'https://api.ocr.space/parse/image';
  static const String _ocrSpaceApiKey = 'K89996646088957';

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text('Scansiona Scontrino', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            children: [
              if (!_showResult) ...[
                _buildCameraSection(isDark),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 24),
                  _buildImagePreviewBox(isDark),
                  const SizedBox(height: 24),
                  _buildProcessButton(isDark),
                ],
              ] else ...[
                _buildResultSection(isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraSection(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.1)],
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scansiona con OCA Space',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'OCR rapido tramite OCA Space (OCR.space)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildActionButton('Fotocamera', Icons.photo_camera, const Color(0xFF6366F1), _pickFromCamera, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildActionButton('Galleria', Icons.photo_library, const Color(0xFF10B981), _pickFromGallery, isDark)),
          ],
        ),
      ],
    );
  }
  Widget _buildProcessButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: _isProcessing ? null : _processWithOCASpace,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: _isProcessing
                ? LinearGradient(colors: [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)])
                : LinearGradient(colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isProcessing
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                const SizedBox(width: 12),
                const Text(
                  'Elaborazione OCA Space...',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ] else ...[
                const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Elabora con OCA Space',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF059669).withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OCR.space completato!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verifica i dati estratti e salva la transazione',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildEditableField('Negozio', _merchantController, Icons.store, isDark),
        const SizedBox(height: 16),
        _buildEditableField('Importo', _amountController, Icons.euro, isDark, isAmount: true),
        const SizedBox(height: 16),
        _buildCategorySelector(isDark),
        const SizedBox(height: 16),
        _buildDateSelector(isDark),
        const SizedBox(height: 16),
        _buildEditableField('Note (opzionale)', _noteController, Icons.note, isDark),
        if (_extractedItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildLineItemsPreview(isDark),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildSecondaryButton('Riprova', Icons.refresh, _resetScanner, isDark)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildSaveButton(isDark)),
          ],
        ),
      ],
    );
  }
  Future<void> _processWithOCASpace() async {
    if (_selectedImage == null) return;

    // Preprocessing immagine scontrino
    _selectedImage = await preprocessReceiptImage(_selectedImage!);

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse(_ocrSpaceUrl),
        headers: {'apikey': _ocrSpaceApiKey},
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'ita',
          'isOverlayRequired': 'false',
        },
      ).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) throw Exception('Backend error: ${response.statusCode}');
      final data = jsonDecode(response.body);
      if (!(data['IsErroredOnProcessing'] == false && data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty)) {
        throw Exception("OCR.space non ha restituito risultati validi");
      }

      final ocrText = data['ParsedResults'][0]['ParsedText'] ?? '';
      final lines = ocrText.split('\n');
      String merchant = '';
      double amount = 0.0;
      String category = 'Altro';
      DateTime receiptDate = DateTime.now();

      // 1. Merchant (prima riga maiuscola significativa)
      for (var line in lines) {
        if (merchant.isEmpty && RegExp(r'[A-Z ]{6,}').hasMatch(line) && !line.contains('TOTALE')) {
          merchant = line.trim();
        }
      }

      // 2. Importo - cerca tutte le cifre e prendi il massimo
      final matches = RegExp(r'(\d+[,.]\d{2})').allMatches(ocrText);
      List<double> amounts = matches.map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0).toList();
      if (amounts.isNotEmpty) {
        amount = amounts.reduce((a, b) => a > b ? a : b);
      }

      // 3. Categoria - euristica testuale
      if (ocrText.contains('MENU') || ocrText.contains('RISTORANTE') || ocrText.contains('PIZZERIA') || ocrText.contains('SUPERMERCATO')) {
        category = 'Spesa';
      }

      // 4. Data
      for (var line in lines) {
        final dateMatch = RegExp(r'(\d{2}-\d{2}-\d{4})').firstMatch(line);
        if (dateMatch != null) {
          try {
            final parts = dateMatch.group(1)!.split('-');
            receiptDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            break;
          } catch (_) {
            receiptDate = DateTime.now();
          }
        }
      }

      _extractedMerchant = merchant.isNotEmpty ? merchant : 'Negozio rilevato';
      _extractedAmount = amount;
      _suggestedCategory = category;
      _selectedCategory = category;
      _selectedDate = receiptDate;
      _merchantController.text = _extractedMerchant;
      _amountController.text = _extractedAmount.toString();
      setState(() {
        _isProcessing = false;
        _showResult = true;
      });
      HapticFeedback.heavyImpact();
      _showSnackBar('Scontrino elaborato con OCA Space!', const Color(0xFF10B981));
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Errore OCR: ${e.toString()}', const Color(0xFFEF4444));
    }
  }

  Future<File> preprocessReceiptImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 150);
    image = img.threshold(image, threshold: 170);

    final temp = await File('${file.path}_scanner.jpg').writeAsBytes(img.encodeJpg(image, quality: 95));
    return temp;
  }

  void _resetScanner() {
    setState(() {
      _selectedImage = null;
      _showResult = false;
      _isProcessing = false;
      _extractedItems.clear();
      _confidence = 0.0;
      _merchantController.clear();
      _amountController.clear();
      _noteController.clear();
      _selectedCategory = 'Spesa';
      _selectedDate = DateTime.now();
    });
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _merchantController.text.isEmpty) {
      _showSnackBar('Compila tutti i campi obbligatori', const Color(0xFFEF4444));
      return;
    }
    final tx = MoneyTx(
      id: null,
      isIncome: false,
      category: _selectedCategory,
      amount: amount,
      date: _selectedDate,
      note: '${_merchantController.text}${_noteController.text.isNotEmpty ? ' - ${_noteController.text}' : ''}',
      payment: PaymentMethod.carta,
    );
    context.read<MoneyModel>().addTx(tx);
    HapticFeedback.heavyImpact();
    _showSnackBar('Transazione salvata!', const Color(0xFF10B981));
    _resetScanner();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
