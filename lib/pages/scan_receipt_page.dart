import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers.dart';
import '../models.dart';
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
  bool _showRetryVision = false;

  @override
  void initState() {
    super.initState();
    _receiptService = ReceiptService(storage: StorageService(), ai: AIService());
  }

  @override
  void dispose() {
    _receiptService.ai.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x != null) {
      setState(() {
        _image = File(x.path);
        _parsed = null;
        _showRetryVision = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) {
      setState(() {
        _image = File(x.path);
        _parsed = null;
        _showRetryVision = false;
      });
    }
  }

  Future<void> _process({bool forceVision = false}) async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      if (forceVision) _showRetryVision = false;
    });
    try {
      final parsed = await _receiptService.processReceipt(_image!, currencyFallback: 'EUR');
      setState(() {
        _parsed = parsed;
        _showRetryVision = parsed.hasVisionError;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore estrazione: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAsTransaction() async {
    if (_parsed == null) return;
    
    final model = Provider.of<MoneyModel>(context, listen: false);
    
    // Create transaction using existing addTx method
    final tx = MoneyTx(
      id: null,
      isIncome: false,
      category: _parsed!.categorySuggestion ?? 'Altro',
      amount: _parsed!.amount,
      date: _parsed!.date,
      note: '🧾 ${_parsed!.merchant} • scontrino AI',
      payment: PaymentMethod.carta,
    );
    
    await model.addTx(tx);
    
    // Cleanup temp image file
    await _receiptService.cleanupAfterSave(_parsed!.imageUrl);
    
    if (mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transazione creata dalla scansione AI'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Scansiona scontrino'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      body: Column(
        children: [
          // Vision API Error Banner
          if (_showRetryVision && _parsed != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vision API non disponibile. Usando OCR locale.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _process(forceVision: true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Riprova Vision', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Camera/Gallery buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          onPressed: _pickFromCamera,
                          icon: Icons.photo_camera,
                          label: 'Fotocamera',
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          onPressed: _pickFromGallery,
                          icon: Icons.photo_library,
                          label: 'Galleria',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Image preview
                  if (_image != null)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // AI Extract button with glass effect
                  _buildGlassActionButton(
                    onPressed: (_image != null && !_loading) ? () => _process() : null,
                    icon: Icons.auto_awesome,
                    label: _loading ? 'Estrazione in corso...' : 'Estrai con AI',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    isLoading: _loading,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Parsed results
                  if (_parsed != null) 
                    Expanded(child: _ParsedCard(parsed: _parsed!, isDark: isDark)),
                  
                  if (_parsed == null) const Spacer(),
                  
                  // Save button with glass effect
                  _buildGlassActionButton(
                    onPressed: _parsed != null ? _saveAsTransaction : null,
                    icon: Icons.save,
                    label: 'Salva come transazione',
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool isOutlined = false,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: isOutlined ? color : Colors.white,
          side: isOutlined ? BorderSide(color: color, width: 2) : null,
          elevation: isOutlined ? 0 : 4,
          shadowColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isOutlined ? color : Colors.white,
              ),
            )
          : Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildGlassActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.8),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ).copyWith(
              overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
            ),
            icon: isLoading 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 22),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParsedCard extends StatelessWidget {
  final ParsedReceipt parsed;
  final bool isDark;
  
  const _ParsedCard({required this.parsed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (parsed.hasVisionError ? Colors.orange : const Color(0xFF10B981)).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      parsed.hasVisionError ? Icons.warning_rounded : Icons.auto_awesome,
                      color: parsed.hasVisionError ? Colors.orange : const Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dettagli estratti',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (parsed.hasVisionError)
                          Text(
                            'OCR Locale (Vision API non disponibile)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Importo', '${parsed.amount.toStringAsFixed(2)} ${parsed.currency}', Icons.euro, isDark),
              _buildDetailRow('Negozio', parsed.merchant, Icons.store, isDark),
              _buildDetailRow('Data', '${parsed.date.day}/${parsed.date.month}/${parsed.date.year}', Icons.calendar_today, isDark),
              _buildDetailRow('Categoria AI', parsed.categorySuggestion ?? 'Non riconosciuta', Icons.category, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
