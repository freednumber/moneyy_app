import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers.dart';
import '../models.dart';
import '../parsed_receipt.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/receipt_service.dart';
import '../utils/permission_helper.dart';

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

  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Altro';

  final List<String> _categories = [
    'Spesa','Trasporti','Svago','Salute','Shopping','Bollette','Altro'
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
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _snack('Fotocamera non disponibile su desktop. Usa "Scegli File".', Colors.orange);
      return;
    }
    final granted = await PermissionHelper.ensureCameraPermission(context);
    if (!granted) return _snack('Permesso fotocamera richiesto per continuare.', Colors.red);
    try {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (x != null && mounted) {
        setState(() { _image = File(x!.path); _parsed = null; _showRetryVision = false; });
      }
    } catch (e) { _snack('Errore fotocamera: $e', Colors.red); }
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
        if (!ok) return _snack('Permessi galleria necessari per continuare.', Colors.red);
        x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      }
      if (x != null && mounted) {
        setState(() { _image = File(x!.path); _parsed = null; _showRetryVision = false; });
        _snack('Immagine caricata con successo!', Colors.green);
      }
    } catch (e) { _snack('Errore selezione immagine: $e', Colors.red); }
  }

  void _snack(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Scansiona scontrino'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      body: SafeArea(
        child: Padding(
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
              Expanded(
                child: _image == null
                  ? Center(child: Text('Nessuna immagine selezionata', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover, height: screenHeight * 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
