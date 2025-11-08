// --- Estrarre dati dallo scontrino OCR ---
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
  // --- Logica OCR aggiornata con parsing ---
  Future<void> _processWithOCASpace() async {
    if (_selectedImage == null) return;
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
      if (!(data['IsErroredOnProcessing'] == false && data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty)) throw Exception("OCR.space non ha restituito risultati validi");
      final ocrText = data['ParsedResults'][0]['ParsedText'] ?? '';
      // --- Nuovo parsing ---
      final lines = ocrText.split('\n');
      String merchant = '';
      double amount = 0.0;
      DateTime receiptDate = DateTime.now();
      // 1. Cerca merchant sul top
      for (var line in lines) {
        if (merchant.isEmpty && RegExp(r'RISTORANTE|PIZZERIA|GENIO|FAMA', caseSensitive: false).hasMatch(line)) {
          merchant = line.trim();
        }
      }
      // 2. Cerca importo/total
      for (var line in lines) {
        final match = RegExp(r'TOTALE.*?(\d+[,.]\d{2})').firstMatch(line);
        if (match != null) {
          amount = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
          break;
        }
        final euro = RegExp(r'EURO.*?(\d+[,.]\d{2})').firstMatch(line);
        if (euro != null) {
          amount = double.tryParse(euro.group(1)!.replaceAll(',', '.')) ?? 0.0;
          break;
        }
      }
      // 3. Cerca data
      for (var line in lines) {
        final dateMatch = RegExp(r'(\d{2}-\d{2}-\d{4})').firstMatch(line);
        if (dateMatch != null) {
          try {
            final parts = dateMatch.group(1)!.split('-');
            receiptDate = DateTime(int.parse(parts[2]),int.parse(parts[1]),int.parse(parts[0]));
            break;
          } catch(_){ receiptDate = DateTime.now(); }
        }
      }
      _extractedMerchant = merchant.isNotEmpty ? merchant : 'Negozio rilevato';
      _extractedAmount = amount;
      _selectedCategory = 'Spesa';
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
      setState(() => _isProcessing = false);
      _showSnackBar('Errore OCR: ${e.toString()}', const Color(0xFFEF4444));
    }
  }
// --- Tutte le altre funzioni widget/UI, supporto (identiche a lavorazione precedente) ---
Widget _buildCameraSection(bool isDark) {...}
Widget _buildImagePreviewBox(bool isDark) {...}
Future<void> _pickFromCamera() async {...}
Future<void> _pickFromGallery() async {...}
Widget _buildEditableField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isAmount = false}) {...}
Widget _buildCategorySelector(bool isDark) {...}
Widget _buildDateSelector(bool isDark) {...}
Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap, bool isDark) {...}
Widget _buildSaveButton(bool isDark) {...}
void _saveTransaction() {...}
void _showSnackBar(String message, Color color) {...}
}
