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

  // OCR.Space API endpoint
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
            boxShadow: _isProcessing ? [] : [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
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
              ],
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
        // Success header con confidence
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
                    Row(
                      children: [
                        const Text(
                          'OCR.space completato!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verifica i dati estratti e salva la transazione',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Dati estratti
        _buildEditableField('Negozio', _merchantController, Icons.store, isDark),
        const SizedBox(height: 16),
        _buildEditableField('Importo', _amountController, Icons.euro, isDark, isAmount: true),
        const SizedBox(height: 16),
        _buildCategorySelector(isDark),
        const SizedBox(height: 16),
        _buildDateSelector(isDark),
        const SizedBox(height: 16),
        _buildEditableField('Note (opzionale)', _noteController, Icons.note, isDark),
        
        // Line items preview se disponibile
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

  Widget _buildLineItemsPreview(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Articoli Estratti ({_extractedItems.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_extractedItems.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '{item['quantity']}x {item['name']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '€{item['lineTotal'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          )).toList()),
          if (_extractedItems.length > 5) 
            Text(
              '...e altri {_extractedItems.length - 5} articoli',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  // Processo con OCA Space (OCR.space API)
  Future<void> _processWithOCASpace() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    try {
      // Converti immagine a base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse(_ocrSpaceUrl),
        headers: {
          'apikey': _ocrSpaceApiKey,
        },
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'ita',
          'isOverlayRequired': 'false',
        },
      ).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) throw Exception('Backend error: {response.statusCode}');
      final data = jsonDecode(response.body);
      if (!(data['IsErroredOnProcessing'] == false && data['ParsedResults'] != null && data['ParsedResults'].isNotEmpty)) {
        throw Exception("OCR.space non ha restituito risultati validi");
      }
      final ocrText = data['ParsedResults'][0]['ParsedText'] ?? '';
      // Puoi implementare qui qualche estrazione semplice di importo/data/negozio da ocrText
      _extractedMerchant = 'Negozio rilevato';
      _extractedAmount = 0.0;
      _suggestedCategory = 'Spesa';
      _extractedItems = [];
      _confidence = 0.0;
      _merchantController.text = _extractedMerchant;
      _amountController.text = _extractedAmount.toString();
      _selectedCategory = _suggestedCategory;
      _selectedDate = DateTime.now();
      setState(() {
        _isProcessing = false;
        _showResult = true;
      });
      HapticFeedback.heavyImpact();
      _showSnackBar('Scontrino elaborato con OCA Space!', const Color(0xFF10B981));
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Errore OCR: {e.toString()}', const Color(0xFFEF4444));
    }
  }

  // Reset scanner state
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

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
  
// --- RESTO DEL CODICE ECC (funzioni galleria, salvataggio, snackbar ecc) ---
  // ... Rimangono invariati ...
}
