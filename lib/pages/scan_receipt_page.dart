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

  // Editable field controllers
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Altro';

  // Available categories
  final List<String> _categories = [
    'Spesa',
    'Trasporti', 
    'Svago',
    'Salute',
    'Shopping',
    'Bollette',
    'Altro'
  ];

  @override
  void initState() {
    super.initState();
    _receiptService = ReceiptService(storage: StorageService(), ai: AIService());
    _amountController = TextEditingController();
    _merchantController = TextEditingController();
  }

  @override
  void dispose() {
    _receiptService.ai.dispose();
    _amountController.dispose();
    _merchantController.dispose();
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
        
        // Update editable fields with parsed data
        _amountController.text = parsed.amount.toStringAsFixed(2);
        _merchantController.text = parsed.merchant;
        _selectedDate = parsed.date;
        _selectedCategory = parsed.categorySuggestion ?? 'Altro';
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
    
    // Use edited values instead of original parsed values
    final amount = double.tryParse(_amountController.text) ?? _parsed!.amount;
    final merchant = _merchantController.text.isEmpty ? _parsed!.merchant : _merchantController.text;
    
    // Create transaction using edited values
    final tx = MoneyTx(
      id: null,
      isIncome: false,
      category: _selectedCategory,
      amount: amount,
      date: _selectedDate,
      note: '🧾 $merchant • scontrino AI',
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
                  
                  // Parsed results with editable fields
                  if (_parsed != null) 
                    Expanded(child: _EditableReceiptCard(
                      parsed: _parsed!,
                      isDark: isDark,
                      amountController: _amountController,
                      merchantController: _merchantController,
                      selectedDate: _selectedDate,
                      selectedCategory: _selectedCategory,
                      categories: _categories,
                      onDateChanged: (date) => setState(() => _selectedDate = date),
                      onCategoryChanged: (category) => setState(() => _selectedCategory = category),
                    )),
                  
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

class _EditableReceiptCard extends StatelessWidget {
  final ParsedReceipt parsed;
  final bool isDark;
  final TextEditingController amountController;
  final TextEditingController merchantController;
  final DateTime selectedDate;
  final String selectedCategory;
  final List<String> categories;
  final Function(DateTime) onDateChanged;
  final Function(String) onCategoryChanged;
  
  const _EditableReceiptCard({
    required this.parsed,
    required this.isDark,
    required this.amountController,
    required this.merchantController,
    required this.selectedDate,
    required this.selectedCategory,
    required this.categories,
    required this.onDateChanged,
    required this.onCategoryChanged,
  });

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
              
              // Editable Amount
              _buildEditableAmountRow(context),
              const SizedBox(height: 12),
              
              // Editable Merchant
              _buildEditableMerchantRow(context),
              const SizedBox(height: 12),
              
              // Editable Date
              _buildEditableDateRow(context),
              const SizedBox(height: 12),
              
              // Editable Category
              _buildEditableCategoryRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableAmountRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.euro,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            'Importo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _showAmountEditDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${amountController.text} EUR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableMerchantRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.store,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            'Negozio',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _showMerchantEditDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      merchantController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDateRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            'Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _showDatePicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableCategoryRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.category,
          size: 18,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            'Categoria',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _showCategoryPicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedCategory,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAmountEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Importo'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Importo (EUR)',
            prefixIcon: Icon(Icons.euro),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _showMerchantEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Negozio'),
        content: TextField(
          controller: merchantController,
          decoration: const InputDecoration(
            labelText: 'Nome negozio',
            prefixIcon: Icon(Icons.store),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  void _showCategoryPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Categoria'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category),
                trailing: selectedCategory == category 
                  ? const Icon(Icons.check, color: Color(0xFF10B981))
                  : null,
                onTap: () {
                  onCategoryChanged(category);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}
