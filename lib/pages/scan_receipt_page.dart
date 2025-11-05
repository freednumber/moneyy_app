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
  bool _useDeepSeekOCR = true; // Toggle per DeepSeek vs simulazione

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

  // Production Vercel endpoint - App Store ready
  static const String _backendUrl = 'https://moneyyocr2025-jqiwfk839-freed-numbers-projects.vercel.app';

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
        actions: [
          // Toggle DeepSeek OCR
          IconButton(
            icon: Icon(
              _useDeepSeekOCR ? Icons.auto_awesome : Icons.psychology_alt,
              color: _useDeepSeekOCR ? const Color(0xFF6366F1) : Colors.grey,
            ),
            onPressed: () => setState(() => _useDeepSeekOCR = !_useDeepSeekOCR),
            tooltip: _useDeepSeekOCR ? 'AI DeepSeek attivo' : 'Modalità demo',
          ),
        ],
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
                child: Icon(
                  _useDeepSeekOCR ? Icons.auto_awesome : Icons.receipt_long,
                  size: 48,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _useDeepSeekOCR ? 'Scansiona con DeepSeek AI' : 'Modalità Demo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _useDeepSeekOCR 
                  ? 'OCR economico e veloce con analisi intelligente scontrini'
                  : 'Elaborazione simulata per test dell\'interfaccia',
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
        onTap: _isProcessing ? null : (_useDeepSeekOCR ? _processWithDeepSeek : _processWithAI),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: _isProcessing
                ? LinearGradient(colors: [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)])
                : LinearGradient(colors: _useDeepSeekOCR ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)] : [const Color(0xFF10B981), const Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isProcessing ? [] : [
              BoxShadow(
                color: (_useDeepSeekOCR ? const Color(0xFF6366F1) : const Color(0xFF10B981)).withOpacity(0.4),
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
                Text(
                  _useDeepSeekOCR ? 'Elaborazione DeepSeek OCR...' : 'Elaborazione AI...',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ] else ...[
                Icon(
                  _useDeepSeekOCR ? Icons.auto_awesome : Icons.psychology_alt,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _useDeepSeekOCR ? 'Elabora con DeepSeek' : 'Elabora (Demo)',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
                child: Icon(
                  _useDeepSeekOCR ? Icons.auto_awesome : Icons.check,
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
                        Text(
                          _useDeepSeekOCR ? 'DeepSeek OCR completato!' : 'Elaborazione completata!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        if (_useDeepSeekOCR && _confidence > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(_confidence * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
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
                'Articoli Estratti (${_extractedItems.length})',
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
                    '${item['quantity']}x ${item['name']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '€${item['lineTotal'].toStringAsFixed(2)}',
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
              '...e altri ${_extractedItems.length - 5} articoli',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  // Processo con DeepSeek OCR via Vercel (PRODUCTION)
  Future<void> _processWithDeepSeek() async {
    if (_selectedImage == null) return;
    
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    
    try {
      // Converti immagine a base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Chiamata al backend Vercel + DeepSeek
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ocr/receipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageBase64': 'data:image/jpeg;base64,$base64Image'
        }),
      ).timeout(const Duration(seconds: 45)); // Timeout per serverless
      
      if (response.statusCode != 200) {
        throw Exception('Backend error: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      
      if (!data['success']) {
        throw Exception(data['error'] ?? 'OCR processing failed');
      }
      
      // Popola i campi con i risultati DeepSeek
      _extractedMerchant = data['merchant'] ?? 'Negozio Non Identificato';
      _extractedAmount = (data['total'] ?? 0.0).toDouble();
      _suggestedCategory = data['category'] ?? 'Spesa';
      _extractedItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _confidence = (data['confidence'] ?? 0.0).toDouble();
      
      try {
        _extractedDate = DateTime.parse(data['date']);
      } catch (_) {
        _extractedDate = DateTime.now();
      }
      
      _merchantController.text = _extractedMerchant;
      _amountController.text = _extractedAmount.toString();
      _selectedCategory = _suggestedCategory;
      _selectedDate = _extractedDate;
      
      setState(() {
        _isProcessing = false;
        _showResult = true;
      });
      
      HapticFeedback.heavyImpact();
      _showSnackBar('Scontrino elaborato con DeepSeek!', const Color(0xFF10B981));
      
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Errore OCR: ${e.toString()}', const Color(0xFFEF4444));
      
      // Fallback alla modalità demo se DeepSeek fallisce
      if (_useDeepSeekOCR) {
        _showSnackBar('Fallback alla modalità demo...', const Color(0xFFF59E0B));
        await _processWithAI();
      }
    }
  }

  // Processo simulato (fallback/demo)
  Future<void> _processWithAI() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _extractedMerchant = 'CONAD SUPERSTORE';
    _extractedAmount = 45.67;
    _suggestedCategory = 'Spesa';
    _extractedDate = DateTime.now();
    _extractedItems = [
      {'name': 'Pasta Barilla', 'quantity': 2, 'unitPrice': 1.20, 'lineTotal': 2.40},
      {'name': 'Latte Intero', 'quantity': 1, 'unitPrice': 1.50, 'lineTotal': 1.50},
    ];
    _confidence = 0.95;
    
    _merchantController.text = _extractedMerchant;
    _amountController.text = _extractedAmount.toString();
    _selectedCategory = _suggestedCategory;
    _selectedDate = _extractedDate;
    
    setState(() {
      _isProcessing = false;
      _showResult = true;
    });
    
    HapticFeedback.heavyImpact();
    _showSnackBar('Dati estratti (modalità demo)!', const Color(0xFF10B981));
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

  Widget _buildImagePreviewBox(bool isDark) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(child: Image.file(_selectedImage!, fit: BoxFit.cover)),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImage = null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isAmount = false}) {
    return Container(
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!)),
      child: TextField(
        controller: controller,
        keyboardType: isAmount ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]), prefixIcon: Icon(icon, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final categories = ['Spesa', 'Trasporti', 'Svago', 'Salute', 'Shopping', 'Bollette', 'Casa', 'Altro'];
    return Container(
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!)),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(labelText: 'Categoria', labelStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]), prefixIcon: Icon(Icons.category, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 16),
        items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
        onChanged: (value) => setState(() => _selectedCategory = value!),
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600]),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Data', style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[600])),
              const SizedBox(height: 4),
              Text(DateFormat('d MMMM yyyy', 'it_IT').format(_selectedDate), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ]),
            const Spacer(),
            Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.4) : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[400]!)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isDark ? Colors.white : Colors.grey[700], size: 18), const SizedBox(width: 8), Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return InkWell(
      onTap: _saveTransaction,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))]),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save, color: Colors.white, size: 20), SizedBox(width: 8), Text('Salva Transazione', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))]),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _showSnackBar('Fotocamera non disponibile su desktop. Usa "Galleria".', const Color(0xFFF59E0B));
      return;
    }
    final granted = await PermissionHelper.ensureCameraPermission(context);
    if (!granted) { _showSnackBar('Permesso fotocamera richiesto', const Color(0xFFEF4444)); return; }
    try {
      final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (image != null) { setState(() => _selectedImage = File(image.path)); HapticFeedback.lightImpact(); }
    } catch (e) { _showSnackBar('Errore fotocamera: $e', const Color(0xFFEF4444)); }
  }

  Future<void> _pickFromGallery() async {
    try {
      XFile? x;
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
        if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
          x = XFile(result.files.first.path!);
        }
      } else {
        final ok = await PermissionHelper.ensureGalleryPermission(context);
        if (!ok) return _showSnackBar('Permessi galleria necessari', const Color(0xFFEF4444));
        x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      }
      if (x != null && mounted) {
        setState(() => _selectedImage = File(x!.path));
        HapticFeedback.lightImpact();
        _showSnackBar('Immagine caricata!', const Color(0xFF10B981));
      }
    } catch (e) { _showSnackBar('Errore selezione: $e', const Color(0xFFEF4444)); }
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _merchantController.text.isEmpty) { _showSnackBar('Compila tutti i campi obbligatori', const Color(0xFFEF4444)); return; }
    final tx = MoneyTx(id: null, isIncome: false, category: _selectedCategory, amount: amount, date: _selectedDate, note: '${_merchantController.text}${_noteController.text.isNotEmpty ? ' - ${_noteController.text}' : ''}', payment: PaymentMethod.carta);
    context.read<MoneyModel>().addTx(tx); HapticFeedback.heavyImpact(); _showSnackBar('Transazione salvata!', const Color(0xFF10B981));
    _resetScanner();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}