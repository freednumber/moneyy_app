import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'dart:ui';
import '../models.dart';
import '../providers.dart';

class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});
  @override
  State createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  File? _processedImage;
  bool _isProcessing = false;
  bool _showResult = false;
  String _currentFilter = 'auto';
  int _imageQualityScore = 0;
  String _extractedMerchant = '';
  double _extractedAmount = 0.0;
  String _suggestedCategory = 'Spesa';
  DateTime _extractedDate = DateTime.now();
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
                  _buildQualityIndicator(isDark),
                  const SizedBox(height: 16),
                  _buildImagePreviewWithFilters(isDark),
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

  Widget _buildQualityIndicator(bool isDark) {
    if (_imageQualityScore == 0) return SizedBox.shrink();
    
    Color color;
    String label;
    IconData icon;
    String suggestion = '';
    
    if (_imageQualityScore >= 75) {
      color = const Color(0xFF10B981);
      label = 'Ottima';
      icon = Icons.check_circle;
    } else if (_imageQualityScore >= 50) {
      color = const Color(0xFFF59E0B);
      label = 'Buona';
      icon = Icons.warning_amber;
      suggestion = 'Migliora l\'illuminazione per risultati ottimali';
    } else {
      color = const Color(0xFFEF4444);
      label = 'Scarsa';
      icon = Icons.error;
      suggestion = 'Scatta nuovamente con più luce o meno ombre';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                'Qualità: $label ($_imageQualityScore%)',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              suggestion,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraSection(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.1)],
                  ),
                ),
                child: const Icon(Icons.receipt_long, size: 40, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 12),
              Text(
                'Scansiona Scontrino',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '💡 Suggerimenti:\n• Centra lo scontrino\n• Evita ombre\n• Buona luce',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  ),
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

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewWithFilters(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey[300]!, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _processedImage ?? _selectedImage!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Filtro Applicato: ${_getFilterLabel(_currentFilter)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('Originale', 'none', isDark),
              const SizedBox(width: 12),
              _buildFilterButton('Auto OCR', 'auto', isDark),
              const SizedBox(width: 12),
              _buildFilterButton('Poca Luce', 'low_light', isDark),
              const SizedBox(width: 12),
              _buildFilterButton('B/N+', 'bw', isDark),
              const SizedBox(width: 12),
              _buildFilterButton('Ultra Contrasto', 'contrast', isDark),
            ],
          ),
        ),
      ],
    );
  }

  String _getFilterLabel(String key) {
    switch (key) {
      case 'none': return 'Originale';
      case 'auto': return 'Auto OCR';
      case 'low_light': return 'Poca Luce';
      case 'bw': return 'Bianco/Nero+';
      case 'contrast': return 'Ultra Contrasto';
      default: return 'Sconosciuto';
    }
  }

  Widget _buildFilterButton(String label, String filterKey, bool isDark) {
    final isSelected = _currentFilter == filterKey;
    return InkWell(
      onTap: () => _applyFilter(filterKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
              : LinearGradient(colors: [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: _isProcessing ? null : _processWithOCR,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: _isProcessing
                ? LinearGradient(colors: [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)])
                : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isProcessing ? [] : [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                const SizedBox(width: 12),
                const Text('Elaborazione OCR...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ] else ...[
                const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Elabora con OCR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OCR completato!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(
                      'Verifica i dati estratti e salva',
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

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isAmount = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isAmount ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final model = context.watch<MoneyModel>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!, width: 1.2),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.category, color: Color(0xFF6366F1)),
            ),
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            items: model.expenseCats.map((cat) {
              final style = model.getTransactionStyle(cat);
              return DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(style.icon, color: style.color, size: 20),
                    const SizedBox(width: 12),
                    Text(cat),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey[300]!, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                const SizedBox(width: 16),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDark ? Colors.white : Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return InkWell(
      onTap: _saveTransaction,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white),
            SizedBox(width: 8),
            Text('Salva Transazione', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (photo != null) {
      await _processPickedImage(File(photo.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (photo != null) {
      await _processPickedImage(File(photo.path));
    }
  }

  Future<void> _processPickedImage(File image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ritaglia Scontrino',
          toolbarColor: const Color(0xFF6366F1),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Ritaglia Scontrino',
        ),
      ],
    );
    if (croppedFile == null) return;
    setState(() {
      _selectedImage = File(croppedFile.path);
      _processedImage = null;
      _currentFilter = 'auto';
    });
    await _analyzeImageQuality();
    await _applyFilter('auto');
    HapticFeedback.mediumImpact();
  }

  Future<void> _analyzeImageQuality() async {
    if (_selectedImage == null) return;
    final bytes = await _selectedImage!.readAsBytes();
    final score = await compute(_calculateQualityScore, bytes);
    setState(() => _imageQualityScore = score);
  }

  static int _calculateQualityScore(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return 0;
    int score = 50;
    if (image.width > 800 && image.height > 600) {
      score += 20;
    } else if (image.width < 400 || image.height < 300) {
      score -= 20;
    }
    int totalBrightness = 0;
    int sampleSize = 100;
    for (int i = 0; i < sampleSize; i++) {
      int x = (image.width * i ~/ sampleSize);
      int y = (image.height ~/ 2);
      final pixel = image.getPixel(x, y);
      totalBrightness += ((pixel.r + pixel.g + pixel.b) ~/ 3).toInt();
    }
    int avgBrightness = totalBrightness ~/ sampleSize;
    if (avgBrightness >= 80 && avgBrightness <= 180) {
      score += 30;
    } else if (avgBrightness < 50) {
      score -= 30;
    } else if (avgBrightness > 200) {
      score -= 20;
    }
    return score.clamp(0, 100);
  }

  Future<void> _applyFilter(String filterKey) async {
    if (_selectedImage == null) return;
    setState(() => _currentFilter = filterKey);
    if (filterKey == 'none') {
      setState(() => _processedImage = null);
      return;
    }
    final bytes = await _selectedImage!.readAsBytes();
    final Uint8List filtered = await compute(_processImageBytes, {'bytes': bytes, 'filter': filterKey});
    final temp = File('${_selectedImage!.path}_filtered.jpg');
    await temp.writeAsBytes(filtered);
    setState(() => _processedImage = temp);
    HapticFeedback.lightImpact();
  }

  static Uint8List _processImageBytes(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final String filter = params['filter'];
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    switch (filter) {
      case 'auto':
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.6, brightness: 1.08);
        if (image.width > 1200) {
          image = img.copyResize(image, width: 1200);
        }
        break;
      case 'low_light':
        image = img.grayscale(image);
        image = img.adjustColor(image,
          brightness: 1.25,
          contrast: 1.7,
          saturation: 0
        );
        if (image.width > 1200) {
          image = img.copyResize(image, width: 1200);
        }
        break;
      case 'bw':
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.3);
        break;
      case 'contrast':
        image = img.adjustColor(image, contrast: 1.5, brightness: 1.05);
        image = img.grayscale(image);
        image = img.adjustColor(image, contrast: 1.4);
        break;
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  Future<void> _processWithOCR() async {
    final imageToProcess = _processedImage ?? _selectedImage;
    if (imageToProcess == null) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await imageToProcess.readAsBytes();
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
      if (!(data['IsErroredOnProcessing'] == false &&
          data['ParsedResults'] != null &&
          data['ParsedResults'].isNotEmpty)) {
        throw Exception('OCR non ha restituito risultati validi');
      }
      final ocrText = data['ParsedResults'][0]['ParsedText'] ?? '';
      final lines = ocrText.split('\n');
      String merchant = '';
      double amount = 0.0;
      String category = 'Spesa';
      DateTime receiptDate = DateTime.now();
      for (var line in lines) {
        if (merchant.isEmpty && RegExp(r'[A-Z ]{6,}').hasMatch(line) && !line.contains('TOTALE')) {
          merchant = line.trim();
          break;
        }
      }
      final matches = RegExp(r'(\d+[,.]\d{2})').allMatches(ocrText);
      List<double> amounts = matches.map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0).toList();
      if (amounts.isNotEmpty) {
        amount = amounts.reduce((a, b) => a > b ? a : b);
      }
      if (ocrText.toUpperCase().contains('SUPERMERCATO') || ocrText.toUpperCase().contains('ALIMENTARI')) {
        category = 'Spesa';
      } else if (ocrText.toUpperCase().contains('FARMACIA')) {
        category = 'Salute';
      }
      for (var line in lines) {
        final dateMatch = RegExp(r'(\d{2}[-/]\d{2}[-/]\d{4})').firstMatch(line);
        if (dateMatch != null) {
          try {
            final dateStr = dateMatch.group(1)!;
            final parts = dateStr.split(RegExp(r'[-/]'));
            receiptDate = DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]),
            );
            break;
          } catch (_) {}
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
      _showSnackBar('Scontrino elaborato con successo!', const Color(0xFF10B981));
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('Errore OCR: ${e.toString()}', const Color(0xFFEF4444));
    }
  }

  void _resetScanner() {
    setState(() {
      _selectedImage = null;
      _processedImage = null;
      _showResult = false;
      _isProcessing = false;
      _currentFilter = 'auto';
      _imageQualityScore = 0;
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
