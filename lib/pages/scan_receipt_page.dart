import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _showSnackBar('Fotocamera non disponibile su desktop. Usa "Scegli File".', Colors.orange);
      return;
    }

    final granted = await PermissionHelper.ensureCameraPermission(context);
    if (!granted) {
      _showSnackBar('Permesso fotocamera richiesto per continuare.', Colors.red);
      return;
    }

    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (x != null && mounted) {
        setState(() { _image = File(x.path); _parsed = null; _showRetryVision = false; });
      }
    } catch (e) {
      _showSnackBar('Errore fotocamera: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      XFile? x;
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.path != null) x = XFile(file.path!);
        }
      } else {
        final granted = await PermissionHelper.ensureGalleryPermission(context);
        if (!granted) {
          _showSnackBar('Permessi galleria necessari per continuare.', Colors.red);
          return;
        }
        x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      }

      if (x != null && mounted) {
        setState(() { _image = File(x.path); _parsed = null; _showRetryVision = false; });
        _showSnackBar('Immagine caricata con successo!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Errore selezione immagine: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ... resto file invariato ...
}
